#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::DBFile;
use Fcntl;
use File::Copy;
use File::Temp;
use Encode qw(encode decode);

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $prog = basename($0);
our $VERSION  = "0.12";

our $iencoding = undef;

our $include_empty = 0;
our %dbf           = (type=>'BTREE', flags=>O_RDWR|O_CREAT, encoding=>undef, dbopts=>{cachesize=>'32M'});
our $outfile  = undef; ##-- default: INFILE.db
our $tmpdir   = undef; ##-- build in temp directory (e.g. tmpfs)?
our $parse_str = undef; ##-- input-parsing code

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   #'man|m'  => \$man,
	   #'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- db options
	   'db-hash|hash|dbh' => sub { $dbf{type}='HASH'; },
	   'db-btree|btree|bt|b' => sub { $dbf{type}='BTREE'; },
	   'db-recno|recno|dbr' => sub { $dbf{type}='RECNO'; },
	   'append|add|a!' => \$append,
	   'truncate|trunc|clobber|t!' => sub { $append=!$_[1]; },
	   'db-cachesize|db-cache|cache|c=s' => \$dbf{dbopts}{cachesize},
	   'db-pagesize|db-page|db-psize|page|psize|p=s' => \$dbf{dbopts}{psize},
	   'db-reclen|reclen|rl=i' => \$dbf{dbopts}{reclen},
	   'db-bval|bval|bv=s'     => \$dbf{dbopts}{bval},
	   'db-option|dbo|O=s' => $dbf{dbopts},
	   'include-empty-analyses|include-empty|empty!' => \$include_empty,

	   ##-- I/O
	   'input-parse|parse|P=s' => \$parse_str,
	   'input-encoding|iencoding|ie=s' => \$iencoding,
	   'output-db|output|out|o|odb|db=s' => \$outfile,
	   'output-db-encoding|db-encoding|dbe|oe=s' => \$dbf{encoding},
	   'encoding|e=s' => sub {$iencoding=$dbf{encoding}=$_[1]},
	   'pack-key|pk=s' => \$dbf{pack_key},
	   'pack-value|pv=s' => \$dbf{pack_val},
	   'tempdir|tmpdir|temp|tmp|td=s' => \$tmpdir,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'No dictionary file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

sub parse_default { split(/\t/,$_,2); }
my $parse_sub = \&parse_default;

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

push(@ARGV,'-') if (!@ARGV);

##-- parsing
if ($parse_str) {
  $parse_sub = eval qq{sub {$parse_str}};
  die("$prog: ERROR: failed to compile user-supplied value-parser code {$parse_str}".($@ ? ": $@" : ''))
    if ($@ || !$parse_sub);
}

##-- defaults
$outfile    = $ARGV[0].".db"  if (!defined($outfile));
our $dbfile = $outfile;
if (defined($tmpdir)) {
  ##-- build in temp dir, then copy
  my ($tmpfh);
  ($tmpfh,$dbfile) = File::Temp::tempfile("ttdbXXXX", DIR=>$tmpdir, SUFFIX=>'.db', UNLINK=>1);
  $tmpfh->close();

  if (-e $outfile && !$append) {
    File::Copy::copy($outfile,$dbfile)
	or die("$prog: could not copy original '$outfile' to '$dbfile' for append: $!");
  }
  #print STDERR "$prog: using temporary file $dbfile\n";
}

##-- open db
$dbf{flags} |=  O_TRUNC if (!$append);
our $dbf = Lingua::TT::DBFile->new(%dbf)
  or die("$prog: could not create TT::DBFile object: $!");
$dbf->open($dbfile)
  or die("$prog: could not open DB file '$dbfile': $!");
our $data = $dbf->{data};
our $tied = $dbf->{tied};

##-- process input files
my ($key,$val);
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$iencoding)
    or die("$0: open failed for '$infile': $!");
  $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    next if (/^%%/ || /^$/);
    chomp;
    ($key,$val) = $parse_sub->();
    next if (!defined($key) || (!defined($val) && !$include_empty)); ##-- no entry for unanalyzed input
    $tied->put($key,$val)==0
      or die("$prog: DB_File::put() failed: $!");
  }
  $ttin->close;
}

undef $tied;
undef $data;
$dbf->close;

if (defined($tmpdir)) {
  ##-- copy to final output
  File::Copy::copy($dbfile,$outfile)
      or die("$prog: could not copy temporary '$dbfile' to final '$outfile': $!");
}

END {
  unlink($dbfile) if (defined($tmpdir) && defined($dbfile));
}

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-dict2db.perl - convert a text dictionary to a DB_File

=head1 SYNOPSIS

 tt-dict2db.perl OPTIONS [TT_DICT_FILE(s)]

 General Options:
   -help

 DB Options:
  -hash , -btree , -recno ##-- select DB output type (default='BTREE')
  -append , -truncate     ##-- do/don't append to existing db (default=-append)
  -empty  , -noempty      ##-- do/don't create records for empty analyses
  -cache SIZE             ##-- set DB cache size (with suffixes K,M,G)
  -page SIZE              ##-- set DB page size (with suffixes K,M,G)
  -bval BVAL              ##-- separator string for variable-length -recno arrays
  -reclen RECLEN          ##-- record size in bytes for fixed-length -recno arrays
  -db-option OPT=VAL      ##-- set DB_File option
  -db-encoding ENC        ##-- set DB internal encoding (default: null)

 I/O Options:
   -input-parse CODE      ##-- parse input using CODE (parse $_, returns ($key,$val))
   -input-encoding ENC    ##-- set input encoding (default: null)
   -encoding ENC          ##-- alias for -input-encoding=ENC -db-encoding=ENC
   -pack-key PACKAS       ##-- set pack/unpack template for DB keys
   -pack-val PACKAS       ##-- set pack/unpack template for DB values
   -output FILE           ##-- default: STDOUT
   -tmpdir DIR            ##-- build temporary DB in DIR then copy (e.g. tmpfs)

=cut

###############################################################
## OPTIONS
###############################################################
=pod

=head1 OPTIONS

=cut

###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item -help

Display a brief help message and exit.

=item -version

Display version information and exit.

=item -verbose LEVEL

Set verbosity level to LEVEL.  Default=1.

=back

=cut


###############################################################
# Other Options
###############################################################
=pod

=head2 Other Options

=over 4

=item -someoptions ARG

Example option.

=back

=cut


###############################################################
# Bugs and Limitations
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

perl(1).

=cut
