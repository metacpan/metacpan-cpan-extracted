#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::DBFile;
use DB_File;
use Fcntl;
use Encode qw(encode decode);

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $prog = basename($0);
our $VERSION  = "0.12";

our $include_empty = 0;
our %dbf           = (type=>'GUESS', flags=>O_RDONLY, encoding=>undef, dbopts=>{cachesize=>'128M'});
#our $dbencoding    = undef;

our $oencoding = undef;
our $oformat_str = undef;
our $outfile  = '-';

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
	   'db-btree|btree|dbb' => sub { $dbf{type}='BTREE'; },
	   'db-recno|recno|dbr' => sub { $dbf{type}='RECNO'; },
	   'db-guess|guess|dbg' => sub { $dbf{type}='GUESS'; },
	   'db-cachesize|db-cache|cache|c=s' => \$dbf{dbopts}{cachesize},
	   'db-reclen|reclen|rl=i' => \$dbf{dbopts}{reclen},
	   'db-bval|bval|bv=s'     => \$dbf{dbopts}{bval},
	   'db-option|dbo|O=s' => $dbf{dbopts},
	   'db-encoding|dbe|de=s' => \$dbf{encoding},

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'output-format|format|of|F=s' => \$oformat_str,
	   'output-encoding|oencoding|oe=s' => \$oencoding,
	   'encoding|e=s' => sub {$dbf{encoding}=$oencoding=$_[1]},
	   'pack-key|pk=s' => \$dbf{pack_key},
	   'pack-value|pv=s' => \$dbf{pack_val},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'No DB file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

sub oformat_default { $_[0]."\t".$_[1]; }
my $oformat_sub = \&oformat_default;

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- output formatting code
if (defined($oformat_str)) {
  $oformat_sub = eval qq{sub {$oformat_str}};
  die("$prog: ERROR: failed to compile user-supplied formatting code {$oformat_str}".($@ ? ": $@" : ''))
    if ($@ || !$oformat_sub);
}

##-- open db
my $dbfile = shift(@ARGV);
our $dbf = Lingua::TT::DBFile->new(%dbf,file=>$dbfile)
  or die("$prog: could not open DB file '$dbfile': $!");
our $data = $dbf->{data};
our $tied = $dbf->{tied};

##-- open output handle
our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$oencoding)
  or die("$0: open failed for '$outfile': $!");
our $outfh = $ttout->{fh};

##-- dump DB
my ($key,$val,$status,$line);
$key=$val=0;
for ($status = $tied->seq($key,$val,R_FIRST);
     $status == 0;
     $status = $tied->seq($key,$val,R_NEXT))
  {
    #$line = $key."\t".$val."\n";
    #$line = decode($dbencoding,$line) if (defined($dbencoding));
    #$outfh->print($line);
    ##--
    $outfh->print( $oformat_sub->($key,$val), "\n" );
  }

undef($data);
undef($tied);
$dbf->close;
$ttout->close;


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-db2dict.perl - convert DB dictionary to text

=head1 SYNOPSIS

 tt-db2dict.perl [OPTIONS] DB_FILE

 General Options:
   -help

 DB Options:
  -hash , -btree , -recno ##-- select DB output type (default=GUESS)
  -guess                  ##-- guess DB type (default)
  -cache SIZE             ##-- set DB cache size (with suffixes K,M,G)
  -bval BVAL              ##-- separator string for variable-length -recno arrays
  -reclen RECLEN          ##-- record size in bytes for fixed-length -recno arrays
  -db-option OPT=VAL      ##-- set DB_File option
  -db-encoding ENC        ##-- set DB internal encoding (default: null)

 I/O Options:
  -output FILE            ##-- default: STDOUT
  -output-format CODE     ##-- code to format output line (for args ($key,$val))
  -output-encoding ENC    ##-- output encoding (default: null)
  -encoding ENC           ##-- alias for -db-encoding=ENC -output-encoding=ENC
  -pack-key PACKAS        ##-- set pack/unpack template for DB keys
  -pack-val PACKAS        ##-- set pack/unpack template for DB values

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
