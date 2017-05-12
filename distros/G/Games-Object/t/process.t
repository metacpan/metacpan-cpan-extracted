# -*- perl -*-

# Processing

# Note that while this has some event processing in it, it is not a full
# test of events. The events are mainly to check priority processing.

package GOTM;

use strict;
use warnings;
use Exporter;
use Games::Object;
use vars qw(@ISA @EXPORT);

@ISA = qw(Games::Object Exporter);
@EXPORT = qw(@RESULTS);

use vars qw(@RESULTS);

@RESULTS = ();

sub initialize { @RESULTS = (); }

sub new
{
	my $class = shift;
	my $obj = $class->SUPER::new(@_);
	bless $obj, $class;
	$obj;
}

sub attr_modified {
    my ($obj, $action, $old, $new, @uargs) = @_;
    push @RESULTS, [ $obj->id(), 'attr_modified', $action, $old, $new, @uargs ];
    1;
}

sub attr_oob {
    my ($obj, $action, $old, $new, @uargs) = @_;
    push @RESULTS, [ $obj->id(), 'mod_oob', $action, $old, $new, @uargs ];
    1;
}

sub do_this {
    my $obj = shift;
    push @RESULTS, [ $obj->id(), @_ ];
}

1;

package main;

use strict;
use warnings;
use Test;
use Games::Object::Manager;
use Games::Object;
use IO::File;

BEGIN { $| = 1; plan tests => 50 }

# Create an object from the subclassed test module.
my $man = Games::Object::Manager->new();
my $obj = GOTM->new();
$man->add($obj);
ok( defined($obj) && $obj->isa('Games::Object') );

# Define an attribute.
eval('$obj->new_attr(
    -name	=> "SomeNumber",
    -type	=> "number",
    -value	=> 50,
    -real_value	=> 100,
    -minimum	=> 0,
    -maximum	=> 100,
    -tend_to_rate=> 1,
    -priority	=> 1,
    -on_change	=> [ "O:self", "attr_modified", "A:action", "A:old", "A:new" ],
    -on_minimum	=> [ "O:self", "attr_oob", "A:action", "A:old", "A:new" ],
    -on_maximum	=> [ "O:self", "attr_oob", "A:action", "A:old", "A:new" ],
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);

# Define a second attribute
eval('$obj->new_attr(
    -name	=> "SomeOtherNumber",
    -type	=> "number",
    -value	=> 70,
    -real_value	=> 150,
    -minimum	=> 0,
    -maximum	=> 150,
    -tend_to_rate=> 2,
    -priority	=> 2,
    -on_change	=> [ "O:self", "attr_modified", "A:action", "A:old", "A:new" ],
    -on_minimum	=> [ "O:self", "attr_oob", "A:action", "A:old", "A:new" ],
    -on_maximum	=> [ "O:self", "attr_oob", "A:action", "A:old", "A:new" ],
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);

# Process it. Insure that we see in the event that the attribute was modified.
GOTM->initialize();
$obj->process();
ok( $obj->attr('SomeNumber') == 51 );
ok( $obj->attr('SomeOtherNumber') == 72 );
ok( @GOTM::RESULTS == 2
 && $GOTM::RESULTS[0][2] eq 'attr:SomeOtherNumber:on_change'
 && $GOTM::RESULTS[1][2] eq 'attr:SomeNumber:on_change' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 2)\n"
  if (@GOTM::RESULTS != 2);

# Add a persisent static modifier to SomeNumber. Do the same for
# SomeOtherNumber, but force it to take effect now.
GOTM->initialize();
eval('$obj->mod_attr(
    -name	=> "SomeNumber",
    -modify	=> 10,
    -persist_as	=> "StaticModifier",
)');
eval('$obj->mod_attr(
    -name	=> "SomeOtherNumber",
    -modify	=> 5,
    -persist_as	=> "StaticModifierDoNow",
    -apply_now	=> 1,
);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj->attr('SomeNumber') == 51 );
ok( $obj->attr('SomeOtherNumber') == 77 );
# And the modification for SomeOtherNumber should already have triggered
# a modify event already.
ok( @GOTM::RESULTS == 1
 && $GOTM::RESULTS[0][2] eq 'attr:SomeOtherNumber:on_change' );
