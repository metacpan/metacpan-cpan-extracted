package Geo::Postcode::Location;

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD $datafile $tablename $dbh $broadosgrid $fineosgrid $units $pi);
use DBI;

$VERSION = '0.12';
$tablename = "postcodes";
$units = "km";
$pi = 3.14159;
$datafile = undef;
$dbh = undef;

=head1 NAME

Geo::Postcode::Location - helper class for Geo::Postcode that handles grid reference lookups

=head1 SYNOPSIS

  $Geo::Postcode::Location::datafile = '/usr/local/lib/postcodes.db';
  my ($x, $y) = Geo::Postcode->coordinates('EC1R 8BB');

=head1 DESCRIPTION

Geo::Postcode::Location holds the gridref-lookup functions of Geo::Postcode. It is separated here to minimise the footprint of the main module and to facilitate subclassing.

It doesn't really have a useful direct interface, since it requires an object of Geo::Postcode (or a subclass) and is most easily reached through that object, but it does have a couple of configuration variables and there is method documentation here for anyone interested in subclassing it or changing the data source.

=head1 GRIDREF DATA

There are at least three ways to supply your own gridref data.

=over

=item * replace the data file

If you can get your data into a SQLite file, all you have to do is set the either C<Geo::Postcode::Location::datafile> or $ENV{POSTCODE_DATA} to the full path to your data file:

  $Geo::Postcode::Location::datafile = '/home/site/data/postcodes.db';
  # or
  PerlSetEnv POSTCODE_DATA /home/site/data/postcodes.db

I've included (in ./useful) an idiot script that I use to turn .csv data into a SQLite file suitable for use with this module.

=item * replace the database handle

The query that we use to retrieve location information is very simple, and should work with any DBI database handle. If your application already makes available a suitable database handle, or you would like to create one externally and make sure it is reused, it should just work:

  $Geo::Postcode::Location::dbh = $my_dbh;
  $Geo::Postcode::Location::tablename = 'postcodedata';
  my ($x, $y) = Geo::Postcode->coordinates('EC1Y 8PQ');

If running under mod_perl, you probably don't want to share the handle like that. You can achieve the same thing with instance methods and avoid side-effects, but you have to make the calls at the right time:

  my $postcode = Geo::Postcode->new('EC1Y 8PQ');
  $postcode->location->dbh( $my_dbh );
  $postcode->location->tablename( 'postcodedata' );
  my ($x, $y) = $postcode->coordinates;

=item * override the lookup mechanism in subclass

The data-retrieval process is divided up to make this as simple as possible: see the method descriptions below for details. You should be able to replace the data source by overriding C<dbh> or redo the whole lookup by replacing C<retrieve>.

  $Geo::Postcode->location_class('My::Location');

  package My::Location;
  use base qw(Geo::Postcode::Location);
  sub dbh { ... }

=back

=head1 METHODS

=head2 new ()

Constructs and returns a location object. Must be supplied with a postcode object of the class dictated by C<postcode_class>. 

=cut

sub new {
    my ($class, $postcode) = @_;
    return unless $postcode && ref $postcode eq $class->postcode_class;
    my $self = bless { postcode => $postcode }, $class;
    return $self;
}

=head2 postcode_class ()

Returns the full name of the postcode class we should be expecting.

=cut

sub postcode_class { 'Geo::Postcode' }

=head2 postcode ()

Returns the postcode object used to construct this object.

=cut

sub postcode { return shift->{postcode} }

=head2 retrieve ()

Retrieves location information for this postcode. This method is called during construction, retrieves all the necessary information in one go, so all the rest have to do is look up internal values.

=cut

sub retrieve {
    my $self = shift;
    return if $self->{retrieved};
    my $table = $self->tablename || 'postcodes';
    my $sth = $self->dbh->prepare("SELECT * from $table where postcode = ?");
    my $row;
    my $codes = $self->postcode->analyse;    
    TRY: for (@$codes) {
        $sth->execute($_);
        last TRY if $row = $sth->fetchrow_hashref;
    }
    $self->{$_} = $row->{$_} for $self->cols;
    $self->{retrieved} = 1;
    $sth->finish;
    $self->dbh->disconnect if $self->disconnect_after_use;
    return;
}

=head2 disconnect_after_use ()

If this returns a true value, then dbh->disconnect will be called after location information is retrieved.

=cut

sub disconnect_after_use { 0 }

=head2 dbh ()

Accepts, returns - and creates, if necessary - the DBI handle that will be used to retrieve location information. 

This is only separate to make it easy to override.

=cut

sub dbh {
    my $self = shift;
    return $self->{dbh} = $_[0] if @_;
    return $self->{dbh} = $dbh if defined $dbh;
    return $self->{dbh} if $self->{dbh};
    
    my $file = $self->datafile;
    return unless $file && -e $file && -f $file;
    eval 'require DBI;';
    return warn "$@" if $@;
    return $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$file","","");
}

=head2 datafile ( path_to_file )

Accepts and returns the location of the SQLite file we expect to provide location data.

If no file path is supplied, or found by checking C<$Geo::Postcode::Location::datafile> and C<$ENV{POSTCODE_DATA}>, then we will scan the path to locate the default data file that is installed with this module.

=cut

