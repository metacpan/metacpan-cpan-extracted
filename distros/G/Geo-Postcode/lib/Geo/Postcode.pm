package Geo::Postcode;

use strict;
use vars qw($VERSION);

use overload 
    '""' => '_as_string',
    'eq' => '_as_string';

$VERSION = '0.17';

=head1 NAME

Geo::Postcode - UK Postcode validation and location

=head1 SYNOPSIS

  use Geo::Postcode;
  my $postcode = Geo::Postcode->new('SW1 1AA');

  return unless $postcode->valid;
  my ($n, $e) = ($postcode->gridn, $postcode->gride);

  # is the same as

  my ($n, $e) = $postcode->coordinates;

  # and alternative to
    
  my @location = ($postcode->lat, $postcode->long);
  
  # or the impatient can skip the construction step:
    
  my ($n, $e) = Geo::Postcode->coordinates('SW1 1AA');
   
  my $clean_postcode = Geo::Postcode->valid( $postcode );

  my ($unit, $sector, $district, $area) = Geo::Postcode->analyse('SW1 1AA');

=head1 DESCRIPTION

Geo::Postcode will accept full or partial UK postcodes, validate them against the official spec, separate them into their significant parts, translate them into map references or co-ordinates and calculate distances between them.

It does not check whether the supplied postcode exists: only whether it is well-formed according to British Standard 7666, which you can find here: 

  http://www.govtalk.gov.uk/gdsc/html/frames/PostCode.htm

Geo::Postcode will also work with partial codes, ie areas, districts and sectors. They won't validate, but you can test them for legitimacy with a call to C<valid_fragment>, and you can still turn them into grid references.

To work with US zipcodes, you need Geo::Postalcode instead.

=head1 GRID REFERENCES AND DATA FILES

Any postcode, whether fully or partly specified, can be turned into a grid reference. The Post Office calls it a centroid, and it marks the approximate centre of the area covered by the code.

Unfortunately, and inexplicably, this information is not public domain: unless you're prepared to work at a very crude level, you have to buy location data either from the Post Office or a data shop.

This module comes with with a basic set of publicly-available coordinates that covers nearly all the postcode districts (ie it maps the first block of the postcode but not the second). 

This means that the coordinates we return and the distances we calculate are a bit crude, being based at best on the postcode area. See the POD for Geo::Delivery::Location for how to override the standard data set something more comprehensive.

=head1 INTERFACE

This is a mostly vanilla OOP module, but for quick and dirty work you can skip the object construction step and call a method directly with a postcode string. It will build the necessary object behind the scenes and return the result of the operation.

  my @coordinates = Geo::Postcode->coordinates('LA23 3PA');
  my $postcode = Geo::Postcode->valid($input->param('postcode'));
  
The object will not be available for any more requests, of course.
  
=head1 INTERNALS

The main Geo::Postcode object is very simple blessed hashref. The postcode information is stored as a four-element listref in $self->{postcode}. Location information is retrieved by the separate L<Geo::Postcode::Location>, which by default uses SQLite but can easily be overridden to use the database or other source of your choice. The location machinery is not loaded until it's needed, so you can validate and parse postcodes very cheaply.

=head1 CONSTRUCTION

=head2 new ( postcode_string, location_class )

Constructs and returns the very simple postcode object. All other processing and loading is deferred.

You can also pass in a couple of parameters up front, as a hashref after the postcode:

  my $postcode = Geo::Postcode->new('SW1 1AA', {
    location_class => 'My::Location::Data::Class',
    distance_units => 'miles',
  })

This list will probably grow.

=cut

sub new {
    my ($class, $postcode, $parameters) = @_;
    $class = ref $class || $class;
    my $self = {
        postcode_string => $postcode,
        postcode => [],
        location => undef,
        reformatted => undef,
    };
    $self->{$_} = $parameters->{$_} for qw(location_class distance_units);
    return bless $self, $class;
}

=head2 postcode_string ( )

Always returns the (uppercased) postcode string with which the object was constructed. Cannot be set after construction.

=cut

sub postcode_string {
    return uc(shift->{postcode_string});
}

=head2 fragments ( )

