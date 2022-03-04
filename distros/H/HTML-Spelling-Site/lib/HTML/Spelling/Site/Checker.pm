package HTML::Spelling::Site::Checker;
$HTML::Spelling::Site::Checker::VERSION = '0.10.0';
use strict;
use warnings;
use autodie;
use utf8;

use 5.014;

use MooX qw/late/;

use HTML::Parser 3.00 ();
use List::MoreUtils qw(any);
use JSON::MaybeXS qw(decode_json);
use Path::Tiny qw/ path /;
use Digest ();

has '_inside' =>
    ( is => 'rw', isa => 'HashRef', default => sub { return +{}; } );
has 'whitelist_parser'   => ( is => 'ro', required => 1 );
has 'check_word_cb'      => ( is => 'ro', isa => 'CodeRef', required => 1 );
has 'timestamp_cache_fn' => ( is => 'ro', isa => 'Str',     required => 1 );

sub _tag
{
    my ( $self, $tag, $num ) = @_;

    $self->_inside->{$tag} += $num;

    return;
}

sub should_check
{
    my ( $self, $args ) = @_;
    return ( $args->{word} !~ m#\A[\p{Hebrew}\-'’]+\z# );
}

sub _calc_mispellings
{
    my ( $self, $args ) = @_;

    my @ret;

    my $filenames = $args->{files};

    my $whitelist = $self->whitelist_parser;
    $whitelist->parse;

    binmode STDOUT, ":encoding(utf8)";

    my $cache_fh = path( $self->timestamp_cache_fn );

    my $app_key     = 'HTML-Spelling-Site';
    my $data_key    = 'timestamp_cache';
    my $DIGEST_NAME = 'SHA-256';
    my $digest_key  = 'digest_cache';
    my $digest      = Digest->new($DIGEST_NAME);

    my $write_cache = sub {
        my ( $ref, $ddata ) = @_;
        $cache_fh->spew_raw(
            JSON::MaybeXS->new( canonical => 1 )->encode(
                {
                    $app_key => {
                        $data_key   => $ref,
                        $digest_key => { $DIGEST_NAME => $ddata, },
                    },
                },
            )
        );

        return;
    };

    if ( !$cache_fh->exists() )
    {
        $write_cache->( +{}, +{} );
    }

    my $main_json       = decode_json( scalar( $cache_fh->slurp_raw() ) );
    my $timestamp_cache = $main_json->{$app_key}->{$data_key};
    my $digest_cache =
        ( $main_json->{$app_key}->{$digest_key}->{$DIGEST_NAME} // +{} );

    my $check_word = $self->check_word_cb;

FILENAMES_LOOP:
    foreach my $filename (@$filenames)
    {
        my $fp    = path($filename);
        my $mtime = $fp->stat->mtime;
        if ( exists( $timestamp_cache->{$filename} )
            and $timestamp_cache->{$filename} >= $mtime )
        {
            next FILENAMES_LOOP;
        }
        my $d = $digest->clone()->addfile( $fp->openr_raw )->b64digest;
        if ( exists( $digest_cache->{$filename} )
            and $digest_cache->{$filename} eq $d )
        {
            $timestamp_cache->{$filename} = $mtime;

            next FILENAMES_LOOP;
        }

        my $file_is_ok = 1;

        my $process_text = sub {
            if (
                any
                {
                    exists( $self->_inside->{$_} ) and $self->_inside->{$_} > 0
                } qw(script style)
                )
            {
                return;
            }

            my $text = shift;

            my @lines = split /\n/, $text, -1;

            foreach my $l (@lines)
            {

                my $mispelling_found = 0;

                my $mark_word = sub {
                    my ($word) = @_;

                    $word =~ s{’(ve|s|m|d|t|ll|re)\z}{'$1};
                    $word =~ s{[’']\z}{};
                    if ( $word =~ /[A-Za-z]/ )
                    {
                        $word =~
s{\A(?:(?:ֹו?(?:ש|ל|מ|ב|כש|לכש|מה|שה|לכשה|ב-))|ו)-?}{};
                        $word =~ s{'?ים\z}{};
                    }

                    my $verdict = (
                        (
                            !$whitelist->check_word(
                                { filename => $filename, word => $word }
                            )
                        )
                            && $self->should_check( { word => $word } )
                            && ( !( $check_word->($word) ) )
                    );

                    $mispelling_found ||= $verdict;

                    return $verdict ? "«$word»" : $word;
                };

                $l =~ s/
                # Not sure this regex to match a word is fully
                # idiot-proof, but we can amend it later.
                ([\w'’-]+)
                /$mark_word->($1)/egx;

                if ($mispelling_found)
                {
                    $file_is_ok = 0;
                    push @ret,
                        {
                        filename          => $filename,
                        line_num          => 1,
                        line_with_context => $l,
                        };
                }
            }
        };

        HTML::Parser->new(
            api_version => 3,
            handlers    => [
                start => [ sub { return $self->_tag(@_); }, "tagname, '+1'" ],
                end   => [ sub { return $self->_tag(@_); }, "tagname, '-1'" ],
                text  => [ $process_text,                   "dtext" ],
            ],
            marked_sections => 1,
        )->parse_file( $fp->openr_utf8() );

        if ($file_is_ok)
        {
            $timestamp_cache->{$filename} = $mtime;
            $digest_cache->{$filename}    = $d;
        }
    }

    $write_cache->( $timestamp_cache, $digest_cache );

    return { misspellings => \@ret, };
}

sub _format_error
{
    my ( $self, $error ) = @_;

    return sprintf( "%s:%d:%s",
        $error->{filename}, $error->{line_num}, $error->{line_with_context},
    );
}

sub spell_check
{
    my ( $self, $args ) = @_;

    my $misspellings = $self->_calc_mispellings($args);

    foreach my $error ( @{ $misspellings->{misspellings} } )
    {
        printf {*STDOUT} "%s\n", $self->_format_error($error);
    }

    print "\n";
}

sub test_spelling
{
    my ( $self, $args ) = @_;

    my $MAXLEN       = ( $args->{'MAXLEN'}  || 1000 );
    my $MAXSIZE      = ( $args->{'MAXSIZE'} || 20 );
    my $misspellings = $self->_calc_mispellings($args);

    if ( $args->{light} )
    {
        require Test::More;

        my $ret = Test::More::is( scalar( @{ $misspellings->{misspellings} } ),
            0, $args->{blurb} );

        my $output_text = '';
    DIAGLOOP:
        foreach my $error ( @{ $misspellings->{misspellings} } )
        {
            $output_text .= $self->_format_error($error) . "\n";
            if ( length($output_text) >= $MAXLEN )
            {
                $output_text = substr( $output_text, 0, $MAXLEN );
                last DIAGLOOP;
            }
        }
        Test::More::diag($output_text);
        return $ret;
    }
    require Test::Differences;
    my @arr = @{ $misspellings->{misspellings} };
    if ( @arr > $MAXSIZE )
    {
        $#arr = $MAXSIZE - 1;
    }
    return Test::Differences::eq_or_diff( ( \@arr ), [], $args->{blurb}, );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Spelling::Site::Checker - does the actual checking.

=head1 VERSION

version 0.10.0

=head1 SYNOPSIS

In lib/Shlomif/Spelling/FindFiles.pm :

    package Shlomif::Spelling::FindFiles;

    use strict;
    use warnings;

    use MooX qw/late/;
    use List::MoreUtils qw/any/;

    use HTML::Spelling::Site::Finder;

    my @prunes =
    (
        qr#^\Qdest/t2/humour/by-others/how-to-make-square-corners-with-CSS/#,
    );

    sub list_htmls
    {
        my ($self) = @_;

        return HTML::Spelling::Site::Finder->new(
            {
                root_dir => 'dest/t2',
                prune_cb => sub {
                    my ($path) = @_;
                    return any { $path =~ $_ } @prunes;
                },
            }
        )->list_all_htmls;
    }

    1;

In lib/Shlomif/Spelling/Whitelist.pm :

    package Shlomif::Spelling::Whitelist;

    use strict;
    use warnings;

    use MooX qw/late/;

    extends('HTML::Spelling::Site::Whitelist');

    has '+filename' => (default => 'lib/hunspell/whitelist1.txt');

    1;

In lib/Shlomif/Spelling/Check.pm :

    package Shlomif::Spelling::Check;

    use strict;
    use warnings;
    use autodie;
    use utf8;

    use MooX qw/late/;

    use Text::Hunspell;
    use Shlomif::Spelling::Whitelist;
    use HTML::Spelling::Site::Checker;

    sub spell_check
    {
        my ($self, $args) = @_;

        my $speller = Text::Hunspell->new(
            '/usr/share/hunspell/en_GB.aff',
            '/usr/share/hunspell/en_GB.dic',
        );

        if (not $speller)
        {
            die "Could not initialize speller!";
        }

        my $files = $args->{files};

        return HTML::Spelling::Site::Checker->new(
            {
                timestamp_cache_fn => './Tests/data/cache/spelling-timestamp.json',
                whitelist_parser => scalar( Shlomif::Spelling::Whitelist->new() ),
                check_word_cb => sub {
                    my ($word) = @_;
                    return $speller->check($word);
                },
            }
        )->spell_check(
            {
                files => $args->{files}
            }
        );
    }

    1;

In lib/Shlomif/Spelling/Iface.pm :

    package Shlomif::Spelling::Iface;

    use strict;
    use warnings;

    use MooX (qw( late ));

    use Shlomif::Spelling::Check;
    use Shlomif::Spelling::FindFiles;

    sub run
    {
        return Shlomif::Spelling::Check->new()->spell_check(
            {
                files => Shlomif::Spelling::FindFiles->new->list_htmls(),
            },
        );
    }

    1;

In bin/spell-checker-iface :

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use lib './lib';

    use Shlomif::Spelling::Iface;

    Shlomif::Spelling::Iface->new->run;

In t/html-spell-check.t :

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::More tests => 1;

    {
        my $output = `./bin/spell-checker-iface 2>&1`;
        chomp($output);

        # TEST
        is ($output, '', "No spelling errors.");
    }

=head1 DESCRIPTION

The instances of this class can be used to do the actual scanning of
local HTML files.

=head1 METHODS

=head2 my $obj = HTML::Spelling::Site::Checker->new({ whitelist_parser => $parser_obj, check_word_cb => sub { ... }, timestamp_cache_fn => '/path/to/timestamp-cache.json' })

Initialises a new object. C<whitelist_parser> is normally an instance of
L<HTML::Spelling::Site::Whitelist>. C<check_word_cb> is a subroutine to check
a word for correctness. C<timestamp_cache_fn> points to the path where the
cache of the last-checked timestamps of the files is stored in JSON format.

=head2 $finder->spell_check();

Performs the spell check and prints the erroneous words to stdout.

=head2 $bool = $finder->should_check({word=>$word_string})

Whether the word should be checked for being misspelled or not. Can be
overridden in subclasses. (Was added in version 0.4.0).

=head2 $finder->test_spelling({ files => [@files], blurb => $blurb, });

A spell check function compatible with L<Test::More> . Emits one assertion.

Since version 0.2.0, if a C<<< light => 1 >>> key is specified and is true, it
will not use L<Test::Differences>, which tends to consume a lot of RAM when
there are many messages.

Since version 0.10.0, C<'MAXLEN'> argument was added.

Since version 0.10.0, C<'MAXSIZE'> argument was added.

=head2 $finder->whitelist_parser()

For internal use.

=head2 $finder->check_word_cb()

For internal use.

=head2 $finder->timestamp_cache_fn()

For internal use.

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
