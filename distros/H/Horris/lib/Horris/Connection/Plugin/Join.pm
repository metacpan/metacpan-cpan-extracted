package Horris::Connection::Plugin::Join;
# ABSTRACT: Auto Join Channel Plugin on Horris


use Moose;
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has channels => (
	is => 'ro', 
	isa => 'ArrayRef', 
);

sub on_connect {
	my ($self) = @_;
	$self->connection->irc->send_srv(JOIN => $_) for @{ $self->channels };
	return $self->pass;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::Join - Auto Join Channel Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

BOT connected IRC, then auto joinning typed(config) channel

	# single channel
	<Plugin Join>
		channels [ \#test ] # for a single channel
	</Plugin>

	# multi channels
	<Plugin Join>
		channels #test1
		channels #test2
	</Plugin>

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

