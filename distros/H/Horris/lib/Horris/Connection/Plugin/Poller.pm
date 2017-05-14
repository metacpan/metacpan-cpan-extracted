package Horris::Connection::Plugin::Poller;
# ABSTRACT: Poller Plugin on Horris

use Moose;
use DBI;
use Data::Dumper;
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

use constant {
    ROWID  => 0,
    MSG_ID => 1,
    TIME   => 2,
    SEND   => 3,
    MSG    => 4,
};

has channel => (
    is => 'ro',
    isa => 'HashRef',
);

has dbfile => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has '+is_enable' => (
	default => 0
);

my $w;
my $dbh;
my $sth_select;
my $sth_update;
my $interval = 3;

sub on_connect {

    warn __PACKAGE__ . " on_connect\n";

    my ($self) = @_;

    # create table messages (msg_id text, time int, send int, msg text);

    my $current_time = scalar time;

    my $dbfile = $self->dbfile;
    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
    $sth_select = $dbh->prepare("SELECT rowid, msg_id, time, send, msg FROM messages WHERE send=0 and time > $current_time");
    $sth_update = $dbh->prepare("UPDATE messages SET send=1 WHERE rowid=?");

    # Polling $self->dbfile every $interval secs.
    $w = AnyEvent->timer(
        after       => 10,
        interval    => $interval,
        cb          => sub {

            my %anti_excess;

            # select messages to say
            $sth_select->execute;
            foreach my $row (@{ $sth_select->fetchall_arrayref }) {

                warn sprintf '[%s] Poller : %s', $self->is_enable ? 'on' : 'off',  join(", ", @$row);

                if($self->is_enable) {
                    foreach my $channel (keys %{ $self->channel }) {
                        for my $feed (@{ $self->channel->{$channel}->{feed} }) {

                            if($row->[MSG_ID] eq $feed) {

                                # drop '\' from channel name
                                my $cname = substr $channel, 1;

                                $self->connection->irc_privmsg({
                                    channel => $cname,
                                    message => $row->[MSG],
                                });

                                if($anti_excess{ scalar time }++ > 3) {
                                    print Dumper(\%anti_excess);
                                    sleep 5;
                                }
                            }

                        }
                    }
                }

                $sth_update->execute($row->[ROWID]);
            }
        },
    );

    $self->pass;
}

sub on_disconnect {
    undef $w;
    undef $sth_select;
    undef $sth_update;
    undef $dbh;
}

sub irc_privmsg {
	my ($self, $message) = @_;
	my $msg = $message->message;
	my $botname = $self->connection->nickname;
	my ($cmd) = $msg =~ m/^$botname\S*\s+(\w+)/;
	
	if (defined $cmd and lc $cmd eq 'feed') {
		$self->_switch;
		$self->connection->irc_notice({
			channel => $message->channel, 
			message => $self->is_enable ? '[feed] on' : '[feed] off'
		});
	}

	return $self->pass;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::Poller - Poller Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

