=head1 NAME

Directory::Diff::Copy - Copy differences between two directories

=head1 SYNOPSIS

   use Directory::Diff::Copy 'copy_diff_only';
   copy_diff_only ($old_dir, $new_dir, $output_dir);

=cut

package Directory::Diff::Copy;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/copy_diff_only/;
use warnings;
use strict;
our $VERSION = '0.04';
use Carp;
use File::Copy;
use File::Path;
use Directory::Diff 'directory_diff';

#=head2 mdate
#
#my $mod_date = mdate ($filename);
#
#Returns time that $filename was last modified.
#
#=cut

sub mdate
{
    my ($filename) = @_;
    if (!-e $filename) {
        die "reference file '$filename' not found";
    }
    my @stat = stat ($filename);
    if (@stat == 0) {
        die "'stat' failed for '$filename': $@";
    }
    return $stat[9];
}

sub make_subdir
{
    my ($path, $verbose) = @_;
    $path =~ s!/[^/]+$!/!;
    if (! -d $path) {
        if ($verbose) {
            print "Directory::Diff::Copy: Creating $path.\n";
        }
        mkpath ($path);
        if (! -d $path) {
            die "Could not make path '$path'.\n";
        }
    }
}

sub new_only_callback
{
    my ($data, $dir, $file, $verbose) = @_;
    my $output_dir = $data->{output_dir};
    my $copied_file = "$dir/$file";
    if ($verbose) {
        print "$file will be copied from $copied_file to $output_dir/$file\n";
    }
    my $path = "$output_dir/$file";
    if ($file =~ m!/$!) {
        if ($verbose) {
            print "Creating $path.\n";
        }
        # Make the directory
        mkpath ($path);
    }
    else {
        make_subdir ($path, $verbose);
        if (! -f $copied_file) {
            die "The file to copy, '$copied_file', does not exist";
        }
        sane_copy ("$dir/$file", "$output_dir/$file");
        $data->{count}++;
    }
}

sub sane_copy
{
    my ($from, $to) = @_;
    my (undef, undef, $mode) = stat ($from);
    if (! defined $mode) {
	die "Cannot stat $from: $!";
    }
    # perldoc -f stat
    copy ($from, $to)
        or die "Copy of '$from' to '$to' failed: $!";
    # perldoc -f chmod
    chmod $mode & 07777, $to or die "chmod on $to failed: $!";
}

sub diff_callback
{
    my ($data, $old_dir, $new_dir, $file, $verbose) = @_;
    my $output_dir = $data->{output_dir};
    if ($verbose) {
       print "$file will be copied from $new_dir to $output_dir/$file\n";
    }
    my $path = "$output_dir/$file";
    make_subdir ($path, $verbose);
    if ($verbose) {
        print "Directory::Diff::Copy: Copying '$new_dir/$file' to '$output_dir/$file'.\n";
    }
    sane_copy ("$new_dir/$file", "$output_dir/$file");
    $data->{count}++;
}

=head2 copy_diff_only

   copy_diff_only ($old_dir, $new_dir, $output_dir);

Given $old_dir, $new_dir, and $output_dir, compare the files in
$old_dir and $new_dir using L<Directory::Diff::directory_diff>. If
$output_dir does not exist, create it, if it does exist remove all
files from it, and put the differing files only into $output_dir.

The return value is the number of files copied.

=cut

sub copy_diff_only
{
    my ($old_dir, $new_dir, $output_dir, $verbose) = @_;
    if (mdate ($new_dir) < mdate ($old_dir)) {
        croak "$new_dir is older than $old_dir\n";
    }
    if (-d $output_dir) {
        rmtree ($output_dir);
    }
    mkpath $output_dir;
    my %data;
    $data{output_dir} = $output_dir;
    $data{count} = 0;
    directory_diff ($old_dir, $new_dir, 
                {
                    dir2_only => \&new_only_callback,
                    diff => \&diff_callback,
                    data => \%data,
                },
                    $verbose);
    return $data{count};
}

1;
