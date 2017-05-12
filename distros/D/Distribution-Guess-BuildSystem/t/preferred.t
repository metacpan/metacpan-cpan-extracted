#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use File::Basename;
use File::Spec;
use Cwd;


my $class  = 'Distribution::Guess::BuildSystem';
my $method = '_setting';

use_ok( $class );
can_ok( $class, 'preferred_build_file' );
can_ok( $class, 'preferred_build_command' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Default preference
{ # Makemaker only
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros makemaker-true) ),
	);

ok( $guesser->uses_makemaker, "Uses MakeMaker" );
ok( $guesser->uses_makemaker_only, "Uses MakeMaker only" );
is( $guesser->preferred_build_command, $guesser->make_command, "Preferred command is make" );
}

{ # Module::Build only
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros module-build) ),
	);

ok( $guesser->uses_module_build, "Uses Module::Build" );
ok( $guesser->uses_module_build_only, "Uses  Module::Build only" );
is( $guesser->preferred_build_command, $guesser->build_command, "Preferred command is ./Build" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# No explicit preference either way - default is Module::Build
{ # Makemaker only
my $guesser = $class->new(
	dist_dir            => File::Spec->catfile( qw(t test-distros makemaker-true) ),
	);

ok( $guesser->uses_makemaker, "Uses MakeMaker" );
ok( $guesser->uses_makemaker_only, "Uses MakeMaker only" );
is( $guesser->preferred_build_command, $guesser->make_command, "Preferred command is make" );
}

{ # Module::Build only
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros module-build) ),
	);

ok( $guesser->uses_module_build, "Uses Module::Build" );
ok( $guesser->uses_module_build_only, "Uses  Module::Build only" );
is( $guesser->preferred_build_command, $guesser->build_command, "Preferred command is ./Build" );
}

{ # Both
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros makemaker-build-either) ),
	);

ok( $guesser->uses_module_build, "Uses Module::Build" );
ok( $guesser->uses_makemaker,    "Uses  Makemaker" );
is( $guesser->preferred_build_command, $guesser->build_command, "Preferred command is ./Build" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# No preference either way, explicitly
{ # Both
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros makemaker-build-either) ),
	prefer_module_build => 0,
	prefer_makemaker    => 0,
	);

ok( $guesser->uses_module_build, "Uses Module::Build" );
ok( $guesser->uses_makemaker,    "Uses  Makemaker" );
is( $guesser->preferred_build_command, $guesser->build_command, "Preferred command is ./Build when explicit no preference" );

$guesser->prefer_module_build( 1 );
ok( $guesser->prefer_module_build, "Now prefers Module::Build" );
is( $guesser->preferred_build_command, $guesser->build_command, "Preferred command is ./Build" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prefer both, Module::Build should win
{ # Both
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros makemaker-build-either) ),
	prefer_module_build => 1,
	prefer_makemaker    => 1,
	);

ok( $guesser->uses_module_build, "Uses Module::Build" );
ok( $guesser->uses_makemaker,    "Uses  Makemaker" );
is( $guesser->preferred_build_command, $guesser->build_command, "Preferred command is ./Build when preferring both" );

$guesser->prefer_module_build( 0 );
ok( ! $guesser->prefer_module_build, "Now does not prefer Module::Build" );
is( $guesser->preferred_build_command, $guesser->make_command, "Preferred command is now make" );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prefer both, but no build file
{ # Build
my $guesser = $class->new(
	dist_dir => File::Spec->catfile( qw(t test-distros no-build-file) ),
	prefer_module_build => 1,
	prefer_makemaker    => 1,
	);

ok( ! $guesser->uses_module_build, "Does not use Module::Build" );
ok( ! $guesser->uses_makemaker,    "Does not use Makemaker" );
ok( ! $guesser->preferred_build_command, "Preferred command is false with no build file" );

}
