use strict;
use warnings;
use Test::More;
use FFI;
use FFI::Library;

# Load the C and Math libraries
use lib "./t";
use Support;

our $libc;
our $libm;

# Function addresses
my $atoi = address($libc, "atoi");
my $strlen = address($libc, "strlen");
my $pow = address($libm, "pow");

is FFI::call($atoi, 'cip', "12"),         12, 'atoi(12)';
is FFI::call($atoi, 'cip', "-97"),       -97, 'atoi(-97)';
is FFI::call($pow, 'cddd', 2, 0.5),   2**0.5, 'pow(2,0.5)';
is FFI::call($strlen, 'cIp', "Perl"),      4, 'strlen("Perl")';

done_testing;
