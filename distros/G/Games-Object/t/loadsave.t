# -*- perl -*-

# Load and save capabilities

package GOTM;

use strict;
use warnings;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw($RESULT);

my %index = ();

sub new
{
	my $class = shift;
	my $obj = {};
	%$obj = @_;
	$index{$obj->{id}} = $obj;
	bless $obj, $class;
	$obj;
}

sub find
{
	shift if @_ > 1;
	my $id = shift;

	$index{id};
}

sub id { shift->{id}; }

sub load
{
	my $class = shift;
	my $file = shift;
	my $obj = {};

	while (my $tag = <$file>) {
	    chomp $tag;
	    last if ($tag eq "ZOT");
	    my $val = <$file>;
	    chomp $val;
	    $obj->{$tag} = $val;
	}
	bless $obj, $class;
}

sub save
{
	my $obj = shift;
	my $file = shift;

	foreach my $tag (keys %$obj) {
	    print $file "$tag\n$obj->{$tag}\n";
	}
	print $file "ZOT\n";
	1;
}

1;

package GOTMSub;

use strict;
use warnings;
use Exporter;
use Games::Object;
use vars qw(@EXPORT_OK @ISA);

@ISA = qw(Games::Object Exporter);
@EXPORT_OK = qw(@RESULTS);

use vars qw(@RESULTS);

sub initialize { @RESULTS = (); }

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $obj = Games::Object->new(@_);

	bless $obj, $class;
	$obj;
}

# Test method just to make sure it REALLY got re-blessed properly ...

sub answer { 42; }

# Action callbacks, to prove that these can be reloaded.

sub action_changed1
{
	my ($self, $old, $new) = @_;
	push @RESULTS, [ $self->id(), 1, $old, $new ];
	1;
}

sub action_changed2
{
	my ($self, $change) = @_;
	push @RESULTS, [ $self->id(), 2, $change ];
	1;
}

sub action_maxed
{
	my ($self, $excess) = @_;
	push @RESULTS, [ $self->id(), 'max', $excess ];
	1;
}

1;

package main;

use strict;
use warnings;
use Test;
use Games::Object qw(:attrflags);
use Games::Object::Manager;
use IO::File;

BEGIN { $| = 1; plan tests => 32 }

# Create an object from the test module for later use.
my $testobj = GOTM->new(
    id	=> "ackthhbt",
    foo	=> 'blub',
    bar	=> 'blork',
    zog	=> 'yes, no',
);

# Create an object with some attributes.
my $filename = "./testobj.save";
my $obj1 = GOTMSub->new(-id => "SaveObject");
$obj1->new_attr(
    -name	=> "TheAnswer",
    -type	=> "int",
    -value	=> 42,
);
$obj1->new_attr(
    -name	=> "TheQuestion",
    -type	=> "string",
    -value	=> "Unknown, computation did not complete.",
);
$obj1->new_attr(
    -name	=> "HarrysHouse",
    -type	=> 'string',
    -values	=> [qw(Gryffindor Ravenclaw Hufflepuff Slytherin)],
    -value	=> 'Gryffindor',
);
$obj1->new_attr(
    -name	=> "EnterpriseCommander",
    -type	=> 'string',
    -values	=> [qw(Archer Kirk Picard)],
    -map	=> {
	Archer	=> "First starship named Enterprise",
	Kirk	=> "Constitution class vessel",
	Picard	=> "Galaxy class vessel",
    },
    -value	=> 'Kirk',
);
$obj1->new_attr(
    -name	=> "PercentDone",
    -type	=> 'number',
    -value	=> 0,
    -real_value	=> 100,
    -tend_to_rate => 0.5,
);
$obj1->new_attr(
    -name	=> "ComplexData",
    -type	=> 'any',
    -value	=> {
	foo	=> 'bar',
	baz	=> [ 'fud', 'bop' ],
	blork	=> {
	    this	=> 'that',
	    here	=> 'there',
	}
    },
);
$obj1->new_attr(
    -name	=> "ActionData",
    -type	=> 'int',
    -value	=> 50,
    -minimum	=> 0,
    -maximum	=> 100,
    -on_change	=> [
	[ 'O:self', 'action_changed1', 'A:old', 'A:new' ],
	[ 'O:self', 'action_changed2', 'A:change' ],
    ],
    -on_maximum	=> [ 'O:self', 'action_maxed', 'A:excess' ],
);
$obj1->new_attr(
    -name	=> "DisappearingData",
    -flags	=> ATTR_DONTSAVE,
    -type	=> "string",
    -value	=> "How not to be seen",
);
$obj1->new_attr(
    -name	=> "MagicalData",
    -flags	=> ATTR_AUTOCREATE | ATTR_DONTSAVE,
    -type	=> "string",
    -value	=> "Supercalifragilisticexpialadocious",
);

