#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( t/lib );

use_ok('My::CPANAuthors' );

ok(
  my $iter = My::CPANAuthors->new(),
  "Got object"
);
isa_ok(
  $iter, 'My::CPANAuthors'
);

# Expect to see 'AADLER' -> 'ZZCGUMK':
my %saw = ( );
my %saw_page = ( );
while( my $item = $iter->next )
{
  $saw_page{ $iter->page_number } = 1;
  $saw{ lc($item->{id}) }++;
}# end while()

for( 'A'..'Z' )
{
  ok( $saw_page{$_}, "Saw page '$_'" );
}# end for()
ok( $saw{'aadler'}, "Saw aadler" );
ok( $saw{'zzcgumk'}, "Saw zzcgumk" );


