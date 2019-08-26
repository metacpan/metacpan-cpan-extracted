package Dist::Banshee::Git;
$Dist::Banshee::Git::VERSION = '0.001';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/gather_files commit_files/;

use Git::Wrapper;
use File::Slurper 'read_binary';

sub gather_files {
	my ($filter) = @_;
 
	# Prepare to gather files
	my $git = Git::Wrapper->new('.');
 
	# Loop over files reported by git ls-files
	my @filenames = grep { !-d } $git->ls_files;
	@filenames = grep { $filter->($_) } @filenames if $filter;

	my %ret = map { $_ => read_binary($_) } @filenames;
	return \%ret;
}

sub commit_files {
	my ($message, @allowed) = @_;
	my %allowed = map { $_ => 1 } @allowed;

	my $git = Git::Wrapper->new('.');
	my @changed = $git->ls_files({ modified => 1, deleted => 1 });
	my @updated = grep { $allowed{$_} } @changed;
	if (@updated) {
		$git->add(@updated);
		$git->commit({ m => $message});
	}
	else {
		warn "Nothing to update\n";
	}
}

1;