# Add an object reference.
eval('$obj1->new_attr(
    -name	=> "WeirdObject",
    -type	=> "object",
    -value	=> $testobj,
)');
ok( $@ eq '' );
print "# \$@ = $@" if ($@ ne '');

# Trigger the action callbacks on ActionData just to make sure they work.
GOTMSub->initialize();
$obj1->mod_attr(-name => "ActionData", -modify => 10);
ok( @GOTMSub::RESULTS == 2
 && $GOTMSub::RESULTS[0][0] eq 'SaveObject'
 && $GOTMSub::RESULTS[0][1] == 1
 && $GOTMSub::RESULTS[0][2] == 50
 && $GOTMSub::RESULTS[0][3] == 60
 && $GOTMSub::RESULTS[1][0] eq 'SaveObject'
 && $GOTMSub::RESULTS[1][1] == 2
 && $GOTMSub::RESULTS[1][2] == 10 );

# Save it to a file.
my $file1 = IO::File->new();
$file1->open(">$filename") or die "Cannot open file $filename\n";
eval('$obj1->save(-file => $file1)');
ok( $@ eq '' );
print "# \$@ = $@" if ($@ ne '');
$file1->close();
my $size = -s $filename;
#print "# $filename is $size bytes\n";
ok( $size != 0 );

# Now reopen this file and try to create a new object from it.
my $file2 = IO::File->new();
$file2->open("<$filename") or die "Cannot open file $filename\n";
my $obj2;
eval('$obj2 = Games::Object->load(-file => $file2)');
ok( defined($obj2) && $obj2->id() eq 'SaveObject');
print "# \$@ = $@" if (!defined($obj2));
$file2->close();

# Check that the attributes are the same. The pure DONTSAVE attribute should
# NOT be there, while the DONTSAVE + AUTOCREATE should be there but empty.
ok( $obj2->attr('TheAnswer') == 42 );
ok( $obj2->attr('TheQuestion') eq "Unknown, computation did not complete." );
ok( $obj2->attr('HarrysHouse') eq 'Gryffindor' );
ok( $obj2->attr('EnterpriseCommander') eq 'Constitution class vessel' );
ok( $obj2->raw_attr('EnterpriseCommander') eq 'Kirk' );
ok( $obj2->attr('PercentDone') == 0 );
my $data = $obj2->attr('ComplexData');
ok( $data->{foo} eq 'bar'
 && $data->{baz}[1] eq 'bop'
 && $data->{blork}{this} eq 'that' );
ok( $obj2->attr('ActionData') == 60 );
ok( !$obj2->attr_exists('DisappearingData') );
ok( $obj2->attr_exists('MagicalData') && $obj2->attr('MagicalData') eq '' );

# Check that the object reference was loaded and contains the right data.
# We cheat a little here in the interests of testing: we compare stringified
# references (to insure that a new object was indeed created and this is not
# just the old reference) and to check the values of the object's keys.
my $testobj2 = $obj2->attr('WeirdObject');
ok( "$testobj2" ne "$testobj" && ref($testobj2) eq 'GOTM' );
ok( $testobj2->{id} eq "ackthhbt"
 && $testobj2->{foo} eq 'blub'
 && $testobj2->{bar} eq 'blork'
 && $testobj2->{zog} eq 'yes, no' );

# Call process() on the second object. Make sure it updated but the new one
# did not, which should prove that they're distinct objects.
$obj2->process();
ok( $obj1->attr('PercentDone') == 0 );
ok( $obj2->attr('PercentDone') == 0.5 );

# Tweak the action callback as well, make sure it executes
GOTMSub->initialize();
$obj2->mod_attr(-name => "ActionData", -modify => 5);
ok( @GOTMSub::RESULTS == 2
 && $GOTMSub::RESULTS[0][0] eq 'SaveObject'
 && $GOTMSub::RESULTS[0][1] == 1
 && $GOTMSub::RESULTS[0][2] == 60
 && $GOTMSub::RESULTS[0][3] == 65
 && $GOTMSub::RESULTS[1][0] eq 'SaveObject'
 && $GOTMSub::RESULTS[1][1] == 2
 && $GOTMSub::RESULTS[1][2] == 5 );

