#! /usr/bin/env perl
#
# file_unpack2.pl -- Demo of File::Unpack2 features.
# 
# (C) 2010-2014, jnw@cpan.org, all rights reserved.
# Distribute under the same license as Perl itself.
#
# 2010-06-29, jw -- initial draught
# 2010-08-03, jw -- fixed -v.
# 2010-08-31, jw -- fixed -q with -m.
# 2010-09-01, jw -- added --list
# 2011-01-03, jw -- allow multiple arguments. Improved -m
# 2011-03-08, jw -- fixed usage of -l, added -p.
# 2011-04-21, jw -- better format error messages, and stop after error.
# 2011-05-12, jw -- added -n for no_op
# 2012-02-16, jw -- added -A for archive_name_as_dir.
#                   using {log_type} == 'PLAIN' unless -L
# 2013-01-25, jw -- added -f for follow_file_symlinks.
# 2014-07-21, jw -- default to one_shot unless named *deep*.

use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use FindBin;
use lib "$FindBin::RealBin/blib/lib";
use File::Unpack2;

my $version = $File::Unpack2::VERSION;
my @exclude;
my $exclude_vcs = 1;
my $help;
my $mime_only;
my $list_only;
my $list_perlish;
my @mime_helper_dirs;

my %opt = ( verbose => 1, maxfilesize => '2.6G', one_shot => 1, no_op => 0, world_readable => 0, log_fullpath => 0, archive_name_as_dir => 0, follow_file_symlinks => 0, log_type => 'PLAIN');

$opt{one_shot} = 0 if $0 =~ m{deep[^/]*$};

push @mime_helper_dirs, "$FindBin::RealBin/helper" if -d "$FindBin::RealBin/helper";

GetOptions(
	"verbose|v+"   	=> \$opt{verbose},
	"version|V"    	=> sub { print "$version\n"; exit },
	"quiet"        	=> sub { $opt{verbose} = 0; },
	"destdir|D|C=s" => \$opt{destdir},
	"exclude|E=s"  	=> \@exclude,
	"exclude-vcs!" 	=> \$exclude_vcs,
	"vcs|include-vcs!" 	=> sub { $exclude_vcs = !$_[1]; },
	"help|?"       		=> \$help,
	"logfile|L=s"  		=> \$opt{logfile},
	"fullpath-log|F" 	=> \$opt{log_fullpath},
	"one-shot|one_shot|1"   => \$opt{one_shot},
	"deep|recursive"        => sub { $opt{one_shot} = 0; },
	"mimetype|m+"  		=> \$mime_only,
	"no_op|no-op|noop|n+" 	=> \$opt{no_op},
	"list-helpers|l+" 	=> \$list_only,
	"print-helpers|p+" 	=> \$list_perlish,
	"params|P=s"		=> \%{$opt{log_params}},
	"maxfilesize=s"		=> \$opt{maxfilesize},
	"use-mime-helper-dir|I|u=s" 		=> \@mime_helper_dirs,
	"world-readable|world_readable|R+" 	=> \$opt{world_readable},
	"archive-dirs|archive_dirs|A"		=> \$opt{archive_name_as_dir},
	"follow-file-symlinks|f+" 		=> \$opt{follow_file_symlinks},
) or $help++;

@mime_helper_dirs = split(/,/,join(',',@mime_helper_dirs));
my $archive = shift or $list_perlish or $list_only or $help++;

