package Horris::Connection::Plugin::Hit;
# ABSTRACT: Dis(디스) Plugin on Horris


use Moose;
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has texts => (
	is => 'ro', 
	isa => 'ArrayRef', 
);

sub irc_privmsg {
	my ($self, $message) = @_;
	my $msg = $message->message;
	my $botname = $self->connection->nickname;

    my ($output, $nick, $typed);
    if (($nick, $typed) = $msg =~ m/^(\w+)\S*\s+껒$/i) {
        $output = $message->nickname . ': ';
        $output .= sprintf("%s - %s",  'ㅁㅁ?', 'http://tinyurl.com/5t3ew8t');
    } elsif (($nick, $typed) = $msg =~ m/^$botname\S*\s+[(:?dis|hit)]+\s+(\w+)\s*(.*)$/i) {
        $output = $nick . ': ';
        $output .= $typed eq '' ? $self->texts->[int(rand(scalar @{ $self->texts }))] : $typed;
    } else {
        return $self->pass;
    }

    $self->connection->irc_privmsg({
        channel => $message->channel, 
        message => $output
    });

    return $self->pass;
}

sub on_privatemsg {
	my ($self, $nick, $message) = @_;
	my $msg = $message->message;
	if (my ($nick, $typed) = $msg =~ m/^[(:?dis|hit)]+\s+(\w+)\s*(.*)$/i) {
		my $output = $nick . ': ';
		$output .= $typed eq '' ? $self->texts->[int(rand(scalar @{ $self->texts }))] : $typed;
		my %channel_list = %{ $self->connection->irc->channel_list };
		for my $channel (keys %channel_list) {
			if (grep { m/$nick/ } keys %{ $channel_list{$channel} }) {
				$self->connection->irc_privmsg({
					channel => $channel, 
					message => $output
				});
			}
		}
	}
	return $self->pass;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::Hit - Dis(디스) Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

	I don't know about origin of a word 'dis'
	some day a3r0 said, hongbot: hit jeen
	so i made this.

	# assume here at a irc channel
	HH:MM:SS    NICK | BOTNAME dis NICK
	HH:MM:SS BOTNAME | NICK: #@!##$@!@#(random dis message, you can type dis message to configuration file)

	# also you can send a dis message hide behind the BOT
	HH:MM:SS    NICK | /msg BOTNAME dis NICK OH! SHIT!
	HH:MM:SS BOTNAME | NICK: OH! SHIT!

=head1 DESCRIPTION

=head2 COMMAND

=over

=item 1 BOTNAME dis

=item 2 BOTNAME dis message

=item 3 /msg BOTNAME dis

=item 4 /msg BOTNAME dis message

=back

C<hit> is C<dis> alias

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

