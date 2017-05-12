# Testing for File::Find::Rule::Perl

use strict;
use warnings;
use lib ();
use File::Spec::Functions ':ALL';

use Test::More tests => 7;
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use constant FFR => 'File::Find::Rule';

# Check the methods are added
foreach my $method ( qw{ perl_file perl_module perl_script perl_test perl_installer } ) {
	ok( FFR->can($method), "->$method exists" );
}

# Make an object containing all of them
my $Rule = File::Find::Rule->new->perl_file;
isa_ok( $Rule, 'File::Find::Rule' );

my $Rule1 = File::Find::Rule->perl_file; #used in perlver
isa_ok( $Rule1, 'File::Find::Rule' );

exit(0);
