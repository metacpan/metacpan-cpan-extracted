#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use DBI;
use File::Temp qw(tempfile);
use Test::Memcached;
use Cache::Memcached::Fast;

(undef, my $db_file) = tempfile();
my $dbh = DBI->connect('dbi:SQLite:dbname=' . $db_file, '', '');

my $memd = Test::Memcached->new;

$memd->start if defined $memd;

{
    package Test::Maketext;

    use Moose;

    BEGIN { extends 'Locale::Maketext::Lexicon::DB'; }

    has '+dbh' => (
        builder => '_build_dbh',
    );

    sub _build_dbh {
        my $self = shift;

        return $dbh;
    }

    has '+lex' => (
        default => 'test',
    );

    has '+auto' => (
        default => 1,
    );

    has '+language_mappings' => (
        default => sub {
            {
                en_gb   => [qw(en_gb en)],
                en_us   => [qw(en_us en)],
                en      => [qw(en)],
            }
        },
    );

    if (defined $memd) {
        has '+cache' => (
            builder => '_build_cache',
        );

        sub _build_cache {
            my $self = shift;

            return Cache::Memcached::Fast->new({
                servers => ['127.0.0.1:' . $memd->option('tcp_port')],
            });
        }

        has '+cache_expiry_seconds' => (
            default => 3_600,
        );
    }
}

$dbh->do(q{
    CREATE TABLE lexicon (
        id INTEGER PRIMARY KEY NOT NULL,
        lang VARCHAR NOT NULL,
        lex VARCHAR NOT NULL,
        lex_key TEXT NOT NULL,
        lex_value TEXT NOT NULL
    )
});

my $lex_insert_sth = $dbh->prepare(q{
    INSERT INTO lexicon(lex, lang, lex_key, lex_value)
    VALUES (?, ?, ?, ?)
});

$lex_insert_sth->execute('test', 'en', 'foo', 'foo');
$lex_insert_sth->execute('test', 'en_gb', 'foo', 'foo gb');
$lex_insert_sth->execute('test', 'en_gb', 'bar', 'bar [_1]'),

# test en_gb handle
ok(my $handle = Test::Maketext->get_handle('en_gb'), 'get_handle');

is(
    $handle->maketext('foo') => 'foo gb',
    'maketext',
);

is(
    $handle->maketext('bar', 2) => 'bar 2',
    'maketext with value',
);

# test en_us handle - fallback
ok(my $handle_2 = Test::Maketext->get_handle('en_us'), 'get_handle');

is(
    $handle_2->maketext('foo') => 'foo',
    'maketext',
);

SKIP: {
    skip 'Skipping cached tests as memcached not available', 3 unless defined $memd;
    # change value - test cache
    $dbh->do(
        q{
            UPDATE lexicon
            SET lex_value = ?
            WHERE lang = ?
            AND lex = ?
            AND lex_key = ?
        },
        undef,
        'foo changed',
        'en_gb',
        'test',
        'foo',
    );

    is(
        $handle->maketext('foo') => 'foo gb',
        'cached value is the same',
    );

    ok(Test::Maketext->clear_cache, 'clear cache');

    is(
        $handle->maketext('foo') => 'foo changed',
        'cache is reloaded',
    );

    $memd->stop;
}

done_testing();
