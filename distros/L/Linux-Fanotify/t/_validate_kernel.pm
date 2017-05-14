package _validate_kernel;

use Exporter;
use Test::More ();

our @ISA = qw(Exporter);
our @EXPORT = qw(_fano_features HAS_FANO HAS_FANO_PERM);

use constant HAS_FANO => 1;
use constant HAS_FANO_PERM => 2;

sub _uname_r {
	my $ver = `uname -r`;
	chomp($ver);
	return $ver;
}

sub _fano_features {
	my (@cmd1, @cmd2);

	my $diag = "Checking kernel's fanotify capabilities ... ";

	if (-f '/proc/config.gz') {
		@cmd1 = qw(zgrep CONFIG_FANOTIFY=y /proc/config.gz);
		@cmd2 = qw(zgrep CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y /proc/config.gz);
	} elsif (-f '/boot/config-' . _uname_r()) {
		@cmd1 = ( qw(grep CONFIG_FANOTIFY=y) , '/boot/config-' . _uname_r() );
		@cmd2 = ( qw(grep CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y) , '/boot/config-' . _uname_r() );
	} else {
		Test::More::diag($diag . "Failed: no matching kernel configuration found.\n");
		return undef;
	}

	my $p = $cmd1[0];
	if (! `which $p`) {
		Test::More::diag($diag . "Failed: $p not found.\n");
		return undef;
	}

	my $ret = system(@cmd1);
	my $rv = 0;

	if ($ret == 0) {
		$ret = system(@cmd2);

		if ($ret == 0) {
			Test::More::diag($diag . "Great, kernel provides full fanotify features.");
			$rv = HAS_FANO | HAS_FANO_PERM;
		} else {
			Test::More::diag($diag . "Kernel provides fanotify, but no permission handling.");
			$rv = HAS_FANO;
		}
	} else {
		Test::More::diag($diag . "Kernel does not provide fanotify.");
		$rv = 0;
	}

	return $rv;
}

1;
