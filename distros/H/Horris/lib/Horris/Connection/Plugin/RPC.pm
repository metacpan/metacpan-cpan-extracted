package Horris::Connection::Plugin::RPC;
# ABSTRACT: RPC Plugin on Horris


use Moose;
use AnyEvent::MP qw(configure port rcv);
use AnyEvent::MP::Global qw(grp_reg);
use namespace::clean -except => qw/meta/;
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has '+is_enable' => (
	default => 0
);

after init => sub {
	my $self = shift;
	configure nodeid => "eg_receiver", binds => ["*:4040"];
	my $port = port;
	grp_reg eg_receivers => $port;
	rcv $port, test => sub {
		my ($data) = @_;
		$self->connection->irc_privmsg({
			channel => '#aanoaa', # for test
			message => $data
		});
	}
};

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::RPC - RPC Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

Not yet implemented.

=head1 DESCRIPTION

Not yet implemented.

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

