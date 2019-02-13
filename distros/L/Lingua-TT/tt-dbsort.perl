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
our %dbf           = (type=>'RECNO', flags=>O_RDWR, encoding=>undef, dbopts=>{cachesize=>'128M'});

our $cmpstr = 'string'; ##-- comparison code string
our $external = 0;      ##-- use external sort?

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   #'man|m'  => \$man,
	   #'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- db options
	   'db-cachesize|db-cache|cache|c=s' => \$dbf{dbopts}{cachesize},
	   'db-reclen|reclen|rl=i' => \$dbf{dbopts}{reclen},
	   'db-bval|bval|bv=s'     => \$dbf{dbopts}{bval},
	   'db-option|dbo|O=s'    => $dbf{dbopts},
	   'db-encoding|dbe|de=s' => \$dbf{encoding},
	   'pack-value|pv=s' => \$dbf{pack_val},

	   ##-- sort options
	   'compare|comp|cmp|C=s' => \$cmpstr,
	   'compare-by-string|by-string|string|s' => sub { $cmpstr='string'; },
	   'compare-by-number|by-number|numeric|num|n' => sub { $cmpstr='numeric'; },
	   'external|ext|x!' => \$external,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'No DB file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

## $cmp = cmp_numeric()
sub cmp_numeric { return $a <=> $b; }

## $cmp = $cmp_string()
sub cmp_string { return $a cmp $b; }

## $cmp = cmp_numeric_ext()
sub cmp_numeric_ext { return $Sort::External::a <=> $Sort::External::b; }

## $cmp = $cmp_string_ext()
sub cmp_string_ext { return $Sort::External::a cmp $Sort::External::b; }

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- compile sort sub
our ($cmpsub);
if (!defined($cmpsub = UNIVERSAL::can('main',"cmp_${cmpstr}".($external ? '_ext' : '')))) {
  $cmpsub = eval qq{sub {$cmpstr}};
  die("$prog: failed to compile comparison subroutine {$cmpstr}: $@")
    if (!defined($cmpsub) || $@);
}

##-- open db
my $dbfile = shift(@ARGV);
our $dbf = Lingua::TT::DBFile->new(%dbf,file=>$dbfile)
  or die("$prog: could not open DB file '$dbfile': $!");
our $data = $dbf->{data};

##-- sort
if (!$external) {
  ##-- sort in-memory
  @$data = sort $cmpsub @$data;
} else {
  require Sort::External
    or die("$prog: failed to load Sort::External module: $@");
  my $sortex = Sort::External->new(
				   #mem_threshold  => $dbf->{dbinfo}{cachesize},
				   #cache_size     => $dbf->{dbinfo}{cachesize},
				   sortsub        => $cmpsub,
				   #working_dir    => undef,
				  )
    or die("$prog: failed to create Sort::External object: $!");

  ##-- feed items
  my $tied = $dbf->{tied};
  my ($key,$val,$status);
  for ($status=$tied->seq($key,$val,R_FIRST); $status==0; $status=$tied->seq($key,$val,R_NEXT)) {
    $sortex->feed($val);
  }
  $sortex->finish();

  ##-- re-open db and insert
  undef $data;
  undef $tied;
  $dbf->close();
  $dbf->open($dbfile, flags=>($dbf->{flags}|O_TRUNC))
    or die("$prog: failed to truncate DB-file $dbfile: $!");
  $tied = $dbf->{tied};
  while (defined($val=$sortex->fetch)) {
    $tied->push($val);
  }
}

##-- close safely
undef($data);
$dbf->close;


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-dbsort.perl - sort a DB recno array

=head1 SYNOPSIS

 tt-dbsort.perl [OPTIONS] DB_RECNO_FILE

 General Options:
   -help

 DB Options:
  -cache SIZE             ##-- set DB cache size (with suffixes K,M,G)
  -bval BVAL              ##-- separator string for variable-length -recno arrays
  -reclen RECLEN          ##-- record size in bytes for fixed-length -recno arrays
  -db-option OPT=VAL      ##-- set DB_File option

 Sort Options:
  -compare CODE           ##-- set comparison subroutine CODE
  -by-string              ##-- sort by string value (default; like -compare='$a cmp $b')
  -by-number              ##-- sort by numeric value (like -compare='$a <=> $b')
  -pack-val PACKAS        ##-- set pack/unpack template for DB values
  -[no]external           ##-- do/don't use Sort::External to sort on disk

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