Breaks the postcode into its significant parts, eg:

  EC1R 8DH --> | EC | 1R | 8 | DH |

then stores the parts for later reference and returns them as a listref. Most other methods in this class call C<fragments()> first to get their raw material.

=cut

sub fragments {
    my $self = shift;
    return $self->{postcode} if $self->{postcode} && @{ $self->{postcode} };
    my $code = $self->postcode_string;
    my ($a, $d, $s, $u);
    if ($code =~ s/ *(\d)([A-Z]{2})$//) {
        $s = $1;
        $u = $2;
    } elsif ($code =~ s/ (\d)$//) {
        $s = $1;
    }
    if ($code =~ /^([A-Z]{1,2})(\d{1,2}[A-Z]{0,1})/) {
        $a = $1;
        $d = $2;
    }
    return $self->{postcode} = [$a, $d, $s, $u];
}

=head1 LOCATION

The first call to a location-related method of Geo::Postcode will cause the location class - normally L<Geo::Postcode::Location> - to be loaded along with its data file, and a location object to be associated with this postcode object. We then pass all location-related queries on to the location object.

The accuracy of the information returned by location methods depends on the resolution of the location data file: see the POD for Geo::Postcode::Location for how to supply your own dataset instead of using the crude set that comes with this module.

=head2 location ()

Returns - and if necessary, creates - the location object associated with this postcode object. This operation is avoided until explicitly requested, so that simple postcode-validation can be as economical as possible. The location object does all the work of looking up map reference data, calculating distances and translating into other forms.

=head2 location_class ()

Sets and/or returns the full name of the class that should be called to get a location object. Calling C<location_class> after a location object has been constructed will cause that object to be destroyed, so that the next call to a location-dependent method constructs a new object of the newly-specified class.

=head2 default_location_class ()

Returns the name of the location class we'll use if no other is specified. The default default is L<Geo::Postcode::Location>, but if you're subclassing you will probably want to replace that with one of your own.

=cut

sub location_class {
    my $self = shift;
    my $class = shift;
    if (defined $class && $class ne $self->{location_class}) {
        $self->{location} = undef;
        return $self->{location_class} = $class;
    }
    return $self->{location_class} ||= $self->default_location_class;
}
    
sub default_location_class { 'Geo::Postcode::Location' }

sub location {
    my $self = shift;
    return $self->{location} if $self->{location};
	my $class = $self->location_class;
	eval "require $class";
    die "Failed to load location class '$class': $@" if $@;
	return $self->{location} = $class->new($self);    
}

=head2 gridn () gride ()

Return the OS grid reference coordinates of the centre of this postcode.

=head2 gridref ()

Return the proper OS grid reference for this postcode, in classic AA123456 style.

=cut

sub gridn { return shift->location->gridn(@_); }
sub gride { return shift->location->gride(@_); }
sub gridref { return shift->location->gridref(@_); }

=head2 lat () long ()

Return the latitude and longitude of the centre of this postcode.

=cut

sub lat { return shift->location->latitude(@_); }
sub long { return shift->location->longitude(@_); }

=head2 placename () ward () nhsarea () 

These return information from other fields that may or may not be present in your dataset. The default set supplied with this module doesn't have these extra fields but a set derived from the PAF normally will.

=cut

sub placename { return shift->location->placename(@_); }
sub ward { return shift->location->ward(@_); }
sub nhsarea { return shift->location->nhsarea(@_); }

=head2 coordinates () 

Return the grid reference x, y coordinates of this postcode as two separate values. The grid reference we use here are completely numerical: the usual OS prefix is omitted and an absolute coordinate value returned unless you get a stringy version from C<gridref()>.

=cut

sub coordinates {
    my $self = shift;
    return ($self->gridn, $self->gride);
}

=head2 distance_from ( postcode object or string, unit ) 

Accepts a postcode object or string, and returns the distance from here to there.

As usual, you can call this method directly (ie without first constructing an object), or with any combination of postcode strings and objects:

  my $distance = Geo::Postcode->distance_from('LA23 3PA', 'EC1Y 8PQ');
  my $distance = Geo::Postcode->distance_from($postcode, 'EC1Y 8PQ');
  my $distance = Geo::Postcode->distance_from('EC1Y 8PQ', $postcode);

