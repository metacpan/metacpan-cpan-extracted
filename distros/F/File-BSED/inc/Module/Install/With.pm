package Module::Install::With;

### HIGHLY EXPERIMENTAL - TALK TO ADAMK BEFORE USING ANY OF THESE COMMANDS

# Provides chunks of functionality for detecting with and interacting with
# the rest of the toolchain, helping Module::Install play well with others.
#
# That is CPAN vs CPANPLUS vs standalone, and EUMM vs MB.

use strict;
use Module::Install::Base;
use File::Spec ();

use vars qw{$VERSION $ISCORE @ISA};
BEGIN {
	$VERSION = '0.67';
	$ISCORE  = 1;
	@ISA     = qw{Module::Install::Base};
}





#####################################################################
# CPAN Client

# What CPAN client are we running under
sub cpan {
	return 'cpanpm'   if cpanpm();
	return 'cpanplus' if cpanplus();
	return 'legacy'   if cpanlegacy();
}

# Are we running a legacy client
sub cpanlegacy {
	return 1 if cpanpm_legacy();
	return 1 if cpanplus_legacy();
	return '';
}

# Are we currently running under a CPAN.pm client (modern method)
# Returns the version of the CPAN.pm client.
sub cpanpm {
	my $script = File::Spec->rel2abs($0);
	return (
		$ENV{PERL5_CPAN_IS_EXECUTING}
		and
		-f $script
		and
		$ENV{PERL5_CPAN_IS_EXECUTING} eq $script
	)
		? ($ENV{PERL5_CPAN_IS_VERSION} || -1)
		: '';
}

# Are we currently running under the legacy CPAN client
# This method is not reliable.
sub cpanpm_legacy {
	my $self = shift;

	# Does the lock file exist?
	my $home = $self->cpanpm_config('cpan_home');
	my $lock = File::Spec->catfile( $home, '.lock' );
	return unless -f $lock;

	# Check the lock
	local *LOCK;
	return unless open(LOCK, $lock);

	my $cpanpm;
	if ( $^O eq 'MSWin32' ) {
		require Cwd;
		my $cwd  = File::Spec->canonpath( Cwd::cwd() );
		my $cpan = File::Spec->canonpath( $home );
		$cpanpm = (index( $cwd, $cpan ) > -1);
	} else {
		$cpanpm = (<LOCK> == getppid());
	}

	close LOCK;
	return !! $cpanpm;
}

# Get a CPAN.pm config value
sub cpanpm_config {
	my $self = shift;

	# Load the CPAN.pm configuration
	unless ( $CPAN::VERSION ) {
		require CPAN; # XXX - TODO, handle error for this
		$CPAN::HandleConfig::VERSION
			? CPAN::HandleConfig->load # Newer CPAN.pm versions
			: CPAN::Config->load;      # Older CPAN.pm versions
	}

	$CPAN::Config->{shift()};
}

# Are we currently running under the CPANPLUS client
sub cpanplus {
	my $script = File::Spec->rel2abs($0);
	return (
		$ENV{PERL5_CPANPLUS_IS_EXECUTING}
		and
		-f $script
		and
		$ENV{PERL5_CPANPLUS_IS_EXECUTING} eq $script
	) ? ($ENV{PERL5_CPANPLUS_IS_VERSION} || -1) : '';
}

# Is CPANPLUS actually installed
sub cpanplus_available {
	$_[0]->can_use('CPANPLUS');
}

# Are we (maybe) running under a legacy version of CPANPLUS
sub cpanplus_legacy {
	!! $ENV{CPANPLUS_IS_RUNNING};
}





#####################################################################
# Installer Target

# Are we targeting ExtUtils::MakeMaker (running as Makefile.PL)
sub eumm {
	!! ($0 =~ /Makefile.PL$/i);
}

# Are we targeting Module::Build (running as Build.PL)
sub mb {
	!! ($0 =~ /Build.PL$/i);
}

# Indicates the use of an ExtUtils::MakeMaker-only feature
sub no_mb {
	my $self = shift;
	return 1 unless $self->mb;

	# This installer is being run via a Build.PL but uses
	# a feature that does not support Module::Build.
	die "Build.PL tried to use a feature unsupported by Module::Build";
}





#####################################################################
# Testing and Configuration Contexts

# Are we in an interactive configuration environment
sub interactive {
	# Treat things interactively ONLY based on input
	!! -t STDIN;
}

# Are we currently running under some sort of automated testing system
sub automated_testing {
	!! $ENV{AUTOMATED_TESTING};
}

sub user_context {
	! $Module::Install::AUTHOR;
}

sub author_context {
	!! $Module::Install::AUTHOR;
}

1;
