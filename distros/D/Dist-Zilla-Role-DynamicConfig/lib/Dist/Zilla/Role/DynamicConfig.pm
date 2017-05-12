# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Role-DynamicConfig
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Role::DynamicConfig;
BEGIN {
  $Dist::Zilla::Role::DynamicConfig::VERSION = '1.002';
}
BEGIN {
  $Dist::Zilla::Role::DynamicConfig::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: A Role that accepts a dynamic configuration

use Dist::Zilla 4 ();
use Moose::Role;


has _config => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} }
);


# TODO: use around ? call $orig-> ? call super() ?

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  confess 'do not try to pass _config as a build arg!'
    if $copy{_config};

  my $other = $class->separate_local_config(\%copy);

  return {
    zilla => $zilla,
    plugin_name => $name,
    _config     => \%copy,
    %$other
  }
}


requires 'separate_local_config';

no Moose::Role;
1;


__END__
=pod

=for :stopwords Randy Stauner BUILDARGS cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders

=head1 NAME

Dist::Zilla::Role::DynamicConfig - A Role that accepts a dynamic configuration

=head1 VERSION

version 1.002

=head1 DESCRIPTION

This is a role for a L<Plugin|Dist::Zilla::Role::Plugin>
(or possibly other classes)
that accepts a dynamic configuration.

Plugins performing this role must define L</separate_local_config>.

=head1 ATTRIBUTES

=head2 _config

A hashref where the dynamic options will be stored.

Do not attempt to assign to this from your F<dist.ini>.

=head1 METHODS

=head2 BUILDARGS

Copied/modified from L<Dist::Zilla::Plugin::Prereqs>
to allow arbitrary values to be specified.

This overwrites the L<Moose::Object> method
called to prepare arguments before instantiation.

It separates the expected arguments
(including anything caught by L</separate_local_config>)
and places the remaining unknown/dynamic arguments into L</_config>.

=head2 separate_local_config

Separate any arguments that should be stored directly on the object
rather than in the dynamic L</_config> attribute.

Remove those arguments from the passed in hashref,
make any necessary modifications (like renaming the keys if desired),
and return a hashref with the result.

Required.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Role::DynamicConfig

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Role-DynamicConfig>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Role-DynamicConfig>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Role-DynamicConfig>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Role-DynamicConfig>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Role-DynamicConfig>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Role::DynamicConfig>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-role-dynamicconfig at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Role-DynamicConfig>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<http://github.com/rwstauner/Dist-Zilla-Role-DynamicConfig>

  git clone http://github.com/rwstauner/Dist-Zilla-Role-DynamicConfig

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

