#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use Data::Dumper;
use Getopt::Valid;

#
# VALIDATION DEFINITION
#

my $validation_ref = {
    
    # name of the program
    name   => 'Name of the script/program', # overrules $0
    
    # version info
    version => '1.0.1', # overrules $main::VERSION
    
    # the struct of the params
    struct => [
        
        # extended example
        'somestring|s=s' => {
            description => 'The description of somestring',
            constraint  => sub { my ( $val ) = @_; return index( $val, '123' ) > -1 }, # all strings containing 123
            required    => 1,
        },
        
        # Example using only validator and fallback to default description.
        # This value is optional (mind: no "!")
        'otherstring|o=s' => qr/^([a-z]+)$/, # all lowercase words
        
        # Example of using integer key with customized description.
        # This value is optional (mind the "!")
        'someint|i=i!' => 'The description of someint',
        
        # Bool value using the default description
        'somebool|b' => undef
    ]
};

#
# FUNCTIONAL USAGE
#

my $validated_args_ref = GetOptionsValid( $validation_ref ) || die "Failed to validate input\n". join( "\n", @Getopt::Valid::ERRORS, "\n", $Getopt::Valid::USAGE );

print "Got $validated_args_ref->{ somestring }\n";