pod2usage(-verbose => 1, -msg => qq{
file_unpack2 V$version Usage: 

$0 [options] input.tar.gz ...
$0 [options] input/ ...
$0 -l
$0 -p

Valid options are:
 -v	Be more verbose. Default: $opt{verbose}.
 -q     Be quiet, not verbose.

 -A --archive_dirs
	Use exact archive names as subdirectories, modified by appending '._*'
	to avoid collisions.  Default: use truncated and/or modified archive
	names. E.g. example.zip is per default unpacked into 'example/'. With
	-A, it is unpacked into 'example.zip._/'.  This does not apply for
	single file archives. They are always unpacked without a directory.

 -C dir
 -D --destdir dir
        Directory, where to place the output file or directory.
	A subdirectory is created, if there are more than one files to unpack.
	Default: current dir.

 -E --exclude glob.pat
 	Specify files and directories that are not unpacked.
	This option can be specified multiple times.

 -F --fullpath-log
 	Always use full path names in logfile. Default: 
	unpacked path names are written relative to destdir.

 --exclude-vcs	--no-exclude-vcs 
 --include-vcs  --no-include-vcs --vcs --no-vcs
 	Group switch for directory glob patterns of most version control systems.
	This affects at least SCCS, RCS, CVS, .svn, .git, .hg, .osc .
	The logfile has a {skipped}{exclude} counter.
        Default: exclude-vcs=$exclude_vcs .

 -1 --one-shot
 	Make unpacker non-recursive. Perform one level of unpacking only.
	This is the default unless the name of the unpacker contains the substring 'deep'.

 --deep
 --recursive
 	Make unpacker recursive. Perform all possible levels of unpacking.
	This is the default if the name of the unpacker contains the substring 'deep'.

 -h --help -?
        Print this online help.
 
 -L --logfile  file.log
 	Specify a logfile, where freshly unpacked files are reported.
	When a logfile is specified, its format is JSON; 
	default is STDOUT with format PLAIN.
 
 -l --list-helpers
        Overview of mime-type patterns and their helper commands.

 -p --print-helpers
 	List all builtin mime-helpers and all external mime-helpers as 
	a nested Perl datastructure.

 -P --param KEY=VALUE
 	Place additional params into the log file.

 --maxfilesize size
        Truncate an unpacked file, if it gets larger than the specified size.
	Size can be specified as bytes (plain integer), kilo-, mega-, giga-, or 
	tera-bytes (suffix K,M,G,T). Default: $opt{maxfilesize}.

 -m --mimetype
        Do not unpack, just report mimetype of the archive. Output format is 
	similar to '/usr/bin/file -i', unless -q or -v are given.
	With -v, the unpacker command is also printed.

 -R --world-readable
 	Make the unpacked tree world readable. Default: user readable.

 -n --no-op
 	Do not unpack. Print the first unpack command only.

 -u --use-mime-helper-dir dir
 	Include an additonal directory of mime helpers.
	Useable multiple times. Later additions take precedence.

 -f --follow-file-symlinks
 	Follow (and unpack) symlinks that point to files (or archives).
	Used once, we follow only symlinks that are present before unpacking starts.
	Used twice, we also follow symlinks that were unpacked from an archive.
	Symlinks to directories or other (dangling) symlinks are always ignored.
	The logfile has a {skipped}{symlink} counter.
        Default: skip all symlinks.

}) if $help;

if (defined $opt{logfile})
  {
    $opt{log_type} = 'JSON';
    $opt{logfile} = \*STDOUT if $opt{logfile} eq '-';
  }

$opt{logfile} ||= '/dev/null' if $list_only or $list_perlish or $mime_only or $opt{no_op};
my $u = File::Unpack2->new(%opt);
my $list = $u->mime_helper_dir(@mime_helper_dirs);

if ($list_perlish)
  {
    print Dumper $list;
    exit 0;
  }

if ($list_only)
  {
    printf @$_ for $u->list();
    exit 0;
  }

if ($mime_only)
  {
    $u->{verbose}-- if $u->{verbose};
    if ($u->{verbose} > 1)
      {
        print "using File::LibMagic $File::LibMagic::VERSION\n" if defined $File::LibMagic::VERSION;
        print "using File::MimeInfo::Magic $File::MimeInfo::Magic::VERSION\n" if defined $File::MimeInfo::Magic::VERSION;
        print "using File::Unpack2 $File::Unpack2::VERSION\n" if defined $File::Unpack2::VERSION;
      }

    while (defined $archive)
      {
	my $m = $u->mime($archive);
	my ($h,$r) = $u->find_mime_helper($m);
	if ($opt{verbose} > 1)
	  {
	    print "$archive: ", Dumper $m;
	    print File::Unpack2::fmt_run_shellcmd($h) . "\n";
	  }
	elsif ($opt{verbose} == 1)
	  {
	    print "$archive: $m->[0]; charset=$m->[1]\n";
	  }
	else
	  {
	    print "$m->[0]\n";
	  }
        $archive = shift;
      }
    exit 0;
  }

while (defined $archive and !$u->{error}) 
  {
    $u->exclude(vcs => $exclude_vcs);
    $u->exclude(add => \@exclude) if @exclude;

    $u->unpack($archive);
    map { print STDERR "ERROR: $_\n" } @{$u->{error}} if $u->{error};
    $archive = shift;
    if (defined($archive))
      {
        if (defined $opt{logfile} and -f $opt{logfile})
	  {
            warn "File::Unpack2($archive): overwriting previous logfile $opt{logfile} in 3 seconds. Press CTRL-C to abort.\n" if defined $archive;
	    sleep(3);
	  }
        # reload, for the next round. (new() opens the logfile, unpack() closese it.)
        $u = File::Unpack2->new(%opt);
        $u->mime_helper_dir(@mime_helper_dirs);
      }
  }

# delete $u->{json};
# die "$0: " . Dumper $u;
