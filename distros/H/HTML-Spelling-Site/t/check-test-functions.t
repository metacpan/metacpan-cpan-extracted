#!/usr/bin/perl

package Shlomif::Spelling::FindFiles;

use strict;
use warnings;

use MooX            qw/late/;
use List::MoreUtils qw/any/;

use HTML::Spelling::Site::Finder ();

my @prunes = ();

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

package Shlomif::Spelling::Whitelist;

use strict;
use warnings;

use MooX qw/late/;

extends('HTML::Spelling::Site::Whitelist');

has '+filename' =>
    ( default => 't/data/sites/fully-correct-whitelist/whitelist.txt' );

1;

package Shlomif::Spelling::Check;

use strict;
use warnings;
use autodie;
use utf8;

use MooX qw/late/;

use Text::Hunspell                ();
use HTML::Spelling::Site::Checker ();

has 'obj' => (
    is      => 'ro',
    default => sub {
        my ($self) = @_;

        my $speller = Text::Hunspell->new(
            '/usr/share/hunspell/en_GB.aff',
            '/usr/share/hunspell/en_GB.dic',
        );

        if ( not $speller )
        {
            die "Could not initialize speller!";
        }

        return HTML::Spelling::Site::Checker->new(
            {
                timestamp_cache_fn =>
                    't/data/sites/fully-correct-timestamp/cache.json',
                whitelist_parser =>
                    scalar( Shlomif::Spelling::Whitelist->new() ),
                check_word_cb => sub {
                    my ($word) = @_;
                    return $speller->check($word);
                },
            }
        );
    }
);

sub spell_check
{
    my ( $self, $args ) = @_;

    return $self->obj->spell_check(
        {
            files => $args->{files}
        }
    );
}

1;

package Shlomif::Spelling::Iface;

use strict;
use warnings;

use MooX (qw( late ));

has 'files' => (
    is      => 'ro',
    default => sub { return Shlomif::Spelling::FindFiles->new->list_htmls(); }
);
has 'obj' => (
    is      => 'ro',
    default => sub { return Shlomif::Spelling::Check->new(); }
);

sub test
{
    my ( $self, $blurb ) = @_;

    $self->obj->obj->test_spelling(
        { files => $self->files, blurb => $blurb } );
}

package main;

1;

use strict;
use warnings;

use Test::Builder::Tester tests => 1;

{
    # TEST
    test_out('ok 1 - my blurb here');

    my $iface = Shlomif::Spelling::Iface->new;

    $iface->test("my blurb here");

    test_test("test works");
}
