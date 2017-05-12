use strict;
use warnings;

package IMS::CP::Manifest;
{
  $IMS::CP::Manifest::VERSION = '0.0.3';
}
use Moose;
with 'XML::Rabbit::RootNode';

use 5.008; # According to Perl::MinimumVersion

# ABSTRACT: IMS Content Packaging Manifest XML parser


has '+namespace_map' => (
    default => sub { {
        'cp'  => 'http://www.imsglobal.org/xsd/imscp_v1p1',
        'lom' => 'http://www.imsglobal.org/xsd/imsmd_v1p2',
    } },
);


has 'title' => (
    isa         => 'IMS::LOM::LangString',
    traits      => [qw/XPathObject/],
    xpath_query => './cp:metadata/lom:lom/lom:general/lom:title',
);


has 'organizations' => (
    isa         => 'ArrayRef[IMS::CP::Organization]',
    traits      => [qw/XPathObjectList/],
    xpath_query => '/cp:manifest/cp:organizations/*',
);

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

IMS::CP::Manifest - IMS Content Packaging Manifest XML parser

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

This is a simple (read-only) parser for IMS Content Packaging manifest XML
files. The specification is available from
L<http://www.imsglobal.org/content/packaging/index.html>. It is still
incomplete, but it enables you to get access to the organization of all the
resources in the manifest and their associated files (and titles).

=head1 ATTRIBUTES

=head2 namespace_map

The prefixes C<cp> and C<lom> are declared for use in XPath queries.

=head2 title

The main title of the manifest.

=head2 organizations

A list of organizations of content. Organizations are basically different
ways to organize the content in the package, e.g. linear or hierarchial.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc IMS::CP::Manifest

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/IMS-CP-Manifest>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/IMS-CP-Manifest>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMS-CP-Manifest>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/IMS-CP-Manifest>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/IMS-CP-Manifest>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/IMS-CP-Manifest>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/IMS-CP-Manifest>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/I/IMS-CP-Manifest>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=IMS-CP-Manifest>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=IMS::CP::Manifest>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-ims-cp-manifest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMS-CP-Manifest>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/robinsmidsrod/IMS-CP-Manifest>

  git clone git://github.com/robinsmidsrod/IMS-CP-Manifest.git

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
