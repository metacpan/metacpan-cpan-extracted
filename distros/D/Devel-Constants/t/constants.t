#!perl -w

BEGIN { chdir 't' if -d 't' }

use strict;
use Test::More tests => 19;

BEGIN { use_ok( 'Devel::Constants',  'flag_to_names' ) }

use constant ONE	=> 1;
use constant TWO	=> 2;
use constant THREE	=> 4;
use constant FOUR	=> 8;
use constant FIVE	=> 16;

my $val = ONE | TWO | THREE;

my $flagstring = flag_to_names($val);
for (qw( ONE TWO THREE )) {
	ok( $flagstring =~ s/\s?$_\s?//, "$_ flag should be set in string" );
}

my @flaglist = flag_to_names($val);
for my $flag (qw( ONE TWO THREE )) {
	ok( (grep { $_ eq $flag } @flaglist), "$flag flag should be set in list" );
}

is( Devel::Constants::to_name(8), 'FOUR', 'should be able to resolve label ');

my %flags;

# must be done at compile time
Devel::Constants->import(\%flags);

constant->import( A => 1 );
constant->import( B => 2 );
constant->import( C => 3 );

for my $flag (qw( A B C )) {
	my $sub = main->can( $flag);
	ok( $flags{$sub->()}, "$flag exists in passed-in hash");
	is( $flags{$sub->()}, $flag, "$flag has correct value too!" );
}

# now check to see if the custom exporter works
Devel::Constants->import( import => 'bar', to_name => 'label', 'flag_to_names');
diag( 'should import into requested namespace' );
can_ok( 'bar', 'flag_to_names');
can_ok( 'bar', 'label');
diag( 'should export requested name' );

# tell it to capture variables for constants in another package
Devel::Constants->import( package => 'foo', \%foo::fflags);

package foo;

use vars '%fflags';

# must be done at compile time
constant->import( NAME	=> 1 );
constant->import( VALUE	=> 2 );

::is( keys %fflags, 2,     'should capture values in another package' );
::is( $fflags{2}, 'VALUE', '... setting captured value in other package' );

package main;

is( flag_to_names(1, 'foo'), 'NAME', 'should get names for other package' );
