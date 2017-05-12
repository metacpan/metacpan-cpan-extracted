# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Plugin-Git-DescribeVersion
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::DescribeVersion;
{
  $Dist::Zilla::Plugin::Git::DescribeVersion::VERSION = '1.004';
}
# git description: v1.003-5-gff644eb

BEGIN {
  $Dist::Zilla::Plugin::Git::DescribeVersion::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Provide version using git-describe

use Dist::Zilla 4 ();
use Git::DescribeVersion ();
use Moose;

with 'Dist::Zilla::Role::VersionProvider';

while( my ($name, $default) = each %Git::DescribeVersion::Defaults ){
  has $name => ( is => 'ro', isa=>'Str', default => $default );
}

sub provide_version {
  my ($self) = @_;

  # override (or maybe needed to initialize)
  return $ENV{V} if exists $ENV{V};

  # less overhead to use %Defaults than MOP meta API
  my $opts = { map { $_ => $self->$_() }
    keys %Git::DescribeVersion::Defaults };

  my $new_ver = eval {
    Git::DescribeVersion->new($opts)->version;
  };

  $self->log_fatal("Could not determine version from tags: $@")
    unless defined $new_ver;

  $self->log("Git described version as $new_ver");

  $self->zilla->version("$new_ver");
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS repo cpan testmatrix url annocpan anno
bugtracker rt cpants kwalitee diff irc mailto metadata placeholders
metacpan

=head1 NAME

Dist::Zilla::Plugin::Git::DescribeVersion - Provide version using git-describe

=head1 VERSION

version 1.004

=head1 SYNOPSIS

In your F<dist.ini>:

  [Git::DescribeVersion]
  match_pattern  = v[0-9]*     ; this is the default

=head1 DESCRIPTION

This performs the L<Dist::Zilla::Role::VersionProvider> role.
It uses L<Git::DescribeVersion> to count the number of commits
since the last tag (matching I<match_pattern>) or since the initial commit,
and uses the result as the I<version> parameter for your distribution.

The plugin accepts the same options as
L<Git::DescribeVersion/new>.
See L<Git::DescribeVersion/OPTIONS>.

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release

=head1 USAGE

B<Note>: Since L<Git::DescribeVersion>
appends the third part to a two-part version tag
(for example, a tag of C<v1.2> becomes C<v1.2.35>)
This plugin is not designed to be combined with
L<Dist::Zilla::Plugin::Git::Tag>
(which will tag the repo with the generated version).

Instead it works better with manual tags.
For example, you might manually increase the minor version
(from C<v1.2> to C<v1.3>) when a big feature is added or the API changes.
Then each build will append the number of commits as the revision number
(C<v1.3> becomes C<v1.3.28>).

This is probably more useful for projects without formal releases.
This is in fact the only way that the author still uses the module:
For C<$work> projects where builds are deployed often
to a variety of internal environments.

For projects released to the world I suggest using the simple and logical
L<Dist::Zilla::Plugin::Git::NextVersion>
which does work nicely with
L<Dist::Zilla::Plugin::Git::Tag>.

=for Pod::Coverage provide_version

=head1 SEE ALSO

=over 4

=item *

L<Git::DescribeVersion>

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::Git::NextVersion>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Git::DescribeVersion

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Git-DescribeVersion>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Git-DescribeVersion>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Git-DescribeVersion>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Git-DescribeVersion>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Git-DescribeVersion>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Git::DescribeVersion>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-git-describeversion at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-Git-DescribeVersion>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Plugin-Git-DescribeVersion>

  git clone https://github.com/rwstauner/Dist-Zilla-Plugin-Git-DescribeVersion.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

