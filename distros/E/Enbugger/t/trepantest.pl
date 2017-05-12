#!/usr/bin/env perl
use File::Basename; use File::Spec;
my $test_var = 'trepan';
my $basename = basename(__FILE__, '.pl');
my $dirname  = dirname(__FILE__);
unshift @INC, File::Spec->catfile($dirname, qw(.. blib lib));

my $trepan_profile = File::Spec->catfile($dirname, $basename . '.cmd');
my $opts = 
{
    testing     => $trepan_profile,
    basename    => 1,
    readline    => 0,
    highlight   => 0
};
push @INC, 't';
require 'reset_perms.pl';
require Enbugger; 
Enbugger->load_debugger('trepan');

sub five 
{
    5;
}

Enbugger->stop($opts);
print five, "\n";

