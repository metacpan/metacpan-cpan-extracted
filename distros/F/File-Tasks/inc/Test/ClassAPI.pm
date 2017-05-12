#line 1
package Test::ClassAPI;

# Allows us to test class APIs in a simplified manner.
# Implemented as a wrapper around Test::More, Class::Inspector and Config::Tiny.

use 5.005;
use strict;
use Test::More       ();
use Config::Tiny     ();
use Class::Inspector ();
use Params::Util     '_INSTANCE';

use vars qw{$VERSION $CONFIG $SCHEDULE $EXECUTED %IGNORE *DATA};
BEGIN {
	$VERSION = '1.04';

	# Config starts empty
	$CONFIG   = undef;
	$SCHEDULE = undef;

	# We only execute once
	$EXECUTED = '';

	# When looking for method that arn't described in the class
	# description, we ignore anything from UNIVERSAL.
	%IGNORE = map { $_, 1 } qw{isa can};
}

# Get the super path ( not including UNIVERSAL )
# Rather than using Class::ISA, we'll use an inlined version
# that implements the same basic algorithm, but faster.
sub _super_path($) {
	my $class = shift;
	my @path  = ();
	my @queue = ( $class );
	my %seen  = ( $class => 1 );
	while ( my $cl = shift @queue ) {
		no strict 'refs';
		push @path, $cl;
		unshift @queue, grep { ! $seen{$_}++ }
			map { s/^::/main::/; s/\'/::/g; $_ }
			( @{"${cl}::ISA"} );
	}

	@path;
}





#####################################################################
# Main Methods

# Initialise the Configuration
sub init {
	my $class = shift;

	# Use the script's DATA handle or one passed
	*DATA = ref($_[0]) eq 'GLOB' ? shift : *main::DATA;
 
	# Read in all the data, and create the config object
	local $/ = undef;
	$CONFIG = Config::Tiny->read_string( <DATA> )
		or die 'Failed to load test configuration: '
			. Config::Tiny->errstr;
	$SCHEDULE = delete $CONFIG->{_}
		or die 'Config does not have a schedule defined';

	# Add implied schedule entries
	foreach my $tclass ( keys %$CONFIG ) {
		$SCHEDULE->{$tclass} ||= 'class';
		foreach my $test ( keys %{$CONFIG->{$tclass}} ) {
			next unless $CONFIG->{$tclass}->{$test} eq 'implements';
			$SCHEDULE->{$test} ||= 'interface';
		}
	}
	

	# Check the schedule information
	foreach my $tclass ( keys %$SCHEDULE ) {
		my $value = $SCHEDULE->{$tclass};
		unless ( $value =~ /^(?:class|abstract|interface)$/ ) {
			die "Invalid schedule option '$value' for class '$tclass'";
		}
		unless ( $CONFIG->{$tclass} ) {
			die "No section '[$tclass]' defined for schedule class";
		}
	}

	1;
}

# Find and execute the tests
sub execute {
	my $class = shift;
	if ( $EXECUTED ) {
		die 'You can only execute once, use another test script';
	}
	$class->init unless $CONFIG;

	# Handle options
	my @options = map { lc $_ } @_;
	my $CHECK_UNKNOWN_METHODS     = !! grep { $_ eq 'complete'   } @options;
	my $CHECK_FUNCTION_COLLISIONS = !! grep { $_ eq 'collisions' } @options;

	# Set the plan of no plan if we don't have a plan
	unless ( Test::More->builder->has_plan ) {
		Test::More::plan( 'no_plan' );
	}

	# Determine the list of classes to test
	my @classes = sort keys %$SCHEDULE;
	@classes = grep { $SCHEDULE->{$_} ne 'interface' } @classes;

	# Check that all the classes/abstracts are loaded
	foreach my $class ( @classes ) {
		Test::More::ok( Class::Inspector->loaded( $class ), "Class '$class' is loaded" );
	}

	# Check that all the full classes match all the required interfaces
	@classes = grep { $SCHEDULE->{$_} eq 'class' } @classes;
	foreach my $class ( @classes ) {
		# Find all testable parents
		my @path = grep { $SCHEDULE->{$_} } _super_path($class);

		# Iterate over the testable entries
		my %known_methods = ();
		my @implements = ();
		foreach my $parent ( @path ) {
			foreach my $test ( sort keys %{$CONFIG->{$parent}} ) {
				my $type = $CONFIG->{$parent}->{$test};

				# Does the class have a named method
				if ( $type eq 'method' ) {
					$known_methods{$test}++;
					Test::More::can_ok( $class, $test );
					next;
				}

				# Does the class inherit from a named parent
				if ( $type eq 'isa' ) {
					Test::More::ok( $class->isa($test), "$class isa $test" );
					next;
				}

				unless ( $type eq 'implements' ) {
					print "# Warning: Unknown test type '$type'";
					next;
				}
				
				# When we 'implement' a class or interface,
				# we need to check the 'method' tests within
				# it, but not anything else. So we will add
				# the class name to a seperate queue to be
				# processed afterwards, ONLY if it is not
				# already in the normal @path, or already
				# on the seperate queue.
				next if grep { $_ eq $test } @path;
				next if grep { $_ eq $test } @implements;
				push @implements, $test;
			}
		}

		# Now, if it had any, go through and check the classes added
		# because of any 'implements' tests
		foreach my $parent ( @implements ) {
			foreach my $test ( keys %{$CONFIG->{$parent}} ) {
				my $type = $CONFIG->{$parent}->{$test};
				if ( $type eq 'method' ) {
					# Does the class have a method
					$known_methods{$test}++;
					Test::More::can_ok( $class, $test );
				}
			}
		}

		if ( $CHECK_UNKNOWN_METHODS ) {
			# Check for unknown public methods
			my $methods = Class::Inspector->methods( $class, 'public', 'expanded' )
				or die "Failed to find public methods for class '$class'";
			@$methods = grep { $_->[2] !~ /^[A-Z_]+$/ } # Internals stuff
				grep { $_->[1] ne 'Exporter' } # Ignore Exporter methods we don't overload
				grep { ! ($known_methods{$_->[2]} or $IGNORE{$_->[2]}) } @$methods;
			if ( @$methods ) {
				print STDERR join '', map { "# Found undocumented method '$_->[2]' defined at '$_->[0]'\n" } @$methods;
			}
			Test::More::is( scalar(@$methods), 0, "No unknown public methods in '$class'" );
		}

		if ( $CHECK_FUNCTION_COLLISIONS ) {
			# Check for methods collisions.
			# A method collision is where
			#
			#     Foo::Bar->method
			#
			# is actually interpreted as
			#
			#     &Foo::Bar()->method
			#
			no strict 'refs';
			my @collisions = ();
			foreach my $symbol ( sort keys %{"${class}::"} ) {
				next unless $symbol =~ s/::$//;
				next unless defined *{"${class}::${symbol}"}{CODE};
				print STDERR "Found function collision: ${class}->${symbol} clashes with ${class}::${symbol}\n";
				push @collisions, $symbol;
			}
			Test::More::is( scalar(@collisions), 0, "No function/class collisions in '$class'" );
		}
	}

	1;
}

1;

__END__

#line 350