# Clear the events results and process object. For SomeNumber, we should
# see both the tend-to modify and the pmod. For SomeOtherNumber, we should
# see ONLY the former.
GOTM->initialize();
$obj->process();
ok( $obj->attr('SomeNumber') == 62 );
ok( $obj->attr('SomeOtherNumber') == 79 );
ok( @GOTM::RESULTS == 3
# From process_pmod()
 && $GOTM::RESULTS[0][2] eq 'attr:SomeNumber:on_change'
 && $GOTM::RESULTS[0][3] == 51
 && $GOTM::RESULTS[0][4] == 61
# From process_tend_to()
 && $GOTM::RESULTS[1][2] eq 'attr:SomeOtherNumber:on_change'
 && $GOTM::RESULTS[1][3] == 77
 && $GOTM::RESULTS[1][4] == 79
 && $GOTM::RESULTS[2][2] eq 'attr:SomeNumber:on_change'
 && $GOTM::RESULTS[2][3] == 61
 && $GOTM::RESULTS[2][4] == 62 );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 3)\n"
  if (@GOTM::RESULTS != 3);
$obj->process();
ok( $obj->attr('SomeNumber') == 63 );

# Note that from this point on in the test, we do not always check the
# parameters of the SomeOtherNumber mods, since it was added largely to
# test the -apply_now feature, but it is reflected in the total number
# of events.

# Add another persistent modifier, this time to the real value that places it
# below the current value. Process it and see that the tend-to reverses sense.
GOTM->initialize();
eval('$obj->mod_attr(
    -name	=> "SomeNumber",
    -modify_real	=> -80,
    -persist_as	=> "StaticModifierReal",
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj->attr('SomeNumber', 'real_value') == 100 );
$obj->process();
ok( $obj->attr('SomeNumber', 'real_value') == 20
 && $obj->attr('SomeNumber') == 62 );
ok( @GOTM::RESULTS == 2
 && $GOTM::RESULTS[1][2] eq 'attr:SomeNumber:on_change'
 && $GOTM::RESULTS[1][3] == 63
 && $GOTM::RESULTS[1][4] == 62 );

# Now cancel the modifier on the current value. It should change only after
# a process() call, just like the original modifiers.
GOTM->initialize();
eval('$obj->mod_attr(
    -cancel_modify=> "StaticModifier",
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj->attr("SomeNumber") == 62
 && $obj->attr("SomeNumber", 'real_value') == 20 );
$obj->process();
ok( $obj->attr("SomeNumber") == 51
 && $obj->attr("SomeNumber", 'real_value') == 20 );
ok( @GOTM::RESULTS == 3
# process_pmod() results first
 && $GOTM::RESULTS[0][2] eq 'attr:SomeNumber:on_change'
 && $GOTM::RESULTS[0][3] == 62
 && $GOTM::RESULTS[0][4] == 52
# Then the process_tend_to(). SomeOtherNumber updates first (not shown here)
 && $GOTM::RESULTS[2][2] eq 'attr:SomeNumber:on_change'
 && $GOTM::RESULTS[2][3] == 52
 && $GOTM::RESULTS[2][4] == 51 );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 3)\n"
  if (@GOTM::RESULTS != 3);

# Put another modifier on the real value that brings it above the current
# again, but make this one timed. Make sure everything works. Until we come
# to OOB testing, we'll just be checking that the number of events processed
# is correct, since we pretty much exercised the basic event functionality.
GOTM->initialize();
eval('$obj->mod_attr(
    -name	=> "SomeNumber",
    -modify_real=> 50,
    -persist_as	=> "StaticModifierReal2",
    -time	=> 3,
)');
ok( $@ eq '' );
ok( $obj->attr('SomeNumber') == 51
 && $obj->attr('SomeNumber', 'real_value') == 20 );
$obj->process();
ok( $obj->attr('SomeNumber') == 52
 && $obj->attr('SomeNumber', 'real_value') == 70
 && @GOTM::RESULTS == 2 );

# Process two more times. The real value should not change.
GOTM->initialize();
$obj->process();
$obj->process();
ok( $obj->attr('SomeNumber') == 54
 && $obj->attr('SomeNumber', 'real_value') == 70
 && @GOTM::RESULTS == 4 );

# Process one more time. Now the second modifier should be gone.
GOTM->initialize();
$obj->process();
ok( $obj->attr('SomeNumber') == 53
 && $obj->attr('SomeNumber', 'real_value') == 20
 && @GOTM::RESULTS == 2 );