Will do what you would expect, and the last two should be exactly the same. C<distance_between> is provided as a synonym of C<distance_from> to make that read more sensibly:

  my $distance = Geo::Postcode->distance_between('LA23 3PA', 'EC1Y 8PQ');

In any of these cases you can supply an additional parameter dictating the units of distance: the options are currently 'miles', 'm' or 'km' (the default).

  my $distance = Geo::Postcode->distance_between('LA23 3PA', 'EC1Y 8PQ', 'miles');

The same thing can be accomplished by supplying a 'distance_units' parameter at construction time or, if you don't mind acting global, by setting C<$Geo::Postcode::Location::units>.

=cut

sub distance_from {
    my $self = shift;
    $self = $self->new(shift) unless ref $self;
    my $other = shift;
    my $units = shift || $self->{distance_units};
    $other = ref($other) ? $other : $self->new($other);
    return $self->location->distance_from( $other, $units );
}

sub distance_between {
    return shift->distance_from(@_);
}

=head2 bearing_to ( postcode objects or strings) 

Accepts a list of postcode objects and/or strings, and returns a corresponding list of the bearings from here to there, as degrees clockwise from grid North.

=cut

sub bearing_to {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    return $self->location->bearing_to( ref($_[0]) ? $_[0] : $self->new($_[0]) ) unless wantarray;
    return map { $self->location->bearing_to( ref($_) ? $_ : $self->new($_) ) } @_;
}

=head2 friendly_bearing_to ( postcode objects or strings) 

Accepts a list of postcode objects and/or strings, and returns a corresponding list of rough directions from here to there. 'NW', 'ESE', that sort of thing.

  print "That's " . $postcode1->distance_to($postcode2) . " km " . 
    $postcode1->friendly_bearing_to($postcode2) . " of here.";

=cut

sub friendly_bearing_to {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    return $self->location->friendly_bearing_to( ref($_[0]) ? $_[0] : $self->new($_[0]) ) unless wantarray;
    return map { $self->location->friendly_bearing_to( ref($_) ? $_ : $self->new($_) ) } @_;
}

=head1 VALIDATION

Postcodes are checked against BS7666, which specifies the various kinds of sequences allowed and the characters which may appear in each position.

=head2 valid ()

If the postcode is well-formed and complete, this method returns true (in the useful form of the postcode itself, properly formatted). Otherwise, returns false.

=cut

sub valid {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    return $self if $self->_special_case;
    my ($a, $d, $s, $u) = @{ $self->fragments };

    return unless $a && defined $d && defined $s && $u;
    return if length($a) > 2;
    return if $a =~ /[\W\d]/;
    return if $a =~ /^[QVX]/;
    return if $a =~ /^.[IJZ]/;
    return if length($a) == 1 && $d =~ /[^\dABCDEFGHJKSTUW]$/;
    return if length($a) == 2 && $d =~ /[^\dABEHMNPRVWXY]$/;
    return if length($s) > 1;
    return if $s =~ /\D/;
    return if length($u) != 2;
    return if $u =~ /[^A-Z]/;
    return if $u =~ /[CIKMOV]/;
    return $self->_as_string;
}

=head2 valid_fragment ()

A looser check that doesn't mind incomplete postcodes. It will test that area, district or sector codes follow the rules for valid characters in that part of the postcode, and return true unless it finds anything that's not allowed.

=cut

sub valid_fragment {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    return 1 if $self->_special_case;
    my ($a, $d, $s, $u) = @{ $self->fragments };
    
    return unless $a;
    return if length($a) > 2;
    return if $a =~ /[\W\d]/;
    return if $a =~ /^[QVX]/;
    return if $a =~ /^.[IJZ]/;
    return 1 unless defined $d || defined $s || $u;
    
    return if length($a) == 1 && $d !~ /\d[\dABCDEFGHJKSTUW]?/;
    return if length($a) == 2 && $d !~ /\d[\dABEHMNPRVWXY]?/;
    return 1 unless defined $s || $u;
    
    return if length($s) > 1;
    return if $s =~ /\D/;
    return 1 unless $u;
    
    return if length($u) != 2;
    return if $u =~ /[^A-Z]/;
    return if $u =~ /[CIKMOV]/;
    return 1;

}