sub datafile {
    my $self = shift;
    return $self->{datafile} = $_[0] if @_;
    return $self->{datafile} = $datafile if $datafile;
    return $self->{datafile} = $ENV{POSTCODE_DATA} if $ENV{POSTCODE_DATA};
    return $self->{datafile} = _find_file('postcodes.db');
}

sub _find_file {
    my $file = shift;
    my @files = grep { -e $_ } map { "$_/Geo/Postcode/$file" } @INC;
    return $files[0];
}

=head2 tablename ()

Sets and gets the name of the database table that should be expected to hold postcode data.

=cut

sub tablename {
    my $self = shift;
    return $self->{tablename} = $_[0] if @_;
    return $self->{tablename} ||= $tablename;
}

=head2 cols ()

Returns a list of the columns we should pull from the database row into the location object's internal hash (and also provide as instance methods). This isn't used in the SQL query (which just SELECTs *), so we don't mind if columns are missing.

=cut

sub cols { return qw(gridn gride latitude longitude town ward nhsarea) }

=head2 AUTOLOAD ()

Turns the columns defined by C<cols> into lookup methods. You can't set values this way: the whole module is strictly read-only.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $m = $AUTOLOAD;
	$m =~ s/.*://;
    return if $m eq 'DESTROY';
    $m = 'latitude' if $m eq 'lat';
    $m = 'longitude' if $m eq 'long';
    $self->retrieve;
    my %cols = map {$_=>1} $self->cols;
    return unless $cols{$m};
    return $self->{$m} || '00';
}

=head2 gridref () 

Returns a proper concatenated grid reference for this postcode, in classic Ordnance Survey AA123456 form rather than the all-digits version we use internally.

See http://www.ordnancesurvey.co.uk/oswebsite/freefun/nationalgrid/nghelp2.html or the more sober http://vancouver-webpages.com/peter/osgbfaq.txt

for more about grid references.

Unlike other grid methods here, this one will also strip redundant trailing zeros from the eastings and northings for the sake of readability.

=cut

$broadosgrid = [
    ['S', 'T'],
    ['N', 'O'],
    ['H', 'J'],
];

$fineosgrid = [
    ['V', 'W', 'X', 'Y', 'Z'],
    ['Q', 'R', 'S', 'T', 'U'],
    ['L', 'M', 'N', 'O', 'P'],
    ['F', 'G', 'H', 'J', 'K'],
    ['A', 'B', 'C', 'D', 'E'],
];

sub gridref {
    my $self = shift;
    return $self->{gridref} if $self->{gridref};
    $self->retrieve;
    my $n = $self->gridn;
    my $e = $self->gride;
    my $broadn = int($n / 500000 );
    my $broade = int($e / 500000 );
    $n %= 500000;
    $e %= 500000;
    my $finen = int($n / 100000 );
    my $finee = int($e / 100000 );
    $n %= 100000;
    $e %= 100000;
    $n =~ s/(0+)$//;
    $e =~ s/(0+)$//;
    $n .= '0' x (length($e) - length($n));
    $e .= '0' x (length($n) - length($e));
    return $self->{gridref} = $broadosgrid->[$broadn][$broade] . $fineosgrid->[$finen][$finee] . $e . $n;
}

=head2 distance_from ()

We prefer to use grid references to calculate distances, since they're laid out nicely on a flat plane and don't require us to remember our A-levels. This method just returns a single distance value. 

You can specify the units of distance by setting C<$Geo::Postcode::Location::units> or passing in a second parameter. Either way it must be one of 'miles', 'km' or 'm'. The default is 'km'.

=cut

sub distance_from {
    my ($self, $postcode, $u) = @_;
    return unless $postcode;
    $self->retrieve;
    my $dx = $self->gride - $postcode->gride;
    my $dy = $self->gridn - $postcode->gridn;
    my $distance = sqrt($dx**2 + $dy**2);
    $u ||= $units;
    
    # longer coordinates mean greater precision (*10 per digit), which means
    # smaller units. we therefore have to multiply out by a factor based
    # on the length of the coordinates to get a kilometer distance.
    # the multiplier is adjusted to return other units if required.
    
    my $multiplier = 10**(3 - length($self->gride));
    $multiplier *= 0.6214 if $u eq 'miles';
    $multiplier *= 1000 if $u eq 'm';
    return int($distance * $multiplier);
}

=head2 bearing_to ()

Returns the angle from grid north, in degrees clockwise, of the line from this postcode to the postcode object supplied.

=cut

sub bearing_to {
    my ($self, $postcode) = @_;
    my $dx = $self->gride - $postcode->gride;
    my $dy = $self->gridn - $postcode->gridn;
    my $r = atan2($dy,$dx);
    my $d = (90 + ($r/$pi * 180) + 360) % 360;
    return $d;
}

=head2 friendly_bearing_to ()

Returns a readable approximation of the bearing from here to there, in a form like 'NW' or 'SSE'.

=cut

sub friendly_bearing_to {
    my ($self, $postcode) = @_;
    my $bearing = $self->bearing_to( $postcode );
    my @nicely = qw(N NNW NW WNW W WSW SW SSW S SSE SE ESE E ENE NE NNE N);
    my $i = int( ($bearing + 11.25)/22.5 );
    return $nicely[$i];
}

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2004 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;


