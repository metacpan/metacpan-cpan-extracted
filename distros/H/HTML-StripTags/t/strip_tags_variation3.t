# Test strip_tags() function : usage variations - unexpected values for both 'str' and 'allowable_tags'
# * testing functionality of strip_tags() by giving unexpected values for $str and $allowable_tags arguments

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 24;

#------------------------- Test Cases ------------------------------------------
# get an unset variable
my $unset_var = undef;

# get a set variable
my $set_var = "test";

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

};

my $results = {
     1 => "0",
     2 => "1",
     3 => "12345",
     4 => "-2345",
     5 => "10.5",
     6 => "-10.5",
     7 => "101234567000",
     8 => "1.07654321e-09",
     9 => "0.5",
    15 => '',
    16 => '',
    21 => '',
    22 => '',
    24 => '',
    25 => '',
};

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($tests->{$test_number}, $tests->{$test_number}), $results->{$test_number}, "No. ".$test_number);
}



# get a file handle
open(my $fh, '<', __FILE__);

$tests = {
    # array data
    10 => [],
    11 => [0],
    12 => [1],
    13 => [1, 2],
    14 => {'color' => 'red', 'item' => 'pen'},
    # Perl references
    '14.1' => \[1, 2],
    '14.2' => \{'color' => 'red', 'item' => 'pen'},
    '14.3' => \$set_var,

    # object data
    23 => classA->new(),

    # file handler
    26 => $fh,
};

$results = {
    10 => qr/strip_tags\(\) expects parameter 1 to be string, ARRAY given/,
    11 => qr/strip_tags\(\) expects parameter 1 to be string, ARRAY given/,
    12 => qr/strip_tags\(\) expects parameter 1 to be string, ARRAY given/,
    13 => qr/strip_tags\(\) expects parameter 1 to be string, ARRAY given/,
    14 => qr/strip_tags\(\) expects parameter 1 to be string, HASH given/,
    '14.1' => qr/strip_tags\(\) expects parameter 1 to be string, REF given/,
    '14.2' => qr/strip_tags\(\) expects parameter 1 to be string, REF given/,
    '14.3' => qr/strip_tags\(\) expects parameter 1 to be string, SCALAR given/,
    23 => qr/strip_tags\(\) expects parameter 1 to be string, classA given/,
    26 => qr/strip_tags\(\) expects parameter 1 to be string, GLOB given/,
};
foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    eval {
        my $string = strip_tags($tests->{$test_number}, $tests->{$test_number});
    };
    like( $@, $results->{$test_number}, "Non-string ".$test_number );
}

close ($fh);