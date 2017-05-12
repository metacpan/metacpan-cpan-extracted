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
# OBJECT USAGE
#

my $opt = Getopt::Valid->new( $validation_ref );

# collect data
$opt->collect_argv;

# validate ok
if ( $opt->validate ) {
    # acces valid data
    print "Got ". $opt->valid_args->{ somestring }. "\n";
}

# print errors
else {
    print "Oops ". $opt->errors( " ** " ). "\n";
    print $opt->usage();
}
