#!/usr/bin/perl -w
#
#
#
use strict;
use warnings;

use Test::More tests => 1;
use Test::NoWarnings;
#my $tests;
#
#my @files;
#my @default_subs;
#
BEGIN {
    #if (opendir my $dh, "lib/Kephra/Config/Default/") {
        #@files = grep {$_ ne '.' and $_ ne '..'} readdir $dh;
    #}
#
    #@default_subs = qw(
        #global_settings
        #commandlist
        #localisation
        #mainmenu
        #contextmenus
        #toolbars
    #);
}
#
# TODO: Kephra::Config::Default::drop_xp_style_file
#
#plan tests =>  1 + $tests;
#
#BEGIN { $tests += 3 * @files; }
#foreach my $file (@files) {
    #my $module = "Kephra::Config::Default::" . substr $file, 0, -3;
    #require_ok($module);
    #can_ok($module, 'get');
    #my $r = $module->get();
#
    #my $expected_ref = $file eq 'MainMenu.pm' ? 'ARRAY' : 'HASH';
    #is ref($r), $expected_ref, "$file gets a $expected_ref ref";
#}
#
#
#BEGIN { $tests += 1; }
#{
    #require_ok('Kephra::Config::Default');
#}
#
#BEGIN { $tests += @default_subs; }
#foreach my $sub (@default_subs) {
    #my $r = Kephra::Config::Default->$sub;
    #my $expected_ref = $sub eq 'mainmenu' ? 'ARRAY' : 'HASH';
    #is ref($r), $expected_ref, "$sub gets a $expected_ref ref";
#}

exit(0);