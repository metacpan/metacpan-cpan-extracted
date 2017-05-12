#!perl

use strict;
use warnings;
use utf8;
use Test::More;

package Hello::I18N;

use File::Spec::Functions qw/catdir/;
use FindBin;
use parent 'Locale::Maketext';
use Locale::Maketext::Lexicon {
    ja => [ Properties => catdir($FindBin::Bin, 'multi_byte.properties') ],
    _decode => 1,
};

package main;

ok my $lh = Hello::I18N->get_handle('ja');
is $lh->maketext('ほげ'), 'ふが';
is $lh->maketext('ぴよ'), 'hogera';

done_testing;
