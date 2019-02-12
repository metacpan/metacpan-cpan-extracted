#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::DBFile;
use DB_File;
use Fcntl;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $prog = basename($0);
our $VERSION  = "0.11";

our $include_empty = 0;
our %dbf           = (type=>'GUESS', flags=>O_RDWR, encoding=>undef, dbopts=>{cachesize=>'128M'});

our $outfile  = undef; ##-- default: $infile.inv

our $weights = 0; ##-- keep weights in value part of dict?

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
	   'db-guess|guess|dbg' => sub { $dbf{type}='GUESS'; },
	   'db-cachesize|db-cache|cache|c=s' => \$dbf{dbopts}{cachesize},
	   'db-option|O=s' => $dbf{dbopts},

	   ##-- misc
	   'weights|weight|w!' => \$weights, ##-- if true, weights will be parsed and appended to dict values

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|db-encoding|dbe|e=s' => \$dbf{encoding},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'No input DB file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- input db
our $idbfile = shift(@ARGV);
our $idbf = Lingua::TT::DBFile->new(%dbf,file=>$idbfile)
  or die("$prog: could not open input DB file '$idbfile': $!");
our $idata = $idbf->{data};
our $itied = $idbf->{tied};

##-- output db
our $odbfile = $outfile;
$odbfile = "$idbfile.inv" if (!defined($odbfile));
$dbf{flags} |= (O_CREAT|O_TRUNC);
our $odbf = Lingua::TT::DBFile->new(%dbf,file=>$odbfile)
  or die("$prog: could not open input or create output DB file '$odbfile': $!");
our $odata = $odbf->{data};

##-- dump DB
my ($key,$val,$status,$line);
$key=$val=0;
for ($status = $itied->seq($key,$val,R_FIRST);
     $status == 0;
     $status = $itied->seq($key,$val,R_NEXT))
  {
    @a_in = split(/\t/,$val);
    foreach (@a_in) {
      $keyw = $key.($weights && s/(\s*\<[\+\-\d\.eE]+\>\s*)$// ? $1 : '');
      if (exists($odata->{$_})) {
	$odata->{$_} .= "\t".$keyw;
      } else {
	$odata->{$_} = $keyw;
      }
    }
  }


undef($idata);
undef($itied);
undef($odata);
$idbf->close;
$odbf->close;


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-db-invert.perl - invert DB dict files

=head1 SYNOPSIS

 tt-db-invert.perl [OPTIONS] DB_FILE

 General Options:
   -help

 DB Options:
  -hash   , -btree      ##-- select DB output type (default='BTREE')
  -cache SIZE           ##-- set DB cache size (with suffixes K,M,G)
  -db-option OPT=VAL    ##-- set DB_File option

 I/O Options:
   -weight , -noweight  ##-- do/don't keep FST-style weight suffixes in value part (default=don't)
   -output FILE         ##-- default: STDOUT
   -encoding ENCODING   ##-- DB encoding (default: raw)

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
