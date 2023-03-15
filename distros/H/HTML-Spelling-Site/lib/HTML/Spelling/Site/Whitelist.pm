package HTML::Spelling::Site::Whitelist;
$HTML::Spelling::Site::Whitelist::VERSION = '0.10.3';
use strict;
use warnings;
use autodie;

use 5.014;

use MooX (qw( late ));

use Path::Tiny 0.144 qw/ path /;

has '_general_whitelist' => ( is => 'ro', default => sub { return []; } );
has '_records'           => ( is => 'ro', default => sub { return []; } );
has '_general_hashref'   => ( is => 'ro', default => sub { return +{}; } );
has '_per_file'          => ( is => 'ro', default => sub { return +{}; } );
has '_was_parsed'        => ( is => 'rw', default => '' );
has 'filename'           => ( is => 'ro', isa     => 'Str', required => 1 );

sub check_word
{
    my ( $self, $args ) = @_;

    my $filename = $args->{filename};
    my $word     = $args->{word};

    return (
               exists( $self->_general_hashref->{$word} )
            or exists( $self->_per_file->{$filename}->{$word} )
    );
}

sub parse
{
    my ($self) = @_;

    if ( !$self->_was_parsed() )
    {

        my $rec;
        open my $fh, '<:encoding(utf8)', $self->filename;
        my $found_global = 0;
        while ( my $l = <$fh> )
        {
            chomp($l);

            # Whitespace or comment - skip.
            if ( $l !~ /\S/ or ( $l =~ /\A\s*#/ ) )
            {
                # Do nothing.
            }
            elsif ( $l =~ s/\A====\s+// )
            {
                if ( $l =~ /\AGLOBAL:\s*\z/ )
                {
                    if ( defined($rec) )
                    {
                        die "GLOBAL is not the first directive.";
                    }
                    $found_global = 1;
                }
                elsif ( $l =~ /\AIn:\s*(.*)/ )
                {
                    my @filenames = split /\s*,\s*/, $1;

                    if ( defined($rec) )
                    {
                        push @{ $self->_records }, $rec;
                    }

                    my %found;
                    foreach my $fn (@filenames)
                    {
                        if ( exists $found{$fn} )
                        {
                            die
"Filename <<$fn>> appears twice in line <<=== In: $l>>";
                        }
                        $found{$fn} = 1;
                    }
                    $rec = {
                        'files' => [ sort { $a cmp $b } @filenames ],
                        'words' => [],
                        },
                        ;
                }
                else
                {
                    die "Unknown directive <<==== $l>>!";
                }
            }
            else
            {
                if ( defined($rec) )
                {
                    push @{ $rec->{'words'} }, $l;
                }
                else
                {
                    if ( !$found_global )
                    {
                        die "GLOBAL not found before first word.";
                    }
                    push @{ $self->_general_whitelist }, $l;
                }
            }
        }
        if ( defined $rec )
        {
            push @{ $self->_records }, $rec;
        }
        close($fh);

        foreach my $w ( @{ $self->_general_whitelist } )
        {
            $self->_general_hashref->{$w} = 1;
        }

        foreach my $rec ( @{ $self->_records } )
        {
            my @lists;
            foreach my $fn ( @{ $rec->{files} } )
            {
                push @lists, ( $self->_per_file->{$fn} //= +{} );
            }

            foreach my $w ( @{ $rec->{words} } )
            {
                foreach my $l (@lists)
                {
                    $l->{$w} = 1;
                }
            }
        }
    }
    $self->_was_parsed(1);

    return;
}

sub _rec_sorter
{
    my ( $a_aref, $b_aref, $idx ) = @_;

    return (
          ( @$a_aref == $idx ) ? ( ( @$a_aref == @$b_aref ) ? 0 : -1 )
        : ( @$b_aref == $idx ) ? 1
        : ( ( $a_aref->[$idx] cmp $b_aref->[$idx] )
                || _rec_sorter( $a_aref, $b_aref, $idx + 1 ) )
    );
}

sub _sort_words
{
    my $words_aref = shift;

    return [ sort { $a cmp $b } @$words_aref ];
}

sub _rec_cmp
{
    my ( $aa, $bb ) = @_;
    return _rec_sorter( $aa->{files}, $bb->{files}, 0 );
}

sub get_sorted_text
{
    my ($self) = @_;

    $self->parse;

    my %_gen = map { $_ => 1 } @{ $self->_general_whitelist };

    my @sorted_records =
        sort { _rec_cmp( $a, $b ) } @{ $self->_records };

    my @merged_records;
    {
        my $i = 0;
        while ( $i < @sorted_records )
        {
            my $final_i = $i;
            while (
                $final_i < $#sorted_records
                and _rec_cmp(
                    $sorted_records[$i], $sorted_records[ $final_i + 1 ]
                ) == 0
                )
            {
                ++$final_i;
            }
            if ( $i == $final_i )
            {
                push @merged_records, $sorted_records[$i];
            }
            else
            {
                my $rec = {
                    files => $sorted_records[$i]->{files},
                    words => [
                        map { @{ $_->{words} } }
                            @sorted_records[ $i .. $final_i ]
                    ],
                };
                push @merged_records, $rec;
            }
            $i = $final_i + 1;
        }
    }

    return join '', map { "$_\n" } (
        "==== GLOBAL:",
        '',
        @{ _sort_words( [ keys %_gen ] ) },
        (
            map {
                my %found;
                (
                    '',
                    ( "==== In: " . join( ' , ', @{ $_->{files} } ) ),
                    '',
                    (
                        @{
                            _sort_words(
                                [
                                    grep {
                                                !exists( $_gen{$_} )
                                            and !( $found{$_}++ )
                                    } @{ $_->{words} }
                                ]
                            )
                        }
                    )
                )
            } @merged_records
        )
    );
}

sub _get_fh
{
    my ($self) = @_;

    return path( $self->filename );
}

sub is_sorted
{
    my ($self) = @_;

    $self->parse;

    return ( $self->_get_fh->slurp_utf8() eq $self->get_sorted_text );
}

sub write_sorted_file
{
    my ($self) = @_;

    $self->parse;

    $self->_get_fh->spew_utf8( $self->get_sorted_text );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Spelling::Site::Whitelist - handles the whitelist file.

=head1 VERSION

version 0.10.3

=head1 SYNOPSIS

    use HTML::Spelling::Site::Whitelist;

    my $obj = HTML::Spelling::Site::Whitelist->new(
        {
            filename => 'path/to/whitelist.txt',
        }
    );

    $obj->parse;

    if (! $obj->check_word('clover'))
    {
        # Do more spell checking.
    }

    $obj->write_sorted_file;

=head1 DESCRIPTION

The instances of this class can be used to manage a whitelist of words to
spell check.

=head1 METHODS

=head2 my $obj = HTML::Spelling::Site::Checker->new({ filename => './path/to/whitelist.txt'});

Initialises a new object. C<filename> is the path to the file.

=head2 $whitelist->parse;

For now you should call this method right after the object is created.

=head2 $finder->check_word({filename => $filename, word => $word})

Checks if the word $word in the file $filename is in the whitelist.

=head2 $finder->write_sorted_file;

Rewrites the file to be sorted and canonicalized.

=head2 $finder->is_sorted();

Checks if the file is properly sorted and canonicalized.

=head2 $finder->get_sorted_text()

Returns the sorted text of the whitelist.

=head2 $finder->filename()

Returns the filename.

=head1 WHITELIST FORMAT

The format of the whitelist file is:

    ==== GLOBAL:

    [Global whitelist with one word per line]

    ==== In: path1 , path2 , path3

    [one word per line whitelist for path1, path2 and path3]

    ==== In: path4

    [one word per line whitelist for path4]

(B<NOTE> that the paths are a complete path to the file and not parsed for
wildcards or regular expression syntax.)

Here's another example:

L<https://github.com/shlomif/shlomi-fish-homepage/blob/master/lib/hunspell/whitelist1.txt>

You should keep the whitelist file canonicalised and sorted by using
write_sorted_file() and is_sorted() .

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
