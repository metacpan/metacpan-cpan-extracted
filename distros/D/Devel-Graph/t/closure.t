#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 4;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Devel::Graph") or die($@);
   };

#############################################################################
# croak on errors

my $grapher = Devel::Graph->new();

is (ref($grapher), 'Devel::Graph');
my $if_code = <<'IF_CODE';
my $a = 1;
if($a){
    my $var = 1;
    my $other_var = 2;
    my $var_now = $var + $other_var;
    print "$var_now\n";
}
IF_CODE

eval "\$grapher->decompose( \\\$if_code )";
is ($@, '', 'if error');

my $closure_code = <<'CLOSURE_CODE';
{
    my $var = 1;
    my $other_var = 2;
    my $var_now = $var + $other_var;
    print "$var_now\n";
}
CLOSURE_CODE

eval "\$grapher->decompose( \\\$closure_code )";
is ($@, '', 'closure error');


