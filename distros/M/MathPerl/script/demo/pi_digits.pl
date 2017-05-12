#!/usr/bin/perl

# Pi Digits, Program Source Code, Perl Implementation #2
# Calculate & Display Digits Of The Transcendental Number Pi
# The Open Benchmarks Group
# http://openbenchmarks.org

# Contributed In C By Mr. Ledrug
# Converted To Perl By Will Braswell

# $ ./script/demo/pi_digits.pl 10000
# time total:   FOO
# $ rperl lib/MathPerl/Geometry/PiDigits.pm
# $ ./script/demo/pi_digits.pl 10000
# time total:   FOO

# [[[ HEADER ]]]
use RPerl;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use MathPerl::Geometry::PiDigits;
use Time::HiRes qw(time);
use rperltypesconv;

# [[[ OPERATIONS ]]]

my integer $number_of_digits = 50;  # default
if (defined $ARGV[0]) { $number_of_digits = string_to_integer($ARGV[0]); }  # user input, command-line argument

my number $time_start = time();

MathPerl::Geometry::PiDigits::display_pi_digits($number_of_digits);

my number $time_total = time() - $time_start;
print 'time total:   ' . $time_total . ' seconds' . "\n";
