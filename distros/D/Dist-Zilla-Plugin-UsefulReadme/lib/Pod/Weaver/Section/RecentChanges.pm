package Pod::Weaver::Section::RecentChanges;

# ABSTRACT: generate POD with the recent changes

use v5.20;

use Moose;
with 'Pod::Weaver::Role::Section';

use CPAN::Changes::Parser 0.500002;
use List::Util qw( first );
use MooseX::MungeHas;
use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Pod5::Region;
use Types::Common qw( NonEmptySimpleStr SimpleStr );

use experimental qw( lexical_subs postderef signatures );

use namespace::autoclean;

our $VERSION = 'v0.1.1';


has header => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    default => 'RECENT CHANGES',
);


has changelog => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    default => 'Changes',
);


has version => (
    is      => 'lazy',
    isa     => SimpleStr,
    default => '',
);


has region => (
    is      => 'lazy',
    isa     => SimpleStr,
    default => '',
);

sub weave_section( $self, $document, $input ) {

    my $zilla = $input->{zilla};

    unless ($zilla) {
        $self->log_fatal("missing zilla argument");
        return;
    }

    my $file = first { $_->name eq $self->changelog } $zilla->files->@* or return;

    my $version = $self->version || ( $input->{version} // $zilla->version );

    my $re     = quotemeta($version);
    my $parser = CPAN::Changes::Parser->new( version_like => qr/$re/ );

    my $changelog = $parser->parse_string( $file->content );

    # Ignore if there is only one release, e.g. "Initial release"
    return if $changelog->releases <= 1;

    state sub _release_to_pod($entry) {

        my $pod = [];
        push $pod->@*,
          (
            Pod::Elemental::Element::Pod5::Command->new(
                {
                    command => 'item',
                    content => '*'
                }
            ),
            Pod::Elemental::Element::Pod5::Ordinary->new( { content => $entry->text } )
          ) if $entry->can("text");

        if ( my @entries = $entry->entries->@* ) {

            push $pod->@*,
              (
                Pod::Elemental::Element::Pod5::Command->new(
                    {
                        command => 'over',
                        content => '4',
                    }
                ),
                ( map { __SUB__->($_) } @entries ),
                Pod::Elemental::Element::Pod5::Command->new(
                    {
                        command => 'back',
                        content => '',
                    }
                )
              );
        }

        return $pod->@*;

    }

    my $release = $changelog->find_release($version) or return;

    my $text = "Changes for version " . $version;
    if ( my $date = $release->date ) {
        $text .= sprintf( ' (%s)', substr( $date, 0, 10 ) );
    }

    my $res = Pod::Elemental::Element::Nested->new(
        {
            type     => 'command',
            command  => 'head1',
            content  => $self->header,
            children => [
                Pod::Elemental::Element::Pod5::Ordinary->new( { content => $text } ),
                _release_to_pod($release),
                Pod::Elemental::Element::Pod5::Ordinary->new(
                    { content => sprintf( 'See the F<%s> file for more details.', $self->changelog ) }
                )
            ],
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

Pod::Weaver::Section::RecentChanges - generate POD with the recent changes

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

In the F<weaver.ini>

    [RecentChanges]
    header    = RECENT CHANGES
    changelog = Changes
    region    = :readme

=head1 DESCRIPTION

This is a L<Pod::Weaver> plugin to add a section with the changelog entries for the current version.

=head1 CONFIGURATION OPTIONS

=head2 header

The header to use. It defaults to "RECENT CHANGES".

=head2 changelog

The name of the change log. It defaults to "Changes".

=head2 version

This is the release version to show.

The only reason to set this is if you need to specify the L<Dist::Zilla> version placeholder because you want to insert
the recent changes into the module POD, e.g.

    version = {{$NEXT}}

=head2 region

When set to a non-empty string, the section will be embedded in a POD region, e.g.

    region = :readme

to make the region available for L<Dist::Zilla::Plugin::UsefulReadme> or L<Pod::Readme>.

=for Pod::Coverage weave_section

=head1 SEE ALSO

L<Pod::Weaver::Section::Changes>

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
