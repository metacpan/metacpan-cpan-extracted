package Directory::Diff;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/ls_dir get_only get_diff directory_diff
                default_diff default_dir_only/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
our $VERSION = '0.07';
use Carp qw/carp croak/;
use Cwd 'getcwd';
use File::Compare 'compare';

sub ls_dir
{
    my ($dir, $verbose) = @_;
    if (! $dir || ! -d $dir) {
        croak "No such directory '$dir'";
    }
    my %ls;
    if (! wantarray) {
        die "bad call";
    }
    my $original_dir = getcwd ();
    chdir ($dir);
    opendir (my $dh, ".");
    my @files = readdir ($dh);
    for my $file (@files) {
        if ($file eq '.' || $file eq '..') {
            next;
        }
        if (-f $file) {
            $ls{"$file"} = 1;
        }
        elsif (-d $file) {
            my %subdir = ls_dir ($file);
            for my $subdir_file (keys %subdir) {
                $ls{"$file/$subdir_file"} = 1;
            }
            $ls{"$file/"} = 1;
        }
        else {
            warn "Skipping unknown type of file $file.\n";
        }
    }
    closedir ($dh);
    chdir ($original_dir);
    if ($verbose) {
        for my $k (keys %ls) {
            print "$k $ls{$k}\n";
        }
    }
    return %ls;
}

sub get_only
{
    my ($ls_dir1_ref, $ls_dir2_ref, $verbose) = @_;

    if (ref ($ls_dir1_ref) ne "HASH" ||
	ref ($ls_dir2_ref) ne "HASH") {
        croak "get_only requires hash references as arguments";
    }
    my %only;

    # d1e = directory one entry
    
    for my $d1e (keys %$ls_dir1_ref) {
        if (! $ls_dir2_ref->{$d1e}) {
            $only{$d1e} = 1;
            if ($verbose) {
                print "$d1e is only in first directory.\n";
            }
        }
    }
    if (! wantarray) {
        croak "bad call";
    }
    return %only;
}

sub get_diff
{
    my ($dir1, $ls_dir1_ref, $dir2, $ls_dir2_ref) = @_;
    if (ref ($ls_dir1_ref) ne "HASH" ||
	ref ($ls_dir2_ref) ne "HASH") {
        croak "get_diff requires hash references as arguments 2 and 4";
    }
    my %different;
    for my $file (keys %$ls_dir1_ref) {
        my $d1file = "$dir1/$file";
        if ($ls_dir2_ref->{$file}) {
            if (! -f $d1file) {
#                croak "Bad file / directory combination $d1file";
                next;
            }
            my $d2file = "$dir2/$file";
	    if (compare ($d1file, $d2file) != 0) {
		$different{$file} = 1;
            }
        }
    }
    if (! wantarray) {
        croak "Bad call";
    }
    return %different;
}

sub directory_diff
{
    my ($dir1, $dir2, $callback_ref, $verbose) = @_;
    if (! $dir1 || ! $dir2) {
        croak "directory_diff requires two directory names";
    }
    if (! -d $dir1) {
	croak "directory_diff: first directory '$dir1' does not exist";
    }
    if (! -d $dir2) {
	croak "directory_diff: second directory '$dir2' does not exist";
    }
    if ($verbose) {
        print "Directory diff of $dir1 and $dir2 in progress ...\n";
    }
    if (! $callback_ref) {
        croak "directory_diff: no callbacks supplied";
    }
    if (ref $callback_ref ne "HASH") {
        croak "directory_diff: callback not hash reference";
    }
    my %ls_dir1 = ls_dir ($dir1);
    my %ls_dir2 = ls_dir ($dir2);
    # Data to pass to called back functions.
    my $data = $callback_ref->{data};
    # Call back a function on each file which is only in directory 1.
    my $d1cb = $callback_ref->{dir1_only};
    if ($d1cb) {
        # Files which are only in directory 1.
        my %dir1_only = get_only (\%ls_dir1, \%ls_dir2, $verbose);
        for my $file (keys %dir1_only) {
            &{$d1cb} ($data, $dir1, $file, $verbose);
        }
    }
    # Call back a function on each file which is only in directory 2.
    my $d2cb = $callback_ref->{dir2_only};
    if ($d2cb) {
        # Files which are only in directory 2.
        my %dir2_only = get_only (\%ls_dir2, \%ls_dir1, $verbose);
        for my $file (keys %dir2_only) {
            &{$d2cb} ($data, $dir2, $file, $verbose);
        }
    }
    # Call back a function on each file which is in both directories
    # but different.
    my $diff_cb = $callback_ref->{diff};
    if ($diff_cb) {
        # Files which are in both directories but are different.
        my %diff_files = get_diff ($dir1, \%ls_dir1, $dir2, \%ls_dir2, $verbose);
        for my $file (keys %diff_files) {
            &{$diff_cb} ($data, $dir1, $dir2, $file, $verbose);
        }
    }
    if (defined wantarray) {
        carp "directory_diff does not return a meaningful value";
    }
    return;
}

sub default_dir_only
{
    my ($data, $dir, $file) = @_;
    print "File '$file' is only in '$dir'.\n";
}

sub default_diff
{
    my ($data, $dir1, $dir2, $file) = @_;
    print "File '$file' is different between '$dir1' and '$dir2'.\n";
}

1;

