#!/usr/bin/perl -w

use IO::File;
use Getopt::Long ':config'=>'no_ignore_case';
use Pod::Usage;
use File::Basename qw(basename dirname);

use lib '.';
use Lingua::TT;
use Lingua::TT::DBFile;
use Lingua::TT::Enum;
use Fcntl;

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

##-- program vars
our $prog         = basename($0);
our $outfile_db   = undef; ##-- default: "$infile.db"
our $verbose      = 0;

our $pack_key = 'w'; ##-- UNUSED
our $pack_val = 'w';
our $eos_id   = undef;
our $append = 0; ##-- are we adding to an existing db?

our %dbf    = (type=>'BTREE', flags=>O_RDWR|O_CREAT, dbopts=>{});
our $cachesize = '128M';

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- Behavior
	   'eos-id|ei:i' => \$eos_id,

	   ##-- I/O
	   'db-hash|hash|dbh' => sub { $dbf{type}='HASH'; },
	   'db-btree|btree|bt|b' => sub { $dbf{type}='BTREE'; },
	   #'pack-key|pk|p:s' => \$pack_key,
	   'pack-value|pack-val|pack|pv|p:s' => \$pack_val,
	   'nopack|raw|P' => sub { $pack_key=$pack_val=undef; },
	   'append|add|a!' => \$append,
	   'truncate|trunc|clobber|t!' => sub { $append=!$_[1]; },
	   'db-cachesize|db-cache|cache|c=s' => \$cachesize,
	   'db-option|O=s' => $dbf{dbopts},
	   'output-db|odb|db|output|out|o=s' => \$outfile_db,
	  );

#pod2usage({-msg=>'Not enough arguments specified!', -exitval=>1, -verbose=>0}) if (@ARGV < 1);
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>1}) if ($man);

if ($version || $verbose >= 1) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## Subs: messages
##----------------------------------------------------------------------

# undef = vmsg($level,@msg)
#  + print @msg to STDERR if $verbose >= $level
sub vmsg {
  my $level = shift;
  print STDERR (@_) if ($verbose >= $level);
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- defaults
$outfile_db   = $ARGV[0].".db"  if (!defined($outfile_db));
#$pack_key .= '*' if ($pack_key && $pack_key !~ m/\*$/);

##-- open db
if (defined($cachesize) && $cachesize =~ /^\s*([\d\.\+\-eE]*)\s*([BKMGT]?)\s*$/) {
  my ($size,$suff) = ($1,$2);
  $suff = 'B' if (!defined($suff));
  $size *= 1024    if ($suff eq 'K');
  $size *= 1024**2 if ($suff eq 'M');
  $size *= 1024**3 if ($suff eq 'G');
  $size *= 1024**4 if ($suff eq 'T');
  $dbf{dbopts}{cachesize} = $size;
}
$dbf{flags} |=  O_TRUNC if (!$append);
our $dbf = Lingua::TT::DBFile->new(%dbf,file=>$outfile_db)
  or die("$prog: could not open or create DB file '$outfile_db': $!");
our $data = $dbf->{data};

push(@ARGV,'-') if (!@ARGV);
foreach $ngfile (@ARGV) {
  vmsg(1,"$prog: processing $ngfile...\n");

  our $ttin = Lingua::TT::IO->fromFile($ngfile,encoding=>undef)
    or die("$prog: open failed for '$ngfile': $!");
  our $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    next if (/^\%\%/ || /^\s*$/ || /__\$/); ##-- comment or blank line or moot-eos
    if (/^(.*)\t([^\t\r\n]*)$/) {
      ($key,$f)=($1,$2);
    } else {
      chomp;
      warn("$prog: could not parse n-gram line '$_' - skipping");
      next;
    }
    if (defined($val = $data->{$key})) {
      if ($pack_val) {
	$val = unpack($pack_val,$val);
	$data->{$key} = pack($pack_val,$val+$f);
      }
    }
    else {
      $data->{$key} = $pack_val ? pack($pack_val,$f) : $f;
    }
  }

  $ttin->close();
}

##-- cleanup
$dbf->close();

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-ngramdb-add.perl - add n-gram counts for tt files to a Berkely db

=head1 SYNOPSIS

 tt-ngramdb-add.perl [OPTIONS] ID_123_FILE(s)

 General Options:
   -help                     ##-- this help message
   -version                  ##-- print version and exit
   -verbose LEVEL            ##-- set verbosity (0..?)

 Counting Options:
   -eos-id ID                ##-- set EOS id (default=0)

 I/O Options:
   #-pack-key PACKFMT         ##-- set DB key pack format (default='w*')
   -pack-val PACKFMT         ##-- set DB key pack format (default='w')
   -append  , -truncate      ##-- do/don't append to existing file(s) (default:-add)
   -db-hash , -db-btree      ##-- set output DB type (default='HASH')
   -db-cache SIZE            ##-- set db cache size (with suffixes 'K','M','G','T')
   -db-option OPT=VAL        ##-- set DB option
   -output-db DBFILE         ##-- set output DB file (default=TT_FILE.db)

=cut

###############################################################
## OPTIONS AND ARGUMENTS
###############################################################
=pod

=head1 OPTIONS AND ARGUMENTS

Not yet written.

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

