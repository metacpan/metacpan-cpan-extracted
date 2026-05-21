package Dist::Zilla::Plugin::IRC;
$Dist::Zilla::Plugin::IRC::VERSION = '0.001';
use 5.020;
use warnings;

use Moose;
with 'Dist::Zilla::Role::MetaProvider';
use experimental 'signatures';
use namespace::autoclean;

use Types::Standard qw/Str/;

has host => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has channel => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

my %host_for_network = (
	perl     => 'irc.perl.org',
	libera   => 'irc.libera.org',
	freenode => 'chat.freenode.org',
	oftc     => 'irc.oftc.net',
);

around BUILDARGS => sub($orig, $class, $args) {
	if (!$args->{host}) {
		my $host = $host_for_network{$args->{network} // 'perl'};
		$args->{host} = $host if defined $host;
	}
	return $class->$orig($args);
};

my %web_for = (
	'irc.libera.org'    => 'https://web.libera.chat/#%s',
	'chat.freenode.org' => 'http://webchat.freenode.net/?channels=%23'
);

sub metadata($self) {
	my %irc;
	$irc{url} = sprintf 'irc://%s/#%s', $self->host, $self->channel;
	my $web = $web_for{$self->host};
	$irc{web} = sprintf $web, $self->channel if defined $web;

	return {
		resources => {
			x_IRC => \%irc,
		}
	};
}

1;

# ABSTRACT: Add a IRC channel resource to your dist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::IRC - Add a IRC channel resource to your dist

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 [IRC]
 channel = distzilla

=head1 DESCRIPTION

This plugin facilitates adding a link to an IRC channel to the resources.

=head1 ATTRIBUTES

=head2 host

The hostname of the IRC channel.

=head2 network

The network that is used, if any. Valid values include C<perl> (the default), C<libera>, C<freenode> and C<oftc>

This is used to give C<host> a default value, and is ignored otherwise.

=head2 channel

The name of the irc channel, this is mandatory for obvious reasons.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
