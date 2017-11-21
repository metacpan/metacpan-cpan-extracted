package Linux::InitFS::Kernel;
use warnings;
use strict;

use Cwd;

my %CONFIG;


sub _detect_kconfig_here {
	my ( $path ) = @_;

	return unless $path;

	my $full = $path . '/.config';

	if ( -f $full and -r $full ) {
		return $full;
	}

	my @part = split /\//, $path;
	pop @part;
	my $next = join( '/', @part );

	return _detect_kconfig_here( $next );
}

sub _detect_kconfig_proc {
}

sub _detect_kconfig_src {

	return _detect_kconfig_here( '/usr/src/linux' );
}


sub _import_kernel_config {
	my ( $path ) = @_;

	my $rc = open my $fh, '<', $path;
	return unless defined $rc;

	while ( <$fh> ) {
		chomp;
		s/#.*//;
		s/^\s+//;
		s/\s+$//;
		next unless $_;

		my ( $key, $val ) = split /=/;
	
		$CONFIG{$key} = $val;

	}

	return keys %CONFIG;
}


sub detect_config() {

	my $file   = _detect_kconfig_here( getcwd() );
	   $file ||= _detect_kconfig_proc();
	   $file ||= _detect_kconfig_src();

	return unless $file;

	return _import_kernel_config( $file );
}

sub feature_enabled($) {
	my ( $cfgkey ) = @_;

	$cfgkey = 'CONFIG_' . $cfgkey;

	return unless $CONFIG{$cfgkey};

	return $CONFIG{$cfgkey} eq 'y';
}


1;