# Now attempt to load that file by its filename rather than opening the file
# ourselves. We turn on the attribute accessor method feature to make sure
# that.
my $obj3;
eval('$obj3 = Games::Object->load(-filename =>$filename)');
ok( defined($obj3) && $obj3->id() eq 'SaveObject' );
ok( $obj3->attr('TheAnswer') == 42 );
ok( $obj3->attr('TheQuestion') eq "Unknown, computation did not complete." );
ok( $obj3->attr('HarrysHouse') eq 'Gryffindor' );
ok( $obj3->attr('EnterpriseCommander') eq 'Constitution class vessel' );
ok( $obj3->raw_attr('EnterpriseCommander') eq 'Kirk' );
ok( $obj3->attr('PercentDone') == 0 );
ok( $obj3->attr('ActionData') == 60 );
my $testobj3 = $obj3->attr('WeirdObject');
ok( "$testobj3" ne "$testobj" && ref($testobj3) eq 'GOTM' );
ok( $testobj3->{id} eq "ackthhbt"
 && $testobj3->{foo} eq 'blub'
 && $testobj3->{bar} eq 'blork'
 && $testobj3->{zog} eq 'yes, no' );

# Tweak the action callback as well, make sure it executes
GOTMSub->initialize();
$obj3->mod_attr(-name => "ActionData", -modify => 5);
ok( @GOTMSub::RESULTS == 2
 && $GOTMSub::RESULTS[0][0] eq 'SaveObject'
 && $GOTMSub::RESULTS[0][1] == 1
 && $GOTMSub::RESULTS[0][2] == 60
 && $GOTMSub::RESULTS[0][3] == 65
 && $GOTMSub::RESULTS[1][0] eq 'SaveObject'
 && $GOTMSub::RESULTS[1][1] == 2
 && $GOTMSub::RESULTS[1][2] == 5 );

# Finally, we need to test the ability to load multiple objects from the
# same file. Note that we're testing exclusively the individual object load/save
# functionality rather than manager functionality, which is covered in another
# test. First produce a file containing several objects in it.
unlink $filename;
$filename = "./testobjs.save";
my $file3 = IO::File->new();
$file3->open(">$filename") or die "Cannot open file $filename\n";
my $count = 0;
my @pspecs = (
    [ 'Mercury', 'Mercurial Mugwumps', 1.3 ],
    [ 'Venus', 'Venusian Voles', 2.9 ],
    [ 'Earth', 'Hectic Humans', 1.4 ],
    [ 'Mars', 'Martian Mammals', 12.7 ],
    [ 'Jupiter', 'Jovian Jehosephats', 5.9 ],
    [ 'Saturn', 'Saturine Satyrs', 0.6 ],
    [ 'Uranus', 'Uranian Ugnaughts', 0.9 ],
    [ 'Neptune', 'Neptunian Nymphs', 1.5 ],
    [ 'Pluto', 'Plutonian Plutocrats', 0.00005 ],
);
foreach my $spec (@pspecs) {
	$count++;
	my $obj = Games::Object->new(-id => 'Planet' . $count);
	$obj->new_attr(
	    -name	=> 'Name',
	    -type	=> 'string',
	    -value	=> $spec->[0],
	);
	$obj->new_attr(
	    -name	=> "Lifeform",
	    -type	=> 'string',
	    -value	=> $spec->[1],
	);
	$obj->new_attr(
	    -name	=> "GalacticCreditExchangeRate",
	    -type	=> 'number',
	    -value	=> $spec->[2],
	);
	$obj->save(-file => $file3);
}
$file3->close();
$size = -s $filename;
#print "# $filename is $size bytes\n";

# Now reopen the file and attempt to read them back in, validating as we go.
my $file4 = IO::File->new();
$file4->open("<$filename") or die "Cannot open file $filename\n";
while ($count) {
    my $spec = shift @pspecs;
    my $obj;
    my $pnum = 10 - $count;
    eval('$obj = Games::Object->load(-file =>$file4, -id => "NewPlanet" . $pnum)');
    if ($@) {
	print "# Load of $pnum failed\n";
	last;
    }
    if ($obj->attr('Name') ne $spec->[0]) {
	print "# attr Name is bad in $pnum\n";
	last;
    }
    if ($obj->attr('Lifeform') ne $spec->[1]) {
	print "# attr Lifeform is bad in $pnum\n";
	last;
    }
    if ($obj->attr('GalacticCreditExchangeRate') != $spec->[2]) {
	print "# attr GalacticCreditExchangeRate is bad in $pnum\n";
	last;
    }
    $count --;
}
$file4->close();
ok( $count == 0 );
unlink $filename;

exit (0);
