# -*- perl -*-

# Basic attribute creation, modification, and retrieval tests

package Foo;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self;
}

sub bar {
    my ($foo, $bar) = @_;
    if (defined($bar)) { $foo->{bar} = $bar } else { $foo->{bar} }
}

package main;

use strict;
use warnings;
use Test;

BEGIN { $| = 1; plan tests => 55 }

use Games::Object;
use Games::Object::Manager;

# Define a subroutine to check to see if a value is within a very small
# range of a target. This is needed for some Perl 5.8 floating point
# precision problems.
sub in_range {
    my ($num, $target, $range) = @_;
    my $diff = abs($num - $target);
    $diff <= $range;
}

# Create object to use.
my $man = Games::Object::Manager->new();
my $obj = Games::Object->new();
ok( defined($obj) && defined($man->add($obj)) );

# Integers
eval('$obj->new_attr(
	-name	=> "AnInteger",
	-type	=> "int",
	-value	=> 10,
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr('AnInteger') == 10 );
eval('$obj->mod_attr(
	-name	=> "AnInteger",
	-value	=> 12,
)');
ok ( $obj->attr('AnInteger') == 12 );
eval('$obj->mod_attr(
	-name	=> "AnInteger",
	-modify	=> -4,
)');
ok ( $obj->attr('AnInteger') == 8 );

# Fractional-handling with integers
eval('$obj->new_attr(
	-name	=> "AnIntegerFractional",
	-type	=> "int",
	-value	=> 10.56,
	-track_fractional => 1,
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr('AnIntegerFractional') == 10 );
ok ( in_range($obj->raw_attr('AnIntegerFractional'), 10.56, 0.0001) );
ok ( $obj->attr('AnInteger') == 8 );
eval('$obj->mod_attr(
	-name	=> "AnIntegerFractional",
	-modify	=> 0.43,
)');
ok ( $obj->attr('AnIntegerFractional') == 10 );
ok ( in_range($obj->raw_attr('AnIntegerFractional'), 10.99, 0.0001) );
eval('$obj->mod_attr(
	-name	=> "AnIntegerFractional",
	-modify	=> 0.02,
)');
ok ( $obj->attr('AnIntegerFractional') == 11 );
ok ( in_range($obj->raw_attr('AnIntegerFractional'), 11.01, 0.0001) );
eval('$obj->new_attr(
	-name	=> "AnIntegerFractional2",
	-type	=> "int",
	-value	=> 10.56,
	-track_fractional => 1,
	-on_fractional => "ceil",
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr('AnIntegerFractional2') == 11 );
ok ( in_range($obj->raw_attr('AnIntegerFractional2'), 10.56, 0.0001) );
eval('$obj->mod_attr(
	-name	=> "AnIntegerFractional2",
	-modify	=> -0.07,
)');
ok ( $obj->attr('AnIntegerFractional2') == 11 );
ok ( in_range($obj->raw_attr('AnIntegerFractional2'), 10.49, 0.0001) );

# Numbers
eval('$obj->new_attr(
	-name	=> "ANumber",
	-type	=> "number",
	-value	=> 25.67,
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr("ANumber") == 25.67 );

# Strings
eval('$obj->new_attr(
	-name	=> "AString",
	-type	=> "string",
	-value	=> "How now brown cow?",
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr('AString') eq 'How now brown cow?' );

# Picklists
eval('$obj->new_attr(
	-name	=> "APicklist",
	-type	=> "string",
	-value	=> "the_other",
	-values  => [ "this", "that", "the_other", "something_or_other" ],
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr('APicklist') eq 'the_other' );

# Picklists with mapping
eval('$obj->new_attr(
	-name	=> "APicklistWithMapping",
	-type	=> "string",
	-value	=> "that",
	-values  => [ "this", "that", "the_other", "something_or_other" ],
	-map	=> {
	    this	=> "This one right here.",
	    that	=> "That one over there.",
	    the_other	=> "The other one way over there.",
	},
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr('APicklistWithMapping') eq 'That one over there.' );
ok ( $obj->raw_attr('APicklistWithMapping') eq 'that' );

# Split-value numbers
eval('$obj->new_attr(
	-name	=> "ASplitNumber",
	-type	=> "number",
	-value	=> 25.67,
	-tend_to_rate	=> 1,
	-real_value => 100.0,
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr("ASplitNumber") == 25.67 );
ok ( $obj->attr("ASplitNumber", "real_value") == 100.0 );
$obj->process();
ok ( $obj->attr("ASplitNumber") == 26.67 );

