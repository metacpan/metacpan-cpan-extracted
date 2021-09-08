package File::TreeCreate;
$File::TreeCreate::VERSION = '0.0.1';
use autodie;
use strict;
use warnings;

use Carp       ();
use File::Spec ();

sub new
{
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init
{
    return;
}

sub get_path
{
    my $self = shift;
    my $path = shift;

    my @components;

    if ( $path =~ s{^\./}{} )
    {
        push @components, File::Spec->curdir();
    }

    my $is_dir = ( $path =~ s{/$}{} );
    push @components, split( /\//, $path );
    if ($is_dir)
    {
        return File::Spec->catdir(@components);
    }
    else
    {
        return File::Spec->catfile(@components);
    }
}

sub exist
{
    my $self = shift;
    return ( -e $self->get_path(@_) );
}

sub is_file
{
    my $self = shift;
    return ( -f $self->get_path(@_) );
}

sub is_dir
{
    my $self = shift;
    return ( -d $self->get_path(@_) );
}

sub cat
{
    my $self = shift;
    open my $in, "<", $self->get_path(@_)
        or Carp::confess("cat failed!");
    my $data;
    {
        local $/;
        $data = <$in>;
    }
    close($in);
    return $data;
}

sub ls
{
    my $self = shift;
    opendir my $dir, $self->get_path(@_)
        or Carp::confess("opendir failed!");
    my @files =
        sort { $a cmp $b } File::Spec->no_upwards( readdir($dir) );
    closedir($dir);
    return \@files;
}

sub create_tree
{
    my ( $self, $unix_init_path, $tree ) = @_;
    my $real_init_path = $self->get_path($unix_init_path);
    return $self->_real_create_tree( $real_init_path, $tree );
}

sub _real_create_tree
{
    my ( $self, $init_path, $tree ) = @_;
    my $name = $tree->{'name'};
    if ( $name =~ s{/$}{} )
    {
        my $dir_name = File::Spec->catfile( $init_path, $name );
        mkdir($dir_name);
        if ( exists( $tree->{'subs'} ) )
        {
            foreach my $sub ( @{ $tree->{'subs'} } )
            {
                $self->_real_create_tree( $dir_name, $sub );
            }
        }
    }
    else
    {
        open my $out, ">", File::Spec->catfile( $init_path, $name );
        print {$out}
            +( exists( $tree->{'contents'} ) ? $tree->{'contents'} : "" );
        close($out);
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::TreeCreate - recursively create a directory tree.

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use File::TreeCreate ();

    my $t = File::TreeCreate->new();

    my $tree = {
        'name' => "tree-create--tree-test-1/",
        'subs' => [
            {
                'name'     => "b.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "a/",
            },
            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    $t->create_tree( "./t/sample-data/", $tree );

    # TEST
    is_deeply(
        $t->ls("./t/sample-data/tree-create--tree-test-1"),
        [ "a", "b.doc", "foo" ],
        "Testing the contents of the root tree"
    );

=head1 DESCRIPTION

This module was extracted from several near-identical copies used in the tests
of some of my CPAN distributions.

=head1 METHODS

=head2 $obj->cat($path)

Slurp the file.

=head2 $obj->create_tree($unix_init_path, $tree)

create the tree.

=head2 $obj->exist($path)

Does the path exist

=head2 $obj->get_path($path)

Canonicalize the path from UNIX-like.

=head2 $obj->is_dir($path)

is the path a directory.

=head2 $obj->is_file($path)

is the path a file.

=head2 $obj->ls($dir_path)

list files in a directory

=head2 my $obj = File::TreeCreate->new()

Instantiates a new object.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/File-TreeCreate>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-TreeCreate>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/File-TreeCreate>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/File-TreeCreate>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=File-TreeCreate>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=File::TreeCreate>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-file-treecreate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=File-TreeCreate>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-File-TreeCreate>

  git clone git://github.com/shlomif/perl-File-TreeCreate.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-File-TreeCreate/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
