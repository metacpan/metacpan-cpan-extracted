use strict;
use warnings;
use Test::More;
use lib 't';

my $stub0 = qq("$^X" -Ilib -It -MIncludeAll -d);
my $stub1 = qq("$^X" -Ilib -It -MIncludeAll -d:ModuleBreaker);
my $stub2 = qq("$^X" -Ilib -It -MIncludeAll -d:SubBreaker);
my $stub3 = qq("$^X" -Ilib -It -MIncludeAll -d:FileBreaker);
my ($c, @f);



# no PERL5DB environment variables

delete $ENV{PERL5DB};
delete $ENV{PERL5DBX};


@f = qx($stub0 t/bptracker.pl -f);
ok(@f==0, 'env0: no regular debugger output with t/bptracker.pl') or diag @f;

@f = qx($stub1=Some::Module t/bptracker.pl -f);
ok(@f==2,  'env0: finds module subs in multiple files') or diag @f;

@f = qx($stub2=Some::Module t/bptracker.pl -f);
ok(@f==4,  'env0: finds subs in multiple files') or diag @f;

@f = qx($stub3=t/Some/Module t/bptracker.pl -f);
ok(@f==2,  'env0: expr matches multiple files') or diag @f;



# PERL5DB instructs perl to load custom debugger

$ENV{PERL5DB} = $ENV{PERL5DBX} = 'BEGIN { require "t/perl5dby.pl" }';


$c = qx($stub0 t/bptracker.pl -f);
ok($c =~ /^a+$/, 'env1: t/bptracker.pl only makes DB::DB calls') or diag $c;

$c = qx($stub1=Some::Module t/bptracker.pl -f);
ok($c =~ /^b+a+$/,  
   'env1: ModuleBreaker makes cmd_b_subs calls') or diag $c;

$c = qx($stub2=Some::Module t/bptracker.pl -f);
ok($c =~ /^b+a+$/, 
   'env1: SubBreaks makes cmb_b_subs calls') or diag $c;

$c = qx($stub3=t/Some/Module t/bptracker.pl -f);
ok($c =~ /^b+a+$/, 
   'env1: FileBreaker makes cmd_b_subs calls') or diag $c;



# PERL5DB loads custom DB routines

$ENV{PERL5DB} = $ENV{PERL5DBX} =
    'sub DB::DB { print "c" } sub DB::cmd_b_sub { print "d" }';


$c = qx($stub0 t/bptracker.pl -f);
ok($c =~ /^c+$/, 'env1: t/bptracker.pl only makes DB::DB calls') or diag $c;

$c = qx($stub1=Some::Module t/bptracker.pl -f);
ok($c =~ /^d+c+$/,  
   'env2: ModuleBreaker makes cmd_b_subs calls') or diag $c;

$c = qx($stub2=Some::Module t/bptracker.pl -f);
ok($c =~ /^d+c+$/, 
   'env2: SubBreaks makes cmb_b_subs calls') or diag $c;

$c = qx($stub3=t/Some/Module t/bptracker.pl -f);
ok($c =~ /^d+c+$/, 
   'env2: FileBreaker makes cmd_b_subs calls') or diag $c;

done_testing;

