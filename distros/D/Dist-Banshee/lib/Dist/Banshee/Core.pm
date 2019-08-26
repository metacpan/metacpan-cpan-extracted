package Dist::Banshee::Core;
$Dist::Banshee::Core::VERSION = '0.001';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/source write_file write_files in_tempdir dist_test write_tarball prompt y_n bump_version add_manifest/;

use Carp 'croak';
use File::Spec::Functions 'catfile';
use File::Basename 'dirname';
use File::Path 'mkpath';
use File::Slurper 'write_binary';
use File::Temp 'tempdir';
use File::chdir;

sub source {
	my ($filename, @arguments) = @_;
	my $path = catfile('.banshee', "$filename.source");
	my $ret = do "./$path";
	croak $@ if not defined $ret;
	return $ret;
}

sub write_file {
	my ($filename, $content) = @_;
	mkpath(dirname($filename));
	write_binary($filename, $content);
	return;
}

sub write_files {
	my $files = shift;
	for my $filename (keys %{ $files }) {
		mkpath(dirname($filename));
		write_binary($filename, $files->{$filename});
	}
	return;
}

sub write_tarball {
	my ($files, $meta, $trial) = @_;

	require Archive::Tar;
	my $arch = Archive::Tar->new;
	for my $filename (keys %{ $files }) {
		$arch->add_data($filename, $files->{$filename}, { mode => oct '0644'} );
	}
	my $name = $meta->name . '-' . $meta->version . ( $trial ? '-TRIAL' : '');
	my $file =  "$name.tar.gz";
	$arch->write($file, &Archive::Tar::COMPRESS_GZIP, $name);

	return $file;
}

sub in_tempdir(&) {
	my ($code) = @_;
	local $CWD = tempdir(CLEANUP => 1);
	$code->();
}

sub dist_test {
	my ($files) = @_;
	in_tempdir {
		write_files($files);

		system $^X, 'Makefile.PL' and die "Failed perl Makefile.PL";
		system 'make' and die "Failed make";
		system 'make', 'test' and die "Failed make test";
	};
}

sub prompt {
    my($mess, $def) = @_;
    croak "prompt function called without an argument" unless defined $mess;

    my $dispdef = defined $def ? "[$def]" : '';
	$def = '' if not defined $def;

    local $|=1;
    local $\;
    print "$mess $dispdef ";

	my $ans = <STDIN>;
	if (defined $ans) {
		chomp $ans;
		return $ans if $ans ne '';
	}
	else { # user hit ctrl-D
		print "\n";
	}

	return $def;
}

sub y_n {
	my ($mess, $def) = @_;

	croak "y_n() called without a prompt message" unless $mess;
	croak "Invalid default value: y_n() default must be 'y' or 'n'"
		if $def && $def !~ /^[yn]/i;

	while (1) {
		my $answer = prompt($mess, $def);
		return 1 if $answer =~ /^y/i;
		return 0 if $answer =~ /^n/i;
		local $|=1;
		print "Please answer 'y' or 'n'.\n";
	}
}

sub bump_version {
	my (@files) = @_;

	my $pid = open my $handle, '-|', 'perl-reversion', '-bump', @files;
	my @lines = <$handle>;
	waitpid $pid, 0 or die 'Couldn\'t bump version ' . join "\n", @lines;

	my @updated;
	for my $line (@lines) {
		push @updated, $1 if $line =~ /^Saving (.*?)$/ms;
	}

	return @updated;
}

sub add_manifest {
	my $files = shift;
	$files->{MANIFEST} = join "\n", sort keys %{ $files }, 'MANIFEST';
	return;
}

1;
