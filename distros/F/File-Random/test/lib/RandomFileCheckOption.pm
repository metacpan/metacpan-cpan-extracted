package RandomFileCheckOption;
use base qw/RandomFileMethodBase/;
use TestConstants;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use constant FILES_FOR_RE        => (qr/\d$/ => [ SIMPLE_FILES_WITH_NR  ],
		                             qr/\./  => [ SIMPLE_FILES_WITH_DOT ]);
use constant WRONG_CHECK_PARAMS  => (undef, '', '/./', {}, [], 0);

sub check_standard_case : Test(4) {
	my $self = shift;
	my %files = FILES_FOR_RE;
	foreach my $re (keys %files) {
		foreach my $check (qr/$re/, sub {/$re/}) {
			my @args = (-dir => SIMPLE_DIR, -check => $check);
			$self->expected_files_found_ok($files{$re}, 
			                               [@args],
										   "Used RE $re as " . ref $check);
		}
	}
}

sub wrong_check_params : Test(6) {
	my $self = shift;
	foreach (WRONG_CHECK_PARAMS) {
		my @args = (-dir => SIMPLE_DIR, -check => $_);
		dies_ok( sub {$self->random_file(@args)},
		         "expected to die with Args " . Dumper(\@args) );
	    
	}	
}

1;
