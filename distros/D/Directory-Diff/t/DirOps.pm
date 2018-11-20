package DirOps;
use parent Exporter;
our @EXPORT = qw/rmdirs mkdirs rm_mk_dirs create_file/;
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Carp;
use File::Path 'remove_tree';

sub rmdirs
{
    for (@_) {
	if (-d $_) {
	    remove_tree ($_);
	}
        die if -d $_;
    }
}

sub mkdirs
{
    for (@_) {
        die if -d $_;
        mkdir $_ or die $!;
    }
}

sub rm_mk_dirs
{
    rmdirs (@_);
    mkdirs (@_);
}

sub create_file 
{
    my ($file_name, $dir_name, $contents) = @_;
    my $path = "$dir_name/$file_name";
    die "$path exists" if -f $path;
    open my $output, ">:encoding(utf8)", $path or die "$path: $!";
    print $output $contents;
    close $output or die $!;
}

1;
