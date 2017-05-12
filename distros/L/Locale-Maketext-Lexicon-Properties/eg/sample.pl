#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

package Hello::I18N;
use parent 'Locale::Maketext';
use Locale::Maketext::Lexicon {
    en => [ Properties => "$FindBin::Bin/sample.properties" ],
};

package main;
my $lh = Hello::I18N->get_handle('en');
print $lh->maketext('foo');
