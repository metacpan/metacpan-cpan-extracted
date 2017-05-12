#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Inline::MonoCS
  method        => "Echo",
  compiler_args => "",
  code          => <<"CODE";
public class Echo
{
    public static void Main( string[] args)
    {
        System.Console.WriteLine( args[0] );
    }
}
CODE

my $rand = rand();
is( Echo( $rand ) => $rand, "Echo('$rand') == '$rand'" );

