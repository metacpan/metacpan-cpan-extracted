#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 5;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Devel::Graph") or die($@);
   };

#############################################################################
# croak on errors

my $grapher = Devel::Graph->new();

is (ref($grapher), 'Devel::Graph');

eval "\$grapher->decompose( '\$a = 9;' )";
like ($@, qr/Got filename '\$a = 9;', but can't read it: No such file or directory/, 'filename');

my $code = '$a = 9;';
eval "\$grapher->decompose( \$code )";
like ($@, qr/Got filename '\$a = 9;', but can't read it: No such file or directory/, 'filename');

$code = '$a = 9;';
eval "\$grapher->decompose( \\\$code )";
is ($@, '', 'no error');


