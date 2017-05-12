#!/usr/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 4; };


eval "no warnings; require 5.8.0;";
ok(! $@) or print "Bail out! Perl 5.8 is needed for unicode support.\n";

eval "use Encode;";
ok(! $@) or print "Bail out! Perl 5.8 comes with 'Encode' - why cant I find it?\n";

eval "use Memoize;";
ok(! $@) or print "Bail out! You should really install 'Memoize' - eat your dog food...\n";

eval "use I18N::LangTags;";
ok(! $@) or print "Bail out! I18N::LangTags is a dependancy - why cant I find it?\n";

