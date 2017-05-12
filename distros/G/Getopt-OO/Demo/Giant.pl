#!/usr/local/bin/perl -w
# $Id: Giant.pl,v 1.1 2005/01/23 20:22:39 sjs Exp $

=head1 NAME Giant.pl

=head1 DESCRIPTION

Giant.pl is a demonstration of the use of Getopt::OO.
It uses almost every feature of the parser.  Please note
that I don't suggest that you write your code like this.
This is a demonstration only.  In particular, the I would
use the callback below to validate that the giant isn't
exceeding his vocabulary, but I would not use the ClientData
method just to echo what he said with code references.

Try
    Giant.pl -w -b --roars fe fum fo fi -s
for fun!

=cut

use strict;
# use warnings if possible.
eval {require 'warnings.pm'};
eval {require 'Getopt/OO.pm'};
if($@) {
	die "Failed to find Getopt::OO.  Try running \n",
		"\t\"perl -Idir $0\n",
		"where 'dir' is the path to OO.pm.\n";
}

# Set up the parser.  We are using the callback below to filter 
# input from the --roar option.  Our object is that when the
# parser completes we will have eliminated any bogus data.
my $Handle;
eval {
	$Handle = Getopt::OO->new(
		\@ARGV,
		'usage'		=> "Things a giant might do.",
		# Giants gotta roar!
		'required'	=> [ qw(--roars) ],
		'--help'		=> {
			callback => sub {
				system("pod2text $0");
				print "Generated help for this module looks like:\n",
					$_[0]->Help();
				exit(0);
			},
			help => [
				"Run pod2text on this module, print the generated",
				"help message and exit.",
			],
		},
		'--roars'	=> {
			'help'			=> [
				'Giants must roar, but they have a limited vocabulary.',
				'A Giant can only say fe, fi, fo, or fum.'
			],
			'multi_value'	=> 1, 	# -roars fe fi fo -
			'multiple'		=> 1,	# can roar more than once.
			# Use a callback to parse the input roars and die if we
			# get any bogus ones.
			'callback'		=> sub {
				my ($handle, $option) = @_;
				# Multiple is enabled, so return value is a
				# list of array references.  Map dereferences
				# the list references.
				my @roars = map{@$_} $handle->Values($option);
				# Create a hash with good roars in it to use
				# in finding the bogus roars.
				my %good_roars = map {$_,1} qw(fe fi fo fum);
				if(my @bogus = grep !$good_roars{$_}, @roars) {
					die "Silly!  Giants can't \"", join("\", \"", @bogus), "\n";
				}
				# Set the client data to a list of subroutine
				# references to demo how to pass code references
				# in client data.
				my $do_this = $handle->ClientData($option) || [];
				push @{$do_this}, map {
					my $x = $_;
					sub {print "The Giant says $x\n"};
				} @roars;
				$handle->ClientData($option, $do_this);
				0; # Callback must return false or we thik there was an error.
			},
		},
		'-w'	=> {
			'help' => "Giants sometimes wake up.",
			'multiple' => 1,
		},
		'-s'	=> {
			'help' => "Giants sometimes go to sleep.",
			'multiple' => 1,
		},
		'-f'	=> {
			'help' => 'Giants farts are something to fear!',
		},
		'-b'	=> {
			'help' => 'Giants can be rude and belch without apologizing.',
			'multiple' => 1,
		},
	);
};

# at this point, we know that all the giant's input was valid.
die $@, "Failed to parse\n" if $@;
# Values() in arraycontext returns the input options as in the
# order they were found on the command line.
foreach my $option ($Handle->Values()) {
	if ($option eq '--roars') {
		if ($Handle->Values('-s') && $Handle->ClientData('-s')) {
			die "Silly -- Giants don't roar while sleeping!\n";
		}
		else {
			print "The Giant roars!\n";
			map {&{$_}()} @{$Handle->ClientData($option)};
		}
	}
	elsif ($option eq '-s') {
		print "The Giant is going to sleep. zzzzzzzZZzzzzzzzz\n";
		# Use client data to keep track of the state of the giant.
		# if sleep client data is set, the giant is sleeping, if
		# not set, he's awake.
		$Handle->ClientData('-s', 1);
	}
	elsif ($option eq '-w') {
		print "The Giant wakes up, yawnnnnn\n";
		# Giant woke up.  Clear the sleep client data.
		$Handle->ClientData('-s', 0) if $Handle->ClientData('-s');
	}
	elsif ($option eq '-f') {
		die "Oh no!  The Giant farted!  I'm DYINGGGGGGGGGGGggggggg........\n";
	}
	elsif ($option eq '-b') {
		print "How Gross!  The Giant belched and didn't apologize!\n";
	}
	else {
		print "Unhandled option: $option\n";
	}
}

