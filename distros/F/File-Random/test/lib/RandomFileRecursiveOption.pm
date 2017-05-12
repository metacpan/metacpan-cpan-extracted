package RandomFileRecursiveOption;
use base qw/RandomFileMethodBase/;
use TestConstants;

use Data::Dumper;

use constant REC_ON_ARGS       => (1, "on", "true", 9);
use constant REC_OFF_ARGS      => (0, undef, "0", '');

sub recursive_tests : Test(10) {
	my $self = shift;
	$self->_did_i_found([REC_FILES], -recursive => $_) for REC_ON_ARGS();

	chdir REC_DIR;
	$self->_did_i_found([REC_FILES], -dir => '.', -recursive => 1);
	chdir HOME_DIR;

	$self->_did_i_found([REC_ODD_FILES], -recursive => 1, 
    	                                 -check     => qr/[13579]$/);

	$self->_did_i_found([REC_TOP_FILES], -recursive => $_) for REC_OFF_ARGS();
}

sub _did_i_found {
	my ($self, $exp, @params) = @_;
	@params = (-dir => REC_DIR, @params);
	$self->expected_files_found_ok( $exp, [@params], "Args: ".Dumper(\@params) ); 
}

1;
