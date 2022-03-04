package HTML::Spelling::Site::Finder;
$HTML::Spelling::Site::Finder::VERSION = '0.10.0';
use strict;
use warnings;

use 5.014;

use MooX (qw( late ));

use File::Find::Object ();

has 'prune_cb' => ( is => 'ro', isa => 'CodeRef', default => sub { return; } );
has 'root_dir' => ( is => 'ro', isa => 'Str',     'required' => 1, );

sub list_all_htmls
{
    my ($self) = @_;

    my $f = File::Find::Object->new( {}, $self->root_dir );

    my @got;
    while ( my $r = $f->next_obj() )
    {
        my $path = $r->path;
        if ( $self->prune_cb->($path) )
        {
            $f->prune;
        }
        elsif ( $r->is_file and $r->basename =~ /\.x?html\z/ )
        {
            push @got, $path;
        }
    }
    use locale;
    use POSIX qw(locale_h strtod);
    setlocale( LC_COLLATE, 'C' ) or die "cannot set locale.";

    return [ sort @got ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Spelling::Site::Finder - find the relevant .html/.xhtml files in
a directory tree.

=head1 VERSION

version 0.10.0

=head1 SYNOPSIS

    use HTML::Spelling::Site::Finder;

    my $finder = HTML::Spelling::Site::Finder->new(
        {
            prune_cb => sub {
                return (shift =~ m#\Adest/blacklist/#);
            },
            root_dir => 'dest/',
        }
    );

    foreach my $html_file (@{$finder->list_all_htmls()})
    {
        print "Should check <$html_file>.\n";
    }

=head1 DESCRIPTION

The instances of this class can be used to scan a directory tree of files
ending with C<.html> and C<.xhtml> and to return a list of them as a sorted
array reference.

=head1 METHODS

=head2 ->new({ prune_cb => sub { ... }, root_dir => $root_dir })

Initialises a new object. C<prune_cb> is optional and C<root_dir> is required
and is the path to the root of the directory to scan.

=head2 my $array_ref = $finder->list_all_htmls()

Returns an array reference of all HTML files, sorted.

=head2 $finder->prune_cb()

Returns the prune callback. Mostly for internal use.

=head2 $finder->root_dir()

Returns the root directory.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Spelling-Site>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Spelling-Site>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Spelling-Site>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Spelling-Site>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Spelling-Site>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Spelling::Site>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-spelling-site at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Spelling-Site>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/HTML-Spelling-Site>

  git clone https://github.com/shlomif/HTML-Spelling-Site.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/html-spelling-site/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
