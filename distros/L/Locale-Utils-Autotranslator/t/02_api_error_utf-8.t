#!perl
#!perl -T

use strict;
use warnings;
use utf8;

use Carp qw(confess);
use Moo;
use Test::More tests => 3;
use Test::NoWarnings;

extends qw(
    Locale::Utils::Autotranslator
);

sub translate_text {
    confess 'test error';
}

my $output_filename = './translated de_utf-8.po';
my $obj = __PACKAGE__
    ->new(
        language => 'de',
    )
    ->translate(
        't/LocaleData/untranslated de_utf-8.po',
        $output_filename,
    );
is
    $obj->translation_count,
    0,
    'translation count';
like
    $obj->error,
    qr{ \A \Qtest error\E \b }xms,
    'error';
unlink $output_filename;
