#!perl
#!perl -T

use strict;
use warnings;
use utf8;

use Moo;
use Test::More tests => 6;
use Test::NoWarnings;

extends qw(
    Locale::Utils::Autotranslator
);
my $output_filename = './translated de_utf-8.po';
my $obj = __PACKAGE__
    ->new(
        language   => 'de',
        after_translation_code => sub {
            my ( $self, $msgid, $msgstr ) = @_;
            ok
                $self->can('translate_text'),
                'the object itself';
            is
                $msgid,
                'Number of XXXDBXZ: XXXDCXZ',
                'msgid';
            is
                $msgstr,
                q{},
                'msgid';
            0;
        },
    );
is
    $obj
        ->translate(
            't/LocaleData/untranslated de_utf-8.po',
            $output_filename,
        )
        ->translation_count,
    1,
    'translation count';
is
    $obj->error,
    undef,
    'no error';
unlink $output_filename;