# Now to perform some OOB testing. The default OOB mode should be 'use_up',
# so try to make the current value go over the top.
GOTM->initialize();
eval('$obj->mod_attr(
    -name	=> "SomeNumber",
    -modify	=> 80,
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj->attr('SomeNumber') == 100
 && $obj->raw_attr('SomeNumber') == 100);

# Process the events associated with it.
$obj->process();
ok( $obj->attr('SomeNumber') == 99
 && @GOTM::RESULTS == 4
 && $GOTM::RESULTS[0][2] eq 'attr:SomeNumber:on_change'
 && $GOTM::RESULTS[1][2] eq 'attr:SomeNumber:on_maximum'
 && $GOTM::RESULTS[2][2] eq 'attr:SomeOtherNumber:on_change'
 && $GOTM::RESULTS[3][2] eq 'attr:SomeNumber:on_change' );

# Now change the strategy of OOB to ignore and try again.
GOTM->initialize();
eval('$obj->mod_attr(
    -name	=> "SomeNumber",
    -out_of_bounds => "ignore",
    -modify	=> 80,
)');
ok( $@ eq '' );
ok( @GOTM::RESULTS == 0
 && $obj->attr('SomeNumber') == 99
 && $obj->raw_attr('SomeNumber') == 99);

# The final test is to see if the cancel-by-re functionality works. Create
# an attribute and some modifiers on it.
eval('$obj->new_attr(
    -name	=> "MultiCancelTest",
    -type	=> "int",
    -value	=> 10,
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj->mod_attr(
    -name	=> "MultiCancelTest",
    -modify	=> 1,
    -persist_as	=> "FirstMultiModifier",
)');
ok( $@ eq '');
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj->mod_attr(
    -name	=> "MultiCancelTest",
    -modify	=> 1,
    -persist_as	=> "SecondMultiModifier",
)');
ok( $@ eq '');
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj->mod_attr(
    -name	=> "MultiCancelTest",
    -modify	=> 1,
    -persist_as	=> "SomeOtherModifier",
)');
ok( $@ eq '');
print "# DEBUG: \$@ = $@" if ($@);
$obj->process();
ok( $obj->attr('MultiCancelTest') == 13 );

# Cancel two of them.
eval('$obj->mod_attr(
    -cancel_modify_re	=> "^.+MultiModifier\$",
)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
$obj->process();
ok( $obj->attr('MultiCancelTest') == 11 );

# One more last set of tests: See if we can call an arbitrary method via
# Process().
GOTM->initialize();
my $obj2 = GOTM->new();
my $obj3 = GOTM->new();
$man->add($obj2);
$man->add($obj3);
$obj2->priority($obj->priority() + 2);
$obj3->priority($obj->priority() + 1);
eval('$man->process("do_this", "with_this_arg", "and_that");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 3 );
ok( $GOTM::RESULTS[0][0] eq $obj2->id()
 && $GOTM::RESULTS[0][1] eq "with_this_arg"
 && $GOTM::RESULTS[0][2] eq "and_that" );
ok( $GOTM::RESULTS[1][0] eq $obj3->id()
 && $GOTM::RESULTS[1][1] eq "with_this_arg"
 && $GOTM::RESULTS[1][2] eq "and_that" );
ok( $GOTM::RESULTS[2][0] eq $obj->id()
 && $GOTM::RESULTS[2][1] eq "with_this_arg"
 && $GOTM::RESULTS[2][2] eq "and_that" );

# Now try filtering the process list.
GOTM->initialize();
$obj2->new_attr(
    -name	=> "FilterAttr",
    -type	=> "any",
    -value	=> "Who cares?",
);
eval('$man->process( sub { !shift->attr_exists("FilterAttr") }, "do_this", "with_this_arg", "and_that");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 2 );
ok( $GOTM::RESULTS[0][0] eq $obj3->id()
 && $GOTM::RESULTS[0][1] eq "with_this_arg"
 && $GOTM::RESULTS[0][2] eq "and_that" );
ok( $GOTM::RESULTS[1][0] eq $obj->id()
 && $GOTM::RESULTS[1][1] eq "with_this_arg"
 && $GOTM::RESULTS[1][2] eq "and_that" );

# And finally, try to do a process() for a method that does not exist. This
# should be acceptable, but simply not do anything.
GOTM->initialize();
eval('$man->process("bogus_method", "with_this_arg", "and_that");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 0 );

exit(0);
