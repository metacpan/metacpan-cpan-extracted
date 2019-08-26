package Dist::Banshee::Mint;
$Dist::Banshee::Mint::VERSION = '0.001';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/instantiate_skeleton transact_update update_script update_patch keep_file keep_patches/;

use File::Copy 'copy';
use File::Path 'rmtree';
use File::Slurper qw/read_text write_text read_dir read_lines/;
use File::Spec::Functions qw/catdir catfile/;
use Text::Diff 'diff';
use Text::Patch 'patch';

sub _find_profile {
	my ($name, @append) = @_;
	my ($home) = glob '~';
	my $dir = catdir($home, '.dist-banshee', $name, @append);

	die "No such profile $name" if not -d $dir;

	return $dir;
}


sub _copy_files {
	my ($from_dir, $to_dir) = @_;
	mkdir $to_dir if not -d $to_dir;
	for my $entry (read_dir($from_dir)) {
		my $from = catfile($from_dir, $entry);
		if (-f $from) {
			copy($from, catfile($to_dir, $entry)) or die "Could not copy";
		}
		elsif (-d $from) {
			_copy_files(catdir($from_dir, $entry), catdir($to_dir, $entry));
		}
	}
}

sub instantiate_skeleton {
	my ($skeleton_name, $dist_name) = @_;

	my $source_dir = _find_profile($skeleton_name);

	my $inherit_file = catfile($source_dir, 'inherit');
	if (-f $inherit_file) {
		for my $ancestor (read_lines($inherit_file)) {
			instantiate_skeleton($ancestor, $dist_name);
		}
	}

	mkdir $dist_name;
	_copy_files($source_dir, $dist_name);
	return;

}

sub transact_update(&) {
	my $function = shift;

	my $success = eval {
		mkdir '.banshee-update';
		$function->();
		rmtree('.banshee');
		rename '.banshee-update', '.banshee';
		1;
	} or do {
		rmdir '.banshee-update';
		die $@;
	}
}

sub update_script {
	my ($skeleton_name, $script_name) = @_;

	my $source_dir = _find_profile($skeleton_name, 'skeleton', '.banshee');

	my $source = catfile($source_dir, $script_name);
	my $sink = catfile('.banshee-update', $script_name);
	my $patch = catfile('.banshee', $script_name . '.patch');
	if ($patch && -f $patch) {
		my $text = read_text($source);
		my $patch = read_text($patch);
		my $output = patch($text, $patch, { STYLE => 'Unified' });
		write_text($sink, $output);
	}
	else {
		copy($source, $sink) or die "Couldn't copy $script_name from $skeleton_name";
	}

	return;
}

sub update_patch {
	my ($skeleton_name, $script_name) = @_;

	my $source_dir = _find_profile($skeleton_name, 'skeleton', '.banshee');

	my $source = catfile('.banshee', $script_name);
	my $sink = catfile($source_dir, $script_name);
	my $diff = diff($sink, $source, { STYLE => 'Unified' });
	my $patch = "$source.patch";

	if (length $diff) {
		write_text($patch, $diff);
	}
	elsif (-f $patch) {
		unlink $patch or die "Couldn't remove patch $patch";
	}
	return;
}

sub keep_file {
	my $name = shift;
	my $source = catfile('.banshee', $name);
	my $sink = catfile('.banshee-update', $name);
	copy($source, $sink) or die "Couldn't keep $name";
	return;
}

sub keep_patches {
	keep_file($_) for grep { /\.patch$/ } read_dir('.banshee');
	return;
}

1;
