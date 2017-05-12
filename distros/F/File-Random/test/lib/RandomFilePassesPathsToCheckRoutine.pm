package RandomFilePassesPathsToCheckRoutine;
use base qw/RandomFileMethodBase/;
use TestConstants;

use strict;
use warnings;

use Test::More;

sub check_routine_gets_paths : Test(2) {
	my $self = shift;
	my @files_shift = ();
	my @files_it    = ();
	my %files = ('with shift' => \@files_shift, 
	             'with $_'    => \@files_it);
	my %check_routine = (
		'with shift' => sub { push @files_shift, shift() },
		'with $_'    => sub { push @files_it,    $_ }
	);
	while (my ($check_desc, $check_func) = each %check_routine) {
		my @args = (-dir => REC_DIR, 
		            -recursive => 1, 
					-check => $check_func);
		my $exp = Set::Scalar->new(); 
		$exp->insert( $self->random_file(@args) ) for (1 .. SAMPLE_SIZE);
		my $found_files = Set::Scalar->new( @{$files{$check_desc}} );
		
		is $found_files, $exp, "Arguments passed to check $check_desc";
	}
}

1;
