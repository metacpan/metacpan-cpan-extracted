package Horris::Connection::Plugin::PowerManager;
# ABSTRACT: PowerManager Plugin on Horris


use Moose;
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

sub irc_privmsg {
	my ($self, $message) = @_;
	my $msg = $message->message;
	my $botname = $self->connection->nickname;
	$self->connection->irc->disconnect if $msg =~ m{^$botname\S*\s+(:?꺼져|껒여|exit|quit)};
	return $self->pass;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::PowerManager - PowerManager Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

	HH:MM:SS    NICK | BOTNAME [꺼져|껒여|exit|quit]
	HH:MM:SS     <-- | BOTNAME (nick@some.host) has quit (Remote host closed the connection)

=head1 DESCRIPTION

Anybody can kick the bot if needed.

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

