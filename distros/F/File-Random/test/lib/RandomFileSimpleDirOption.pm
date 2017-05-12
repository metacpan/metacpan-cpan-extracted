package RandomFileSimpleDirOption;
use base qw/RandomFileMethodBase/;
use TestConstants;

use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;

use constant SIMPLE_DIR_ARGS  => ([-path => SIMPLE_DIR, -home => HOME_DIR],
                                  [-dir => no_slash(   SIMPLE_DIR)],
							      [-dir => with_slash (SIMPLE_DIR)]);
								   
use constant EMPTY_DIR_ARGS   => ([-path => EMPTY_DIR, -home => HOME_DIR],
                                  [-dir => no_slash   (EMPTY_DIR)],
							      [-dir => with_slash (EMPTY_DIR)]);
									 
use constant WRONG_DIR_PARAMS => ("/foo/bar/nonsens/reallynonsens/", 
                                  undef, '', 0, [], {});

sub create_empty_subdir : Test(setup) {
	mkdir EMPTY_DIR;
}

sub dir_option_with_a_simple_dir : Test(3) {
	my $self = shift;
	foreach (SIMPLE_DIR_ARGS) {
		$self->expected_files_found_ok([ SIMPLE_FILES ], 
		                               $_, 
									   "Simple Dir: Args ". join " ", @$_);
	}
}

sub dir_option_for_an_empty_dir : Test(3) {
	my $self = shift;
	foreach (EMPTY_DIR_ARGS) {
		$self->expected_files_found_ok([], 
		                               $_, 
									   "Empty Dir: Argumente " . join " ", @$_);
	}
}

sub samples_arent_same : Test(1) {
	my ($self) = @_;
	my @arg = (-dir => SIMPLE_DIR);
	ok( ! eq_array( [$self->sample(@arg)], [$self->sample(@arg)] ), 
	    "samples are different" );
}

sub wrong_dir_parameters : Test(6) {
	my ($self) = @_;
	foreach my $wrong_dir ( WRONG_DIR_PARAMS() ) {
		dies_ok( sub {$self->random_file(-dir => $wrong_dir)}, 
		         "-dir " . Dumper($wrong_dir) );
	}
}

1;
