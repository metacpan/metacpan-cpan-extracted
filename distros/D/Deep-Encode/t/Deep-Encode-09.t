#!/usr/bin/perl
# vim: ft=perl ts=4 shiftwidth=4 softtabstop=4 expandtab
# space2tab: ok
#===============================================================================
#
#         FILE:  Deep-Encode-09.t
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Anatoliy Grishaev (), grian@cpan.org
#      CREATED:  03/28/2016 01:55:24 PM
#  DESCRIPTION:  ---
#
#===============================================================================
use strict;
use warnings;

require Test::More;                      # last test to print
my $cgi_present = eval { require CGI; 1; };

if ($cgi_present){
    Test::More->import('no_plan');
    require Deep::Encode;
    Deep::Encode->import('deep_from_to', 'deepc_from_to');
    my $q = CGI->new('a=1&gg=hi');
    my $rr = { a => 1, gg => 'hi' };
    my $r1 = $q->Vars;

    my $r2 =CGI->new('a=1&gg=hi')->Vars;
    is_deeply(deepc_from_to($r1, 'cp1251', 'utf8'), $rr, "deepc_copy hv1");
    deep_from_to($r2, 'cp1251', 'utf8');
    is_deeply($r2, $rr, "deep_copy hv1");

    my $r3 = CGI->new('A=%C0')->Vars;
    my $r4 = CGI->new('A=%C0')->Vars;
    my $r30 = CGI->new('A=%D0%90')->Vars;
    deep_from_to($r4, 'cp1251', 'utf8');
    is_deeply(deepc_from_to($r3, 'cp1251', 'utf8'), $r30, "deepc_copy hv2");
    is_deeply($r4, $r30, "deepc_copy hv2");
    ok('ok', 'tied hash');
}
else {
    Test::More->import('skip_all', 'CGI is missing');
}






