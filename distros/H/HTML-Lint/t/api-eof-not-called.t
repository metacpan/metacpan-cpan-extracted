#!perl

use warnings;
use strict;

use Test::More tests => 3;

use HTML::Lint;
use HTML::Lint::HTML4;


my $lint = HTML::Lint->new;
isa_ok( $lint, 'HTML::Lint', 'Created lint object' );

$lint->newfile( '<DATA>' );
$lint->parse( '<p>Blah blah</p>' );
my @errors = $lint->errors();
cmp_ok( scalar @errors, '>', 0, 'Should get back at least one error' );

my $error = $errors[-1];
is( $error->errcode, 'api-eof-not-called', 'The last error in the list is the API error' );
