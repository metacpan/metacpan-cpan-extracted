#!env perl
use strict;
use diagnostics;

use Archive::Tar;
use File::Find;
use File::Basename;
use File::Spec;
use POSIX qw/EXIT_SUCCESS/;

my $destfile = shift;
my $destfile_basename = basename($destfile);

# print "Creating $destfile\n";

my @list;
find({ wanted => \&wanted, no_chdir => 1 }, @ARGV);
Archive::Tar->create_archive($destfile, COMPRESS_GZIP, @list);

exit(EXIT_SUCCESS);

sub wanted {
    my $dirname = $File::Find::dir;
    my $fullname = File::Spec->canonpath($File::Find::name);
    my $filename = File::Spec->abs2rel($fullname, $dirname) ;
    
    my ($volume, $directories, $file) = File::Spec->splitpath($fullname);
    if ($directories) {
        my @dirs = File::Spec->splitdir($directories);
        if (grep { ! ok($_) } @dirs) {
            # print "KO $fullname [directories: $directories]\n";
            return;
        }
    }
    if ($filename) {
        if (! ok($file)) {
            # print "KO $fullname [filename: $filename]\n";
            return;
        }
    }
    #
    # Ok
    #
    # print "[$destfile_basename] $fullname\n";
    push(@list, $fullname);
}

sub ok {
    return substr(shift, 0, 1) ne File::Spec->curdir;
}
