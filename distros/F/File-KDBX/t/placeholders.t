#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Entry;
use File::KDBX;
use Test::More;

my $kdbx = File::KDBX->new;

my $entry1 = $kdbx->add_entry(
    title       => 'Foo',
    username    => 'User {TITLE}',
);
my $entry2 = $kdbx->add_entry(
    title       => 'Bar',
    username    => sprintf('{REF:U@I:%s}', $entry1->id),
    notes       => 'notes {URL}',
    url         => 'url {NOTES}',
);
my $entry3 = $kdbx->add_entry(
    username    => sprintf('{REF:U@I:%s}', $entry2->id),
    password    => 'lyric:%LYRIC%',
    notes       => '%MISSING% %% %NOT AVAR% %LYRIC%',
);

is $entry1->expand_username, 'User Foo', 'Basic placeholder expansion';
is $entry2->expand_username, 'User Foo', 'Reference to another entry';
is $entry3->expand_username, 'User Foo', 'Reference to another entry through another';

my $recursive_expected = 'url notes ' x 10 . 'url {NOTES}';
my $recursive;
my $warning = warning { $recursive = $entry2->expand_url };
like $warning, qr/detected deep recursion/i, 'Deep recursion causes a warning'
    or diag 'Warnings: ', explain $warning;
is $recursive, $recursive_expected, 'Recursive placeholders resolve to... something';

{
    my $entry = File::KDBX::Entry->new(url => 'http://example.com?{EXPLODE}');
    is $entry->expand_url, 'http://example.com?{EXPLODE}',
        'Unhandled placeholders are not replaced';

    local $File::KDBX::PLACEHOLDERS{EXPLODE} = sub { 'boom' };
    is $entry->expand_url, 'http://example.com?boom', 'Custom placeholders can be set';

    $entry->url('{eXplOde}!!');
    is $entry->expand_url, 'boom!!', 'Placeholder tags are match case-insensitively';
}

{
    local $ENV{LYRIC} = 'I am the very model of a modern Major-General';
    is $entry3->expand_password, "lyric:$ENV{LYRIC}", 'Environment variable placeholders';
    is $entry3->expand_notes, qq{%MISSING% %% %NOT AVAR% $ENV{LYRIC}},
        'Do not replace things that look like environment variables but are not';
}

{
    my $counter = 0;
    local $File::KDBX::PLACEHOLDERS{'COUNTER'} = $File::KDBX::PLACEHOLDERS{'COUNTER:'} = sub {
        (undef, my $arg) = @_;
        return defined $arg ? $arg : ++$counter;
    };
    my $entry4 = $kdbx->add_entry(
        url => '{COUNTER} {USERNAME}',
        username => '{COUNTER}x{COUNTER}y{COUNTER:-1}',
    );
    like $entry4->expand_username, qr/^1x1y-1$/,
        'Each unique placeholder is evaluated once';
    like $entry4->expand_url, qr/^2 3x3y-1$/,
        'Each unique placeholder is evaluated once per string';
}

done_testing;
