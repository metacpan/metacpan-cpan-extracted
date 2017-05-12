package My::Module::Build;

use strict;
use warnings;
use version;
use base 'Module::Build';

use File::Which;

#------------------------------------------------------------------------------


sub new {
    my ($class, %args) = @_;

    my $pinto_exe = File::Which::which('pinto');

    my $version_cmd_output = $pinto_exe ? qx($pinto_exe --version) : '';
    my ($installed_pinto_version) = ($version_cmd_output =~ m/version ([\d\._v]+) /);
    $installed_pinto_version ||= 'undef';  # Old releases don't have the --version option

    my $min_pinto_version = version->parse('0.098'); # TODO: Make configurable
    my $has_acceptable_pinto = $installed_pinto_version >= $min_pinto_version;

    my $reason = !$pinto_exe            ? 'pinto does not appear to be installed in your PATH'
  	           : !$has_acceptable_pinto ? "pinto $min_pinto_version is required.  You only have version $installed_pinto_version"
  	           : undef;

    if ($reason) {
	    print <<"END_MESSAGE";
#######################################################################
$reason

I recommend installing Pinto as a stand-alone application as shown here:

    https://metacpan.org/pod/Pinto::Manual::Installing

This will ensure you get precisely the right versions of all the modules
and it won't alter the existing environment.  So you might want to go do
that first, set PINTO_HOME, and then come back to install this module.

Or, I can just install Pinto directly into PERL5LIB along with all your
other Perl modules.  In this case, I can't guarantee that you'll have
compatible versions of all the dependencies.  Pinto is fairly large,
so it could upgrade or add a lot of dependencies to your environment.
#######################################################################
END_MESSAGE

		$args{requires}->{'Pinto'} = $min_pinto_version
    		if $class->y_n('Shall I also install Pinto into PERL5LIB?', 'n');
    }

	return $class->SUPER::new(%args);
}

#-----------------------------------------------------------------------------
1;

__END__