# Numbers with limits
eval('$obj->new_attr(
	-name	=> "ALimitedNumber",
	-type	=> "number",
	-value	=> 25.67,
	-minimum	=> 0,
	-maximum	=> 100,
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr("ALimitedNumber") == 25.67 );
eval('$obj->mod_attr(
	-name	=> "ALimitedNumber",
	-modify	=> -0.07,
)');
ok ( $obj->attr("ALimitedNumber") == 25.6 );
print "# $@" if ($@);
eval('$obj->mod_attr(
	-name	=> "ALimitedNumber",
	-modify	=> -30,
)');
ok ( $obj->attr("ALimitedNumber") == 0 );
print "# $@" if ($@);
eval('$obj->mod_attr(
	-name	=> "ALimitedNumber",
	-modify	=> 45.4,
)');
ok ( $obj->attr("ALimitedNumber") == 45.4 );
print "# $@" if ($@);
eval('$obj->mod_attr(
	-name	=> "ALimitedNumber",
	-modify	=> 75,
)');
ok ( $obj->attr("ALimitedNumber") == 100 );
print "# $@" if ($@);
eval('$obj->new_attr(
	-name	=> "AnotherLimitedNumber",
	-type	=> "number",
	-value	=> 25.67,
	-minimum	=> 0,
	-maximum	=> 100,
	-out_of_bounds => "ignore",
)');
ok ( $@ eq '' );
print "# $@" if ($@);
ok ( $obj->attr("AnotherLimitedNumber") == 25.67 );
eval('$obj->mod_attr(
	-name	=> "AnotherLimitedNumber",
	-modify	=> 75,
)');
ok ( $obj->attr("AnotherLimitedNumber") == 25.67 );
print "# $@" if ($@);
eval('$obj->mod_attr(
	-name	=> "AnotherLimitedNumber",
	-modify	=> -75,
)');
ok ( $obj->attr("AnotherLimitedNumber") == 25.67 );
print "# $@" if ($@);

# Object references (a very basic test only; more extensive testing can be found
# in other test scripts; this just tests storage, retrieval, and basic error
# handling)
my $robj1 = Foo->new(); $robj1->bar("SampleObject1");
my $robj2 = Foo->new(); $robj2->bar("SampleObject2");
my $res;
eval('$obj->new_attr(
	-name	=> "ObjectRef1",
	-type	=> "object",
	-value	=> $robj1,
)');
ok( $@ eq '' );
print "# $@" if ($@);
$res = $obj->attr("ObjectRef1");
ok( defined($res) && ref($res) eq 'Foo' && $res->bar() eq 'SampleObject1' );
eval('$obj->mod_attr(
	-name	=> "ObjectRef1",
	-value	=> $robj2,
)');
$res = $obj->attr("ObjectRef1");
ok( defined($res) && ref($res) eq 'Foo' && $res->bar() eq 'SampleObject2' );

# Perform some basic attribute existence tests.
ok( !defined($obj->attr("ThisDoesNotExist")) );
ok( !$obj->attr_exists("ThisDoesNotExist") );
ok( $obj->attr_exists("ObjectRef1") );

# Final test: accessors. Turn on accessors feature and create some more
# attributes.
$Games::Object::AccessorMethod = 1;
eval('$obj->new_attr(
	-name	=> "Accessorized1",
	-type	=> "int",
	-value	=> 42,
);');
ok( $@ eq '' );
print "# $@" if ($@);
eval('$obj->new_attr(
	-name	=> "Accessorized2",
	-type	=> "int",
	-value	=> 8674309,
);');
ok( $@ eq '' );
print "# $@" if ($@);

# Try to access their values via the accessor methods.
my $value;
eval('$value = $obj->Accessorized1();');
ok( $@ eq '' && $value == 42 );
print "# $@" if ($@);
eval('$value = $obj->Accessorized2();');
ok( $@ eq '' && $value == 8674309 );
print "# $@" if ($@);

# Try to use these to set the values.
eval('$obj->Accessorized1(1001);');
ok( $@ eq '' );
print "# $@" if ($@);
eval('$obj->Accessorized2(999);');
ok( $@ eq '' );
print "# $@" if ($@);

# And check that they got set.
eval('$value = $obj->Accessorized1();');
ok( $@ eq '' && $value == 1001 );
print "# $@" if ($@);
eval('$value = $obj->Accessorized2();');
ok( $@ eq '' && $value == 999 );
print "# $@" if ($@);

exit (0);
