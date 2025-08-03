package Pod::Weaver::Section::InstallationInstructions;

# ABSTRACT: generate POD with installation instructions

use v5.20;

use Moose;
with 'Pod::Weaver::Role::Section';

use List::Util qw( first );
use Module::Metadata 1.000015;
use MooseX::MungeHas;
use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Pod5::Region;
use Pod::Elemental::Element::Pod5::Verbatim;
use Types::Common qw( Enum NonEmptySimpleStr SimpleStr );

use experimental qw( lexical_subs postderef signatures );

use namespace::autoclean;

our $VERSION = 'v0.1.2';


has header => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    default => 'INSTALLATION',
);


has region => (
    is      => 'lazy',
    isa     => SimpleStr,
    default => '',
);


has builder => (
    is        => 'ro',
    isa       => Enum [qw( Makefile.PL Build.PL )],
    predicate => 1,
);

sub weave_section( $self, $document, $input ) {

    my $zilla = $input->{zilla};

    # TODO change to work without zilla
    my $meta = Module::Metadata->new_from_file( $zilla->main_module->name );
    my $pkg  = $meta->name;

    my @pod = (

        Pod::Elemental::Element::Pod5::Ordinary->new(
            {
                content =>
"The latest version of this module (along with any dependencies) can be installed from L<CPAN|https://www.cpan.org> with the C<cpan> tool that is included with Perl:"
            }
        ),
        Pod::Elemental::Element::Pod5::Verbatim->new(
            {
                content => "    cpan ${pkg}",
            }
        ),

        Pod::Elemental::Element::Pod5::Ordinary->new(
            {
                content => "You can also extract the distribution archive and install this module (along with any dependencies):"
            }
        ),
        Pod::Elemental::Element::Pod5::Verbatim->new(
            {
                content => "    cpan .",
            }
        ),
    );

    my $builder = $self->has_builder ? $self->builder : "";

    my @files = $zilla ? $zilla->files->@* : ();

    if ( !$builder && $zilla ) {

        if ( my $type = first { $_->name =~ /\A(?:Build|Makefile)\.PL\z/ } @files ) {
            $builder = $type->name;
        }
    }

    if ($builder) {
        my $cmd = $builder =~ /^Build/ ? "perl Build" : "make";

        push @pod, (

            Pod::Elemental::Element::Pod5::Ordinary->new(
                {
                    content => "You can also install this module manually using the following commands:"
                }
            ),
            Pod::Elemental::Element::Pod5::Verbatim->new(
                {
                    content => <<"POD_MANUAL_INSTALL",
    perl ${builder}
    ${cmd}
    ${cmd} test
    ${cmd} install
POD_MANUAL_INSTALL
                }
            ),
        );
    }

    if ($zilla) {

        my $example = $builder ? "F<${builder}> file" : "builder file such as L<Makefile.PL>";

        push @pod, (

            Pod::Elemental::Element::Pod5::Ordinary->new(
                {
                    content =>
"If you are working with the source repository, then it may not have a ${example}.  But you can use the L<Dist::Zilla|https://dzil.org/> tool in anger to build and install this module:"
                }
            ),
            Pod::Elemental::Element::Pod5::Verbatim->new(
                {
                    content => <<"POD_DZIL_INSTALL",
    dzil build
    dzil test
    dzil install --install-command="cpan ."
POD_DZIL_INSTALL
                }
            ),
        );

    }

    my $also = "L<How to install CPAN modules|https://www.cpan.org/modules/INSTALL.html>";
    if ( my $doc = first { $_->name =~ /\AINSTALL(?:\.(txt|md|mkdn))?\z/i } @files ) {
        $also = sprintf( 'the F<%s> file included with this distribution', $doc->name );
    }

    push @pod, Pod::Elemental::Element::Pod5::Ordinary->new( { content => "For more information, see ${also}." } );

    my $res = Pod::Elemental::Element::Nested->new(
        {
            type     => 'command',
            command  => 'head1',
            content  => $self->header,
            children => \@pod,
        }
    );

    if ( my $name = $self->region ) {

        push $document->children->@*,
          Pod::Elemental::Element::Pod5::Region->new(
            {
                format_name => $name =~ s/^://r,
                is_pod      => 1,
                content     => '',
                children    => [$res],
            }
          );

    }
    else {
        push $document->children->@*, $res;
    }

}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::InstallationInstructions - generate POD with installation instructions

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

In the F<weaver.ini>

    [InstallationInstructions]
    header  = INSTALLATION
    builder = Makefile.PL
    region  = :readme

=head1 DESCRIPTION

This is a L<Pod::Weaver> plugin to add a section with installation instructions.

The installation instructions will look something like

    INSTALLATION

    The latest version of this module (along with any dependencies) can be
    installed from CPAN <https://www.cpan.org> with the cpan tool that is
    included with Perl:

        cpan Pod::Weaver::Section::InstallationInstructions

    You can also extract the distribution archive and install this module
    (along with any dependencies):

        cpan .

    You can also install this module manually using the following commands:

        perl Makefile.PL
        make
        make test
        make install

    If you are working with the source repository, then it may not have a
    Makefile.PL file. But you can use the Dist::Zilla <https://dzil.org/>
    tool in anger to build and install this module:

        dzil build
        dzil test
        dzil install --install-command="cpan ."

    For more information, see How to install CPAN modules
    <https://www.cpan.org/modules/INSTALL.html>.

The actual text will depend on how it is configured, and what files are in the distribution.

=head1 CONFIGURATION OPTIONS

=head2 header

The header to use. It defaults to "INSTALLATION".

=head2 region

When set to a non-empty string, the section will be embedded in a POD region, e.g.

    region = :readme

to make the region available for L<Dist::Zilla::Plugin::UsefulReadme> or L<Pod::Readme>.

=head2 builder

This indicates the kind of builder used, either C<Makefile.PL> from L<ExtUtils::MakeMaker> or C<Build.PL> from
L<Module::Build> and variants.

If unset, it will attempt to guess.  If it cannot guess, the instructions will be omitted.

=for Pod::Coverage weave_section

=head1 SEE ALSO

L<Pod::Weaver::Section::Installation>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme>
and may be cloned from L<git://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme.git>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
