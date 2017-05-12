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
    en => [ Properties => catdir($FindBin::Bin, 'basic.properties') ],
};

package main;

ok my $lh = Hello::I18N->get_handle('en');
is $lh->maketext('foo'), 'bar';
is $lh->maketext('123'), '456';

eval { $lh->maketext('not_exists') };
ok $@, 'Specify not exists key';

eval { $lh->maketext('ほげ') };
ok $@, 'Specify multi byte character as key';

is $lh->maketext('bar'), "moznion\nstudio3104";

done_testing;