=head1 SEGMENTATION

These methods provide the various sector, area and district codes that can be derived from a full postcode, each of which identifies a larger area that encloses the postcode area.

=head1 analyse ()

Returns a list of all the codes present in this postcode, in descending order of specificity. So:

  Geo::Postcode->analyse('EC1Y8PQ');

will return:
  
  ('EC1Y 8PQ', 'EC1Y 8', 'EC1Y', 'EC')
  
which is useful mostly for dealing with situations where you don't know what resolution will be available and need to try alternatives. We do this when location-finding, so as to be able to work with data of unpredictable or variable specificity (ie we are cheap and only buy very rough data sets, but people enter exact postcodes).

=cut

sub analyse {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;   
    return [
        $self->unit,
        $self->sector,
        $self->district,
        $self->area,
    ];
}
sub analyze { return shift->analyse(@_); }

=head1 area ()

Returns the area code part of this postcode. This is the broadest area of all and is identified by the first one or two letters of the code: 'E' or 'EC' or 'LA' or whatever.

=cut

sub area {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;   
    return $self->fragments->[0];
}

=head1 district ()

Returns the district code part of this postcode. This is also called the 'outward' part, by the post office: it consists of the first two or three characters and identifies the delivery office for this address. It will look like 'LA23' or 'EC1Y'.

=cut

sub district {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    my ($a, $d, $s, $u) = @{ $self->fragments };
    return unless defined $a && defined $d;
    return "$a$d";
} 

=head1 sector ()

Returns the sector code part of this postcode. This is getting more local: it includes the first part of the code and the first digit of the second part, and is apparent used by the delivery office to sort the package. It will look something like 'EC1Y 8' or 'E1 7', and note that the space *is* meaningful. 'E1 7' and 'E17' are not the same thing.

=cut

sub sector {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;   
    my ($a, $d, $s, $u) = @{ $self->fragments };
    return unless defined $a && defined $d && defined $s;
    return "$a$d $s";
}

=head1 unit ()

Returns the whole postcode, properly formatted (ie in caps and with a space in the right place, regardless of how it came in). 

This is similar to what you get just by stringifying the postcode object, with the important difference that unit() will only work for a well-formed postcode:

    print Geo::Postcode->unit('LA233PA');   # prints LA23 3PA
    print Geo::Postcode->new('LA233PA');   # prints LA23 3PA
    print Geo::Postcode->unit('LA23333');   # prints nothing
    print Geo::Postcode->new('LA23333');   # prints LA23
    
Whereas normal stringification - which calls C<_as_string> will print all the valid parts of a postcode.

=cut

sub unit {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    my ($a, $d, $s, $u) = @{ $self->fragments };
    return unless defined $a && defined $d && defined $s;
    return "$a$d $s$u";
}

sub _as_string {
    my $self = shift;
    return $self->{reformatted} if $self->{reformatted};
    my ($a, $d, $s, $u) = @{ $self->fragments };
	$a = "" if not defined $a;
	$d = "" if not defined $d;
	$s = "" if not defined $s;
	$u = "" if not defined $u;
    return $self->{reformatted} = "$a$d $s$u";
}

=head1 special_cases ()

Returns a list of known valid but non-conformist postcodes. The only official one is 'G1R 0AA', the old girobank address, but you can override this method to extend the list.

=cut

sub special_cases {
    return ('G1R 0AA');
}

sub _special_case {
    my $self = shift;
    my $pc =  $self->_as_string;
    return 1 if $pc && grep { $pc eq $_ } $self->special_cases;
}

=head1 PLANS

The next majorish version of this module will support (but not require) the interface offered by Geo::Postalcode, so that one can be dropped into the place of the other. Some methods will not be relevant, but I'll try and keep as close a match as I can.

=head1 AUTHOR

William Ross, wross@cpan.org

Development of this library is kindly supported by Amnesty International UK, who are pleased to see it distributed for public use but should not be held responsible for any shortcomings (or inadvertent copyright violations :).

=head1 COPYRIGHT

Copyright 2004 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

