#!/usr/bin/perl
#
#   Example script to demonstrate Inline::Wrapper
#
#   $Id: sample.pl 5 2008-12-27 11:25:48Z infidel $
#
#   This is a simple demonstration script.  Please read the documentation for
#   Inline::Wrapper for full details.
#
#   run with no arguments, in the same directory as sample.c.
#   e.g.:
#
#     $ ./sample.pl
#

use strict;
use warnings;
use lib '.';
use Inline::Wrapper;

### MAIN ###

print "Inline::Wrapper Demonstration\n";
print "-----------------------------\n\n";

# Create the wrapper object
my $inline = Inline::Wrapper->new(
    language    => 'C',         # The default language for modules
#    auto_reload =>   0,        # Set to TRUE to auto reload upon file change
    base_dir    => '.',         # Set to the base directory for loading mods
);

# Load the source file
print "I am loading the module: sample\n";
my @symbols = $inline->load( 'sample' );

# Display the available functions
print "I now have the following functions available:\n";
print join( ', ', @symbols ), "\n\n";

# Run the function 'proverb'
print "Running proverb( 'reach', 'overbite' ):\n";
$inline->run(
    'sample',                   # module name
    'proverb',                  # function name
    'reach', 'overbite'         # @argument list
);

# Run the function 'answer' and catch its return values in an array
print "\nRunning answer( 20, 2 ):\n";
my @retvals = $inline->run( 'sample', 'answer', 20, 2 );
printf "returned %d\n", $retvals[0];

# BYE!
print "\nThank you, drive through!\n\n";
exit(0);

__END__
