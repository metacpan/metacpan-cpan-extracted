# -*- perl -*-

# Basic flag creation and modification tests

package GOTM;

# GOTM = Games Object Test Module

use strict;
use warnings;
use Exporter;
use vars qw(@ISA @EXPORT);

use Games::Object;

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

sub set_it
{
	my ($self, $flag) = @_;
	push @RESULTS, [ $self->id(), 'set', $flag ];
	1;
}

sub clear_it
{
	my ($self, $flag) = @_;
	push @RESULTS, [ $self->id(), 'clear', $flag ];
	1;
}

use strict;
use warnings;
use Test;
use Games::Object;

BEGIN { $| = 1; plan test => 29 }

# Create an object
my $obj = GOTM->new(-id => "TestObject");

# Create some flags on it.
eval('$obj->new_flag(-name => "this")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj->new_flag(-name => "that")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj->new_flag(-name => "the_other")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);

# Insure that these flags are NOT set.
ok( !$obj->is('this') );
ok( !$obj->is('that') );
ok( !$obj->is('the_other') );
ok( !$obj->maybe('this', 'that', 'the_other') );

# Set two of the three flags on the object (separately).
eval('$obj->set("this")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj->set("that")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);

# Check that they are set in a number of ways, and that the third is not.
ok( $obj->is('this') );
ok( $obj->is('that') );
ok( !$obj->is('the_other') );
ok( $obj->is('this', 'that') );
ok( !$obj->is('this', 'that', 'the_other') );
ok( $obj->maybe('this', 'that', 'the_other') );

# Clear a flag and see if that worked.
eval('$obj->clear("this")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( !$obj->is('this') );
ok( $obj->is('that') );
ok( !$obj->is('the_other') );

# Try to set multiple flags.
eval('$obj->set( ["this", "the_other"] )');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj->is("this", "that", "the_other") );

# Create one more flag, this one with callbacks.
GOTM->initialize();
eval('$obj->new_flag(
	-name	=> "it",
	-on_set	=> [ "O:self", "set_it", "A:name" ],
	-on_clear => [ "O:self", "clear_it", "A:name" ],
);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 0 );

# Set flag. Should see callback.
GOTM->initialize();
$obj->set("it");
ok( $obj->is("it") );
ok( @GOTM::RESULTS == 1
 && $GOTM::RESULTS[0][0] eq 'TestObject'
 && $GOTM::RESULTS[0][1] eq 'set'
 && $GOTM::RESULTS[0][2] eq 'it' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 1)\n"
  if (@GOTM::RESULTS != 1);

# Clear flag. Should see other callback.
GOTM->initialize();
$obj->clear("it");
ok( !$obj->is("it") );
ok( @GOTM::RESULTS == 1
 && $GOTM::RESULTS[0][0] eq 'TestObject'
 && $GOTM::RESULTS[0][1] eq 'clear'
 && $GOTM::RESULTS[0][2] eq 'it' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 1)\n"
  if (@GOTM::RESULTS != 1);

# Clear flag again. This should NOT invoke the callback, as the flag was
# already cleared.
GOTM->initialize();
$obj->clear("it");
ok( !$obj->is("it") );
ok( @GOTM::RESULTS == 0 );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 0)\n"
  if (@GOTM::RESULTS != 0);

exit (0);
