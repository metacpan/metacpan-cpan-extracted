# Test strip_tags() function : usage variations - unexpected values for 'allowable_tags'
# * testing functionality of strip_tags() by giving unexpected values for $allowable_tags argument

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 24;

#------------------------- Test Cases ------------------------------------------
# Initialise function argument
my $string = "<html><a>hello</a></html><p>world</p><!-- COMMENT --><?php echo hello ?>";

# get an unset variable
my $unset_var = undef;

# get a set variable
my $set_var = "test";

# get a file handle
open(my $fh, '<', __FILE__);

# get a class
package classA;
sub new {
    my ($package, %args) = @_;
    my $self = {};
    bless $self, $package;
    return $self;
}
sub __toString {
    return "Class A object";
}

package main;

my $tests = {
    # int data
     1 => 0,
     2 => 1,
     3 => 12345,
     4 => -2345,

    # float data
     5 => 10.5,
     6 => -10.5,
     7 => 10.1234567e10,
     8 => 10.7654321E-10,
     9 => .5,

    # Perl hash
    14 => {'color' => 'red', 'item' => 'pen'},
    # Perl references
    '14.1' => \[1, 2],
    '14.2' => \{'color' => 'red', 'item' => 'pen'},
    '14.3' => \$set_var,

    # DOES NOT APPLY TO PERL
    # # null data
    # 15 => NULL,
    # 16 => null,
    15 => undef,
    16 => "\0",

    # DOES NOT APPLY TO PERL
    # # boolean data
    # 17 => true,
    # 18 => false,
    # 19 => TRUE,
    # 20 => FALSE,
    
    # empty data
    21 => "",
    22 => '',
    
    # DOES NOT APPLY TO PERL, in the PHP meaning of 'undeclared'
    # undefined data
    # 24 => \$undefined_var,

    # unset data
    25 => $unset_var,

    # file handler
    26 => $fh,
};

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($string, $tests->{$test_number}), "helloworld", "No. ".$test_number);
}


$tests = {
    # array data
    10 => [],
    11 => [0],
    12 => [1],
    13 => [1, 2],
};

my $notices = {
    10 => qr/Array to string conversion/,
    11 => qr/Array to string conversion/,
    12 => qr/Array to string conversion/,
    13 => qr/Array to string conversion/,
};
foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    eval {
        my $result_string = strip_tags($string, $tests->{$test_number});
        is ($string, "helloworld", "No. ".$test_number);
    };
    like( $@, $notices->{$test_number}, "Array ".$test_number );
}

# object data
eval {
    my $result_string = strip_tags(classA->new(), '');
    is ($string, "helloworld", "No. 23");
};
like( $@, qr/strip_tags\(\) expects parameter 1 to be string, classA given/, "Array 23" );

close ($fh);