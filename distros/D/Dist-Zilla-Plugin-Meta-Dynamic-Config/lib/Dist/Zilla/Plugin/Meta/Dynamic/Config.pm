package Dist::Zilla::Plugin::Meta::Dynamic::Config;
{
  $Dist::Zilla::Plugin::Meta::Dynamic::Config::VERSION = '0.04';
}

# ABSTRACT: set dynamic_config in resultant META files

use Moose;

has dynamic_config => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

with 'Dist::Zilla::Role::Meta::Dynamic::Config';

__PACKAGE__->meta->make_immutable;
no Moose;

qq[I am an object in motion];


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Meta::Dynamic::Config - set dynamic_config in resultant META files

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # In dist.ini

  [Meta::Dynamic::Config]

=head1 DESCRIPTION

Dist::Zilla::Plugin::Meta::Dynamic::Config is a L<Dist::Zilla> plugin that allows an author to
specify in the C<META.json> and/or C<META.yml> files produced by L<Dist::Zilla> that their
distribution performs some dynamic configuration as per L<CPAN::Meta::Spec>.

Normally this would not be required, but if you are providing your own C<Makefile.PL> or L<Build.PL>
and asking questions, sensing the environment, etc. to generate a list of prereqs then C<dynamic_config>
should be set to a true value to satisfy the Meta specification.

=head1 SEE ALSO

L<Dist::Zilla>

L<CPAN::Meta::Spec>

L<Dist::Zilla::Plugin::FakeFaker>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

