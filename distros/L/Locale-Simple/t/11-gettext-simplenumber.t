#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

use Locale::gettext_dumb qw(:locale_h :libintl_h);

is(ngettext("You have a message","You have some messages",1),'You have a message',"simple plural test with single without %d");
is(ngettext("You have a message","You have some messages",4),'You have some messages',"simple plural test with plural without %d");

done_testing;
