package Geo::PostalCode::InstallDB;

=head1 NAME

Geo::PostalCode::InstallDB - Create and install a new location database for Geo::PostalCode.

=head1 SYNOPSIS

  use Geo::PostalCode::InstallDB;

  Geo::PostalCode::InstallDB->install(zipdata => 'Geo-PostalCode_19991101.txt',
                                      db_dir  => '.')
    or die "Couldn't install DB!\n";

=head1 DESCRIPTION

This class contains only one useful method: C<install>.  It takes a
text file, the name of which should be given in the C<zipdata>
parameter, and converts it into three Berkeley database files
(postalcode.db, latlon.db, and city.db) which will be installed in the
directory given as the C<db_dir> parameter.

The format of these files is a series of lines, the first of which is
skipped.  Each has five tab-seperated values:

  postal_code	lat	lon	city	state

=head1 SEE ALSO

L<Geo::PostalCode>, L<http://www.census.gov/geo/www/tiger/zip1999.html>.

=cut

use strict;
use warnings;
use Geo::PostalCode; our $VERSION = $Geo::PostalCode::VERSION;
use DB_File;
use FileHandle;
use POSIX;
use File::Spec;

use constant ZIPCODEDB => 'postalcode.db';
use constant CELLDB    => 'latlon.db';
use constant CITYDB    => 'city.db';

sub install
{
  my $class = shift;
  my %o = @_;
  my(%zipcode, %cell, %city, %lat, %lon);
  my $dir;

  $o{zipdata}
      or die "Missing required parameter zipdata";
  my $zip = FileHandle->new($o{zipdata}, "r")
      or die "Couldn't open '$o{zipdata}': $!\n";
  if ($o{db_dir})
  {
    $dir = $o{db_dir};
    if (!mkdir($dir))
    {
      die "Couldn't mkdir($dir): $!\n"
	  unless ($! eq 'File exists')
    }
  }
  foreach my $db (ZIPCODEDB, CELLDB, CITYDB)
  {
    if (!unlink(File::Spec->catfile($dir,"$db.tmp")))
    {
      die "Couldn't unlink '$db.tmp': $!\n"
	  unless ($! eq 'No such file or directory')
    }
  }

  tie (%zipcode, 'DB_File', File::Spec->catfile($dir,ZIPCODEDB.".tmp"), O_RDWR|O_CREAT, 0666, $DB_BTREE)
      or die "cannot tie %zipcode to file";
  tie (%cell,    'DB_File', File::Spec->catfile($dir,CELLDB.".tmp"),    O_RDWR|O_CREAT, 0666, $DB_BTREE)
      or die "cannot tie %cell to file";
  tie (%city,    'DB_File', File::Spec->catfile($dir,CITYDB.".tmp"),    O_RDWR|O_CREAT, 0666, $DB_BTREE)
    or die "cannot tie %city to file";

  # Skip header line
  <$zip>;
  while (<$zip>)
  {
    chomp;
    my ($zipcode, $lat, $lon, $city, $state);

    if ($o{is_csv}) {
	# strip enclosing quotes from fields
	($zipcode, $city, $state, $lat, $lon) =
	    map { substr($_, 1, length($_) - 2) } 
	split(",");

	# the CSV format has mixed case cities
	$city = uc($city);
    } else {
	($zipcode, $lat, $lon, $city, $state) = split("\t");
    }

    $zipcode{$zipcode} = "$lat,$lon,$city,$state";
    $lat{$zipcode} = $lat;
    $lon{$zipcode} = $lon;
    
    my $int_lat = floor($lat);
    my $int_lon = floor($lon);
    
    $cell{"$int_lat-$int_lon"} .= $zipcode;
    $city{"$state$city"} .= $zipcode;
  }
  
  foreach my $k (keys %city) {
    my $v = $city{$k};
    my @postal_codes = ($v =~ m!(.{5})!g);
    next unless @postal_codes;
    my ($tot_lat, $tot_lon, $count) = (0,0,0,0);
    for (@postal_codes) {
      $tot_lat += $lat{$_};
      $tot_lon += $lon{$_};
      $count++;
    }
    my $avg_lat = sprintf("%.5f",$tot_lat/$count);
    my $avg_lon = sprintf("%.5f",$tot_lon/$count);
    $city{$k} = "$v|$avg_lat|$avg_lon";
  }

  untie %zipcode;
  untie %cell;
  untie %city;

  foreach my $db (ZIPCODEDB, CELLDB, CITYDB)
  {
    rename(File::Spec->catfile($dir,"$db.tmp"),File::Spec->catfile($dir,$db))
	or die "Couldn't rename '$db.tmp' to '$db': $!\n";
  }
  1;
}

1;
