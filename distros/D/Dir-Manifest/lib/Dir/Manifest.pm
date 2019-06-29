package Dir::Manifest;
$Dir::Manifest::VERSION = '0.2.0';
use strict;
use warnings;

use 5.014;

use Path::Tiny qw/ path /;
use Dir::Manifest::Key   ();
use Dir::Manifest::Slurp ();

use Moo;

has 'manifest_fn' => ( is => 'ro', required => 1 );
has 'dir'         => ( is => 'ro', required => 1 );

my $ALLOWED = qr/[a-zA-Z0-9_\-\.=]/;
my $ALPHAN  = qr/[a-zA-Z0-9_]/;
has '_keys' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my @lines = path( $self->manifest_fn )->lines( { chomp => 1 } );
        my $ret   = +{};

        foreach my $l (@lines)
        {
            if ( $l !~ /\A(?:$ALLOWED)+\z/ )
            {
                die
"Invalid characters in key \"$l\"! We only allow A-Z, a-z, 0-9, _, dashes and equal signs.";
            }
            if ( $l !~ /\A$ALPHAN/ )
            {
                die qq#Key does not start with an alphanumeric - "$l"!#;
            }
            if ( $l !~ /$ALPHAN\z/ )
            {
                die qq#Key does not end with an alphanumeric - "$l"!#;
            }
            $ret->{$l} = 1;
        }
        return $ret;
    }
);

has '_dh' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path( $self->dir );
    },
);

sub get_keys
{
    my ($self) = @_;

    return [ sort { $a cmp $b } keys %{ $self->_keys } ];
}

sub get_obj
{
    my ( $self, $key ) = @_;

    if ( not exists $self->_keys->{$key} )
    {
        die "No such key \"$key\"! Perhaps add it to the manifest.";
    }
    return Dir::Manifest::Key->new(
        { key => $key, fh => $self->_dh->child($key) } );
}

sub fh
{
    my ( $self, $key ) = @_;

    return $self->get_obj($key)->fh;
}

sub text
{
    my ( $self, $key, $opts ) = @_;

    return Dir::Manifest::Slurp::slurp( $self->fh($key), $opts );
}

sub texts_dictionary
{
    my ( $self, $args ) = @_;

    my $opts = $args->{slurp_opts};

    return +{ map { $_ => $self->text( $_, $opts ) } @{ $self->get_keys } };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dir::Manifest

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Dir::Manifest ();

    my $obj = Dir::Manifest->new(
        {
            manifest_fn => "./t/data/texts/list.txt",
            dir         => "./t/data/texts/texts",
        }
    );

    # TEST
    is (
        scalar(`my-process ...`),
        $obj->text("my-process-output1", {lf => 1,}),
        "Good output of my-process.",
    );

=head1 DESCRIPTION

Here is the primary use case: you have several long texts (and/or binary blobs) that you
wish to load from the code (e.g: for the "want"/expected values of tests) and you wish to
conventiently edit them, track them and maintain them. Using L<Dir::Manifest> you can
put each in a separate file in a directory, create a manifest file listing all valid
filenames/key and then say something like
C<<< my $text = $dir->text("deal24solution.txt", {lf => 1}) >>>. And hopefully it will
be done securely and reliably.

=head1 NAME

Dir::Manifest - treat a directory and a manifest file as a hash/dictionary of keys to texts or blobs

=head1 VERSION

version 0.2.0

=head1 METHODS

=head2 $self->manifest_fn()

The path to the manifest file.

=head2 $self->dir()

The path to the directory containing the texts and blobs as files.

=head2 $self->get_keys()

Returns a sorted array reference containing the available keys as strings.

=head2 $self->get_obj($key)

Returns the L<Dir::Manifest::Key> object associated with the string $key.
Throws an error if $key was not given in the manifest.

=head2 $self->fh($key)

Returns the L<Path::Tiny> objects for the key, which is usable as a path
in string context. Equivalent to C<<< $self->get_obj($key)->fh() >>>.

(Added in version 0.2.0. ).

=head2 my $contents = $self->text("$key", {%OPTS})

Slurps the key using L<Dir::Manifest::Slurp>

=head2 my $hash_ref = $obj->texts_dictionary( {slurp_opts => {},} );

Returns a hash reference (a dictionary) containing all keys and their slurped contents
as values. C<'slurp_opts'> is passed to text().

=head1 DEDICATION

This code is dedicated to the memory of L<Jonathan Scott Duff|https://metacpan.org/author/DUFF>
a.k.a PerlJam and perlpilot who passed away some days before the first release of
this code. For more about him, see:

=over 4

=item * L<https://p6weekly.wordpress.com/2018/12/30/2018-53-goodbye-perljam/>

=item * L<https://www.facebook.com/groups/perl6/permalink/2253332891599724/>

=item * L<https://www.mail-archive.com/perl6-users@perl.org/msg06390.html>

=item * L<https://www.shlomifish.org/humour/fortunes/sharp-perl.html>

=back

=head1 MEDIA RECOMMENDATION

L<kristian vuljar|https://www.jamendo.com/artist/441226/kristian-vuljar> used to
have a jamendo track called "Keys" based on L<Shine 4U|https://www.youtube.com/watch?v=B8ehY5tutHs> by Carmen and Camille. You can find it at L<http://www.shlomifish.org/Files/files/dirs/kristian-vuljar--keys/> .

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Dir-Manifest>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dir-Manifest>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dir-Manifest>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dir-Manifest>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dir-Manifest>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dir-Manifest>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dir-Manifest>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dir-Manifest>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dir::Manifest>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dir-manifest at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dir-Manifest>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Dir-Manifest>

  git clone https://github.com/shlomif/Dir-Manifest.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/dir-manifest/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
