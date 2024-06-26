package Geo::Gpx;

use warnings;
use strict;

our $VERSION = '1.11';

use Carp;
use DateTime::Format::ISO8601;
use DateTime;
use Encode;
use HTML::Entities qw( encode_entities encode_entities_numeric );
use Scalar::Util qw( blessed looks_like_number );
use XML::Descent;
use File::Basename;
use Cwd qw(cwd abs_path);
use Geo::Gpx::Point;

=encoding utf8

=head1 NAME

Geo::Gpx - Create and parse GPX files

=head1 SYNOPSIS

    my ($gpx, $waypoints, $tracks);

    # From a filename, an open file, or an XML string:

    $gpx = Geo::Gpx->new( input => $fname );
    $gpx = Geo::Gpx->new( input => $fh    );
    $gpx = Geo::Gpx->new(   xml => $xml   );

    my $waypoints = $gpx->waypoints();
    my $tracks    = $gpx->tracks();

=head1 DESCRIPTION

C<Geo::Gpx> supports the parsing and generation of GPX data.

=cut

my %AS_ATTR = (                 # values that are encoded as attributes
    wpt   => qr{^lat|lon$},
    rtept => qr{^lat|lon$},
    trkpt => qr{^lat|lon$},
    email => qr{^id|domain$},
    link  => qr{^href$}
    );

my %KEY_ORDER = (
    wpt => [
        qw(
            ele time magvar geoidheight name cmt desc src link sym type fix
            sat hdop vdop pdop ageofdgpsdata dgpsid extensions
            )
        ],
    );

my %XMLMAP = (                  # map hash keys to GPX names
    waypoints => { waypoints => 'wpt' },
    routes    => {
        routes => 'rte',
        points => 'rtept'
        },
    tracks => {
        tracks   => 'trk',
        segments => 'trkseg',
        points   => 'trkpt'
        }
    );

# my $unsafe_chars_default = '<>&\'"';
my $unsafe_chars_default = '<>&"';      # single-quote character is not problematic

my (@META, @ATTR);
BEGIN {
    @META = qw( name desc author time keywords copyright link );
    @ATTR = qw( version );

    # Generate accessors
    for my $attr ( @META, @ATTR ) {
        no strict 'refs';
        *{ __PACKAGE__ . '::' . $attr } = sub {
            my $self = shift;
            $self->{$attr} = shift if @_;
            return $self->{$attr};
        }
    }
}

sub _time_string_to_epoch {
    my $dt = DateTime::Format::ISO8601->parse_datetime( shift );
    return $dt->epoch
}

sub _time_epoch_to_string {
    my $dt = DateTime->from_epoch( epoch => shift, time_zone => 'UTC' );
    my $str = $dt->strftime( '%Y-%m-%dT%H:%M:%S%z' );
    $str =~ s/(\d{2})$/:$1/;
    $str =~ s/\+00:00$/Z/;
    return $str
}

sub _init_shiny_new {
    my ( $self, $args ) = @_;
    $self->{schema}    = [];
    $self->{waypoints} = [];
    $self->{routes}    = [];
    $self->{tracks}    = [];
    $self->{handler} = {
        create => sub { return {@_}; },
        time =>   sub { return _time_epoch_to_string( $_[0] ); }
        }
}

=head2 Constructor

=over 4

=item new( input => ($fname | $fh) or xml => $xml [, work_dir => $working_directory ] )

Create and return a new C<Geo::Gpx> instance based on a *.gpx file (I<$fname>), an open filehandle (I<$fh>), or an XML string (I<$xml>). GPX 1.0 and 1.1 are supported.

The optional C<work_dir> (or C<wd> for short) specifies where to save any working files, such as with the save() method. It can be supplied as a relative path or as an absolute path. If C<work_dir> is omitted, it is set based on the path of the I<$fname> supplied or the current working directory if the constructor is called with an XML string or a filehandle (see C<< set_wd() >> for more info).

=back

=cut

sub new {
    my ( $class, @args ) = @_;
    my $self = bless( {}, $class );

    # CORE::time because we have our own time method.
    $self->{time} = CORE::time();

    if ( @args % 2 == 0 ) {
        my %args = @args;
        $self->_init_shiny_new( \%args );

        if ( exists $args{input} ) {
            my ($fh, $arg);
            $arg = $args{input};
            $arg =~ s/~/$ENV{'HOME'}/ if $arg =~ /^~/;
            if (-f $arg and $arg !~ /^GLOB/) {
                open( $fh , '<', $arg ) or  die "can't open file $arg $!";
                $self->_parse( $fh );
                $self->set_filename($arg)
            } else { $self->_parse( $args{input} ) }
        } elsif ( exists $args{xml} ) {
            $self->_parse( \$args{xml} )
        }
        $self->set_wd( $args{work_dir} || $args{wd} )
    }
    else {
        croak( "Invalid arguments" )
    }
    return $self
}

sub _trim {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/\s+/ /g;

    $str = encode( 'utf-8', $str );
    # ... because XML::TokeParser (called by the XML::Descent instance) encodes all entities indiscriminately and there is no way to turn that off

    return $str
}

sub _parse {
    my $self   = shift;
    my $source = shift;

    my $p = XML::Descent->new( { Input => $source } );

    $p->on(
        gpx => sub {
            my ( $elem, $attr ) = @_;
            $p->context( $self );

            my $version = $self->{version} = ( $attr->{version} || '1.0' );

            my $parse_deep = sub {
                my ( $elem, $attr ) = @_;
                my $ob = $attr;    # Get attributes
                $p->context( $ob );
                $p->walk();
                return $ob
                };

            # Parse a point
            my $parse_point = sub {
                my ( $elem, $attr ) = @_;
                my $pt = $parse_deep->( $elem, $attr );
                return Geo::Gpx::Point->new( %{$pt} )
                };

            $p->on(
                '*' => sub {
                    my ( $elem, $attr, $ctx ) = @_;
                    $ctx->{$elem} = _trim( $p->text() )
                    },
                time => sub {
                    my ( $elem, $attr, $ctx ) = @_;
                    my $tm = _time_string_to_epoch( _trim( $p->text() ) );
                    $ctx->{$elem} = $tm if defined $tm
                    }
                );

            if ( _cmp_ver( $version, '1.1' ) >= 0 ) {
                # Handle 1.1 metadata
                $p->on(
                    metadata => sub {
                        $p->walk();
                    },
                    [ 'link', 'email', 'author' ] => sub {
                        my ( $elem, $attr, $ctx ) = @_;
                        $ctx->{$elem} = $parse_deep->( $elem, $attr )
                        }
                    );
            } else {
                # Handle 1.0 metadata
                $p->on(
                    url => sub {
                        my ( $elem, $attr, $ctx ) = @_;
                        $ctx->{link}->{href} = _trim( $p->text() )
                        },
                    urlname => sub {
                        my ( $elem, $attr, $ctx ) = @_;
                        $ctx->{link}->{text} = _trim( $p->text() )
                        },
                    author => sub {
                        my ( $elem, $attr, $ctx ) = @_;
                        $ctx->{author}->{name} = _trim( $p->text() )
                        },
                    email => sub {
                        my ( $elem, $attr, $ctx ) = @_;
                        my $em = _trim( $p->text() );
                        if ( $em =~ m{^(.+)\@(.+)$} ) {
                            $ctx->{author}->{email} = {
                                id     => $1,
                                domain => $2
                                };
                        }
                        }
                    );
            }

            $p->on(
                bounds => sub {
                    my ( $elem, $attr, $ctx ) = @_;
                    $ctx->{$elem} = $parse_deep->( $elem, $attr )
                    },
                keywords => sub {
                    my ( $elem, $attr ) = @_;
                    $self->{keywords} = [ map { _trim( $_ ) } split( /,/, $p->text() ) ]
                    },
                wpt => sub {
                    my ( $elem, $attr ) = @_;
                    push @{ $self->{waypoints} }, $parse_point->( $elem, $attr )
                    },
                [ 'trkpt', 'rtept' ] => sub {
                    my ( $elem, $attr, $ctx ) = @_;
                    push @{ $ctx->{points} }, $parse_point->( $elem, $attr )
                    },
                rte => sub {
                    my ( $elem, $attr ) = @_;
                    my $rt = $parse_deep->( $elem, $attr );
                    push @{ $self->{routes} }, $rt
                    },
                trk => sub {
                    my ( $elem, $attr ) = @_;
                    my $tk = {};
                    $p->context( $tk );
                    $p->on(
                        trkseg => sub {
                            my ( $elem, $attr ) = @_;
                            my $seg = $parse_deep->( $elem, $attr );
                            push @{ $tk->{segments} }, $seg;
                            }
                        );
                    $p->walk();
                    push @{ $self->{tracks} }, $tk
                    }
                );
            $p->walk()
            }
        );
    $p->walk()
}

=over 4

=item clone()

Returns a deep copy of a C<Geo::Gpx> instance.

  $clone = $self->clone;

=back

=cut

sub clone {                     # actually it can clone anything
    my $clone;
    eval(Data::Dumper->Dump([ shift ], ['$clone']));
    confess $@ if $@;
    return $clone
}

=head2 Methods

=over 4

=item waypoints( $int or name => $name )

Without arguments, returns the array reference of waypoints.

With an argument, returns a reference to the waypoint whose C<name> field is an exact match with I<$name>. If an integer is specified instead of the C<name> key/value pair, returns the waypoint at position I<$int> in the array reference (1-indexed with negative integers also counting from the end of the array).

Returns C<undef> if no corresponding waypoints are found such that this method can be used to check if a specific point exists (i.e. no exception is raised if I<$name> or I<$int> do not exist) .

=back

=cut

sub waypoints {
    my $aref = shift->{waypoints};
    return $aref unless @_;
    my $waypoint;
    if (@_ == 2) {
        croak "$_[0] key is not supported in waypoints()" unless $_[0] eq 'name';
        for my $pt ( @{$aref} ) {
            next unless defined $pt->name;
            $waypoint = $pt if $pt->name eq $_[1]
        }
    } else {
        my $index = $_[0];
        croak 'waypoints are 1-indexed, please specify a non-zero integer' if $index==0;
        $index -= 1 if $index > 0;          # such that -1, -2, still count from end
        $waypoint = $aref->[ $index ]
    }
    return $waypoint
}

=over 4

=item waypoints_add( $point or \%point [, $point or \%point, … ] )

Add one or more waypoints. Each waypoint must be either a L<Geo::Gpx::Point> or a hash reference with fields that can be parsed by L<Geo::Gpx::Point>'s C<new()> constructor. See the later for the possible fields.

  %point = ( lat => 54.786989, lon => -2.344214, ele => 512, name => 'My house' );
  $gpx->waypoints_add( \%point );

    or

  $pt = Geo::Gpx::Point->new( %point );
  $gpx->waypoints_add( $pt );

=back

=cut

sub waypoints_add {
    my $self = shift;

    for my $wpt ( @_ ) {
        eval { keys %$wpt };
        croak "waypoint argument must be a hash reference" if $@;

        croak "'lat' and 'lon' keys are mandatory in waypoint hash"
            unless exists $wpt->{lon} && exists $wpt->{lat};

        my $pt = Geo::Gpx::Point->new( %$wpt );

        if (defined $pt->name ) {
            my $new_name = $pt->name;
            croak "there already is a waypoint named $new_name, please select another name" if $self->waypoints( 'name' => $new_name );
        }
        push @{ $self->{waypoints} }, $pt
    }
    #TODO: Should return 1
}

=over 4

=item waypoints_search( $field => $regex )

returns an array of waypoints whose I<$field> (e.g. C<name>, C<desc>, …) matches I<$regex>. By default, the regex is case-sensitive; specify C<qr/(?i:search_string_here)/> to ignore case.

=back

=cut

sub waypoints_search {
    my ($gpx, $field, $regex) = @_;
    my @matches;
    my $iter = $gpx->iterate_waypoints();
    while ( my $pt = $iter->() ) {
        if (defined $pt->$field) {
            push @matches, $pt if ($pt->$field =~ $regex)
        }
    }
    return @matches
}

=over 4

=item waypoints_clip( $name | $regex | LIST )

=item way_clip( )

Sends the coordinates of the waypoint(s) whose name is either C<$name> or matches C<$regex> to the clipboard (all points found are sent to the clipboard) and returns an array of points found. By default, the regex is case-sensitive; specify C<qr/(?i:...)/> to ignore case.

Alternatively, an array of C<Geo::GXP::Points> can be provided. C<way_clip()> is a short-hand for this method (convenient when used interactively in the debugger).

This method is only supported on unix-based systems that have the C<xclip> utility installed (see DEPENDENCIES).

=back

=cut

sub way_clip { waypoints_clip( @_ ) }
sub waypoints_clip {
    my $gpx = shift;

    my @points;
    if ( blessed $_[0] and $_[0]->isa('Geo::Gpx::Point' )) {
        @points = @_
    } else {
        my $first_arg = shift;
        if ( ref( $first_arg ) eq 'Regexp' )  {
            @points = $gpx->waypoints_search( name => $first_arg )
        } else {
            my $match = $gpx->waypoints( name => $first_arg );
            push @points, $match if $match
        }
        croak 'no point matches the supplied regex' unless @points
    }
    my @points_reversed = reverse @points;

    for my $pt (@points_reversed) {
        croak 'way_clip() expects list of Geo::Gpx::Point objects' unless $pt->isa('Geo::Gpx::Point');
        my $coords = $pt->lat . ', ';
        $coords   .= $pt->lon;
        system("echo $coords | xclip -selection clipboard")
    }
    return @points
}

=over 4

=item waypoints_delete_all()

delete all waypoints. Returns true.

=back

=cut

sub waypoints_delete_all {
    my $gpx = shift;
    croak 'waypoints_delete_all() expects no arguments' if @_;
    $gpx->{waypoints} = [];
    return 1
}

=over 4

=item waypoint_delete( $name )

delete the waypoint whose C<name> field is an exact match for I<$name> (case sensitively). Returns true if successful, C<undef> if the name cannot be found.

=back

=cut

sub waypoint_delete {
    my ($gpx, $name) = @_;
    my ($index, $found_match) = (0, undef);
    my $iter = $gpx->iterate_waypoints();
    while ( my $pt = $iter->() ) {
        if (defined $pt->name) {
            if ($pt->name eq $name) {
                $found_match = 1;
                last
            }
        }
        ++$index
    }
    splice @{$gpx->{waypoints}}, $index, 1 if $found_match;
    return $found_match
}

=over 4

=item waypoint_rename( $name, $new_name )

rename the waypoint whose C<name> field is an exact match for I<$name> (case sensitively) to I<$new_name>. Returns the point's new name if successful, C<undef> otherwise.

=back

=cut

sub waypoint_rename {
    my $gpx = shift;
    croak 'waypoint_rename() expects $name and $new_name as arguments' unless @_ == 2;
    my ($name, $new_name) = @_;
    my $ret_val;

    croak "there already is a waypoint named $new_name, please select another name" if $gpx->waypoints( 'name' => $new_name );

    my $iter = $gpx->iterate_waypoints();
    while ( my $pt = $iter->() ) {
        if (defined $pt->name) {
            if ($pt->name eq $name) {
                $ret_val = $pt->name( $new_name );
                last
            }
        }
    }
    return $ret_val
}

=over 4

=item waypoints_merge( $gpx, $regex )

Merge waypoints with those contained in the L<Geo::Gpx> instance provide as argument. Waypoints are compared based on their respective C<name> fields, which must exist in I<$gpx> (if names are missing in the current instance, all points will be merged).

A I<$regex> may be provided to limit the merge to a subset of waypoints from I<$gpx>.

Returns the number of points successfully merged (i.e. the difference in C<< $gps->waypoints_count >> before and after the merge).

=back

=cut

sub waypoints_merge {
    my ($gpx1, $gpx2) = (shift, shift);
    my ($regex, @to_merge);
    $regex = shift if ref $_[0] eq 'Regexp';
    croak "waypoints_merge() expects a Geo::Gpx object (and optionally a regex) as arguments" if @_;

    if ($regex) { @to_merge = $gpx2->waypoints_search( name => $regex ) }
    else { @to_merge = @{ $gpx2->waypoints } }
    croak "no waypoints to merge found" unless @to_merge;

    my $before_count = $gpx1->waypoints_count;
    for (0 .. $#to_merge) {
        my $pt = $to_merge[$_];
        croak "points to merge must contain a name field" unless defined $pt->name;
        next if $gpx1->waypoints( name => $pt->name );      # i.e. don't add if exists, could later give option force => 1
        $gpx1->waypoints_add( $pt )
    }
    return $gpx1->waypoints_count - $before_count
}

=over 4

=item waypoint_closest_to( $point or $tcx_trackpoint )

=item trackpoint_closest_to( … )

=item routepoint_closest_to( … )

=item point_closest_to( … )

From any L<Geo::Gpx::Point> or L<Geo::TCX::Trackpoint> object, return the L<Geo::Gpx::Point> that is closest to it. If called in list context, returns a two-element array consisting of that point, and the distance from the coordinate (in meters).

=back

=cut

sub waypoint_closest_to {
    my $gpx = shift;
    my ($closest_pt, $min_dist) = _iterate_and_find_closest_to( $gpx->iterate_waypoints, @_ );
    return ($closest_pt, $min_dist) if wantarray;
    return $closest_pt
}

sub trackpoint_closest_to {
    my $gpx = shift;
    my ($closest_pt, $min_dist) = _iterate_and_find_closest_to( $gpx->iterate_trackpoints, @_ );
    return ($closest_pt, $min_dist) if wantarray;
    return $closest_pt
}

sub routepoint_closest_to {
    my $gpx = shift;
    my ($closest_pt, $min_dist) = _iterate_and_find_closest_to( $gpx->iterate_routepoints, @_ );
    return ($closest_pt, $min_dist) if wantarray;
    return $closest_pt
}

sub point_closest_to {
    my $gpx = shift;
    my ($closest_pt, $min_dist) = _iterate_and_find_closest_to( $gpx->iterate_points, @_ );
    return ($closest_pt, $min_dist) if wantarray;
    return $closest_pt
}

sub _iterate_and_find_closest_to {
    my ($iterator, $to_pt) = (shift, shift);
    my ($method_name, @caller);
    @caller = caller(1);
    ($method_name = $caller[3]) =~ s/.*::(.*)/$1()/;

    my $croak_msg = $method_name . ' expects a single argument in the form of a Geo::Gpx::Point or Geo::TCX::Trackpoint';
    if (ref $to_pt) {
        croak $croak_msg unless $to_pt->isa('Geo::Gpx::Point') or $to_pt->isa('Geo::TCX::Trackpoint')
    } else { croak $croak_msg }
    croak $croak_msg if @_;

    my ($closest_pt, $min_dist);
    while ( my $pt = $iterator->() ) {
        my $distance = $to_pt->distance_to( $pt );
        $min_dist = $distance if ! defined $min_dist;       # $min_dist can be 0
        $closest_pt ||= $pt;
        if ($distance < $min_dist) {
            $closest_pt = $pt;
            $min_dist   = $distance
        }
    }
    return ($closest_pt, $min_dist)
}

=over 4

=item waypoints_print()

print the list of waypoints to screen, along with their names and descriptions if defined. Returns true.

=back

=cut

sub waypoints_print {
    my $gpx = shift;
    croak 'waypoints_print() expects no arguments' if @_;

    my $iter = $gpx->iterate_waypoints();
    while ( my $pt = $iter->() ) {
        my ($name, $desc);
        $name = defined $pt->name ? $pt->name : 'Unnamed';
        $desc = defined $pt->desc ? $pt->desc : 'No description';
        print $name, ': ', $desc, "\n\t", $pt->lat, " ", $pt->lon, "\n"
    }
    return 1
}

=over 4

=item waypoints_count()

returns the number of waypoints in the object.

=back

=cut

sub waypoints_count { return scalar @{ shift->{waypoints} } }

=over 4

=item routes( integer or name => 'name' )

Returns the array reference of routes when called without argument. Optionally accepts a single integer referring to the route number from routes aref (1-indexed with negative integers also counting from the end of the array) or a key value pair with the name of the route to be returned.

=back

=cut

sub routes {
    my $o= shift;
    return $o->{routes} unless @_;
    my $route;
    if (@_ == 2) {
        for my $t ( @{ $o->{routes} } ) {
            $route = $t if $t->{$_[0]} eq $_[1]
        }
        croak "no route named $_[1] in route list" unless $route
    } else {
        my $index = $_[0];
        croak 'routes are 1-indexed, please specify a non-zero integer' if $index==0;

        $index -= 1 if $index > 0;          # such that -1, -2, still count from end
        $route = $o->{routes}[ $index ];
        croak "route $_[0] not found" unless $route
    }
    return $route
}

=over 4

=item routes_add( $route or $points_aref [, name => $route_name )

Add a route to a C<Geo::Gpx> object. The I<$route> is expected to be an existing route (i.e. a hash ref). Returns true. A new route can also be created based an array reference(s) of L<Geo::Gpx::Point> objects and added to the C<Geo::Gpx> instance.

C<name> and all other meta fields supported by routes can be provided and will overwrite any existing fields in I<$route>.

=back

=cut

sub routes_add {
    my $o = shift;
    my ($route, $aref);

    my @args = @_;
    for (@args) {
        if ( ref($_) eq 'HASH' ) {
            $route = shift
        } elsif ( ref($_) eq 'ARRAY' ) {
            $aref = shift
        }
    }
    my %opts = @_;

    my $c;
    if ($aref) {
        croak 'arguments to routes_add() contain both an existing route and an array reference of points, please specify only one kind of reference' if $route;
        $route = { 'name' => 'Track' };

        for my $pt (@$aref) {
            my $is_geo_gpx_point = blessed $pt and $pt->isa('Geo::Gpx::Point');
            $pt = Geo::Gpx::Point->new( %$pt ) unless $is_geo_gpx_point
        }
        $route->{points} = $aref
    }
    croak 'routes_add() expects an existing route or an array reference as argument' unless $route;
    $c = clone( $route );
    for (keys %opts) {
        $c->{$_} = $opts{$_}        # need to check the $_ are legal
    }
    push @{ $o->{routes} }, $c;
    return 1
}

=over 4

=item routes_delete_all()

delete all routes. Returns true.

=back

=cut

sub routes_delete_all {
    my $gpx = shift;
    croak 'routes_delete_all() expects no arguments' if @_;
    $gpx->{routes} = [];
    return 1
}

=over 4

=item routes_count()

returns the number of routes in the object.

=back

=cut

sub routes_count { return scalar @{ shift->{routes} } }

=over 4

=item tracks( integer or name => 'name' )

Returns the array reference of tracks when called without argument. Optionally accepts a single integer referring to the track number from the tracks aref (1-indexed with negative integers also counting from the end of the array) or a key value pair with the name of the track to be returned.

=back

=cut

sub tracks {
    my $o= shift;
    return $o->{tracks} unless @_;
    my $track;
    if (@_ == 2) {
        for my $t ( @{ $o->{tracks} } ) {
            $track = $t if $t->{$_[0]} eq $_[1]
        }
        croak "no track named $_[1] in track list" unless $track
    } else {
        my $index = $_[0];
        croak 'tracks are 1-indexed, please specify a non-zero integer' if $index==0;

        $index -= 1 if $index > 0;          # such that -1, -2, still count from end
        $track = $o->{tracks}[ $index ];
        croak "track $_[0] not found" unless $track
    }
    return $track
}

=over 4

=item tracks_add( $track or $points_aref [, $points_aref, … ] [, name => $track_name ] )

Add a track to a C<Geo::Gpx> object. The I<$track> is expected to be an existing track (i.e. a hash ref). Returns true.

If I<$track> has no C<name> field and none is provided, the timestamp of the first point of the track will be used (this is experimental and may change in the future). All other fields supported by tracks can be provided and will overwrite any existing fields in I<$track>.

A new track can also be created based an array reference(s) of L<Geo::Gpx::Point> objects and added to the C<Geo::Gpx> instance. If more than one array reference is supplied, the resulting track will contain as many segments as the number of aref's provided.

=back

=cut

sub tracks_add {
    my $o = shift;
    my ($track, @arefs);

    my @args = @_;
    for (@args) {
        if ( ref($_) eq 'HASH' ) {
            $track = shift
        } elsif ( ref($_) eq 'ARRAY' ) {
            push @arefs, shift
        }
    }
    my %opts = @_;

    # Q: do we need to check that $o->{tracks} does not already contain a track of the same name?
    # - if so we would do here (unless not yet possible) but it's relevant to method way of adding a track
    # Q: is the name key mandatory? check the schema

    my $c;
    if (@arefs) {
        croak 'arguments to tracks_add() contain both an existing track and an array reference of points, please specify only one kind of reference' if $track;
        # $track = { 'name' => 'Track', 'segments' => [] };
        $track = { 'segments' => [] };      # commented line was just to show the structure of the aref, the name is not required

        for my $i (0 .. $#arefs) {
            my $points = $arefs[$i];
            for my $pt (@{$points}) {
                my $is_geo_gpx_point = blessed $pt and $pt->isa('Geo::Gpx::Point');
                $pt = Geo::Gpx::Point->new( %$pt ) unless $is_geo_gpx_point
            }
            $track->{segments}[$i]{points} = $points
        }
    } else {
        croak 'tracks_add() expects an existing track or an array reference as argument' unless $track
    }
    $c = clone( $track );
    for (keys %opts) {
        $c->{$_} = $opts{$_}        # need to check the $_ are legal
    }

    # let's try a default behaviour of adding time of first point if name is not defined (could provide option to turn this off)
    if ( ! defined $c->{name} ) {
        my $first_pt_time = $c->{segments}[0]{points}[0]->time;
        $c->{name} = _time_epoch_to_string( $first_pt_time ) if $first_pt_time
    }
    push @{ $o->{tracks} }, $c;
    return 1
}

=over 4

=item tracks_delete_all()

delete all tracks. Returns true.

=back

=cut

sub tracks_delete_all {
    my $gpx = shift;
    croak 'tracks_delete_all() expects no arguments' if @_;
    $gpx->{tracks} = [];
    return 1
}

=over 4

=item track_delete( $name )

delete the track whose C<name> field is an exact match for I<$name> (case sensitively). Returns true if successful, C<undef> if the name cannot be found.

=back

=cut

sub track_delete {
    my ($gpx, $name) = @_;
    my ($index, $found_match) = (0, undef);
    for my $t ( @{ $gpx->{tracks} } ) {
        if ($t->{name} eq $name) {
            $found_match = 1;
            last
        }
        ++$index
    }
    splice @{$gpx->{tracks}}, $index, 1 if $found_match;
    return $found_match
}

=over 4

=item track_rename( $name, $new_name )

rename the track whose C<name> field is an exact match for I<$name> (case sensitively) to I<$new_name>. Returns the track's new name if successful, C<undef> otherwise.

Alternatively, an integer may be specified as the first argument, referring to the track number from tracks aref (1-indexed). This is a convenience as it is quite common for tracks to be named with the timestamp fo the first point.

=back

=cut

sub track_rename {
    my $gpx = shift;
    croak 'track_rename() expects $name (or an integer) and $new_name as arguments' unless @_ == 2;
    my ($first_arg, $new_name) = @_;

    for my $t ( @{ $gpx->{tracks} } ) {
        croak "there already is a track named $new_name, please select another name" if $t->{name} eq $new_name
    }

    my $track;
    my $is_index = looks_like_number( $first_arg );
    $track = $is_index ? $gpx->tracks( $first_arg ) : $gpx->tracks( name => $first_arg );

    if (defined $track) {
        return $track->{name} = $new_name
    }
    return undef
}

=over 4

=item tracks_print()

print the list of tracks to screen, by their C<name> field. Returns true.

=back

=cut

sub tracks_print {
    my $gpx = shift;
    croak 'tracks_print() expects no arguments' if @_;

    for my $t ( @{ $gpx->{tracks} } ) {
        print $t->{name}, "\n"
    }
    return 1
}

=over 4

=item tracks_count()

returns the number of tracks in the object.

=back

=cut

sub tracks_count { return scalar @{ shift->{tracks} } }

sub _iterate_points {
    my $pts = shift || [];    # array ref
    unless ( defined $pts ) {
        return sub { return }
    }
    my $max = scalar( @{$pts} );
    my $pos = 0;
    return sub {
        return if $pos >= $max;
        return $pts->[ $pos++ ]
        }
}

sub _iterate_iterators {
    my @its = @_;
    return sub {
        for ( ;; ) {
            return undef unless @its;
            my $next = $its[0]->();
            return $next if defined $next;
            shift @its
        }
        }
}

=over 4

=item iterate_waypoints()

=item iterate_trackpoints()

=item iterate_routepoints()

Get an iterator for all of the waypoints, trackpoints, or routepoints in a C<Geo::Gpx> instance, as per the iterator chosen.

=cut

sub iterate_waypoints {
    my $self = shift;
    return _iterate_points( $self->{waypoints} )
}

sub iterate_routepoints {
    my $self = shift;
    my @iter = ();
    if ( exists( $self->{routes} ) ) {
        for my $rte ( @{ $self->{routes} } ) {
            push @iter, _iterate_points( $rte->{points} )
        }
    }
    return _iterate_iterators( @iter )
}

sub iterate_trackpoints {
    my $self = shift;
    my @iter = ();
    if ( exists( $self->{tracks} ) ) {
        for my $trk ( @{ $self->{tracks} } ) {
            if ( exists( $trk->{segments} ) ) {
                for my $seg ( @{ $trk->{segments} } ) {
                    push @iter, _iterate_points( $seg->{points} )
                }
            }
        }
    }
    return _iterate_iterators( @iter )
}

=item iterate_points()

Get an iterator for all of the points in a C<Geo::Gpx> instance, including waypoints, trackpoints, and routepoints.

    my $iter = $gpx->iterate_points();
    while ( my $pt = $iter->() ) {
        print "Point: ", join( ', ', $pt->{lat}, $pt->{lon} ), "\n";
    }

=back

=cut

sub iterate_points {
    my $self = shift;
    return _iterate_iterators(
        $self->iterate_waypoints(),
        $self->iterate_routepoints(),
        $self->iterate_trackpoints()
        )
}

=over 4

=item bounds( $iterator )

Compute the bounding box of all the points in a C<Geo::Gpx> returning the result as a hash reference.

  my $gpx = Geo::Gpx->new( xml => $some_xml );
  my $bounds = $gpx->bounds();

returns a structure like this:

  $bounds = {
    minlat => 57.120939,
    minlon => -2.9839832,
    maxlat => 57.781729,
    maxlon => -1.230902
  };

C<$iterator> defaults to C<$self-E<gt>iterate_points> if not specified.

=cut

sub bounds {
    my ( $self, $iter ) = @_;
    $iter ||= $self->iterate_points;

    my $bounds = {};
    while ( my $pt = $iter->() ) {
        $bounds->{minlat} = $pt->{lat}
            if !defined $bounds->{minlat} || $pt->{lat} < $bounds->{minlat};
        $bounds->{maxlat} = $pt->{lat}
            if !defined $bounds->{maxlat} || $pt->{lat} > $bounds->{maxlat};
        $bounds->{minlon} = $pt->{lon}
            if !defined $bounds->{minlon} || $pt->{lon} < $bounds->{minlon};
        $bounds->{maxlon} = $pt->{lon}
            if !defined $bounds->{maxlon} || $pt->{lon} > $bounds->{maxlon};
    }
    return $bounds
}

sub _enc {
    return encode_entities_numeric( @_ )    # 2nd positional arg can either be undef or the string of unsafe chars to encode
}

sub _tag {
    my $uc   = shift;           # unsafe_characters
    my $name = shift;
    my $attr = shift || {};

    my @tag  = ( '<', $name );

    # Sort keys so the tests can depend on hash output order
    for my $n ( sort keys %{$attr} ) {
        my $v = $attr->{$n};
        push @tag, ' ', $n, '="', _enc( $v, $uc ), '"'
    }

    if ( @_ ) { push @tag, '>', @_, '</', $name, ">\n"
    } else {    push @tag, " />\n" }
    return join( '', @tag )
}

sub _xml {
    my $self     = shift;
    my $uc       = shift;       # unsafe_characters
    my $name     = shift;
    my $value    = shift;
    my $name_map = shift || {};

    my $tag = $name_map->{$name} || $name;
    my $is_geo_gpx_point = blessed $value and $value->isa('Geo::Gpx::Point');

    if ( defined( my $enc = $self->{encoder}->{$name} ) ) {
        return $enc->( $name, $value )
    } elsif ( ref $value eq 'HASH' or $is_geo_gpx_point ) {
        my $attr    = {};
        my @cont    = ( "\n" );
        my $as_attr = $AS_ATTR{$name};

        # Shallow copy so we can delete keys as we output them
        my %v = %{$value};
        for my $k ( @{ $KEY_ORDER{$name} || [] }, sort keys %v ) {
            if ( defined( my $vv = delete $v{$k} ) ) {
                if ( defined $as_attr && $k =~ $as_attr ) {
                    $attr->{$k} = $vv
                } else {
                    push @cont, $self->_xml( $uc, $k, $vv, $name_map )
                }
            }
        }
        return _tag( $uc, $tag, $attr, @cont )
    } elsif ( ref $value eq 'ARRAY' ) {
        return join '', map { $self->_xml( $uc, $tag, $_, $name_map ) } @{$value}
    } else {
        return _tag( $uc, $tag, {}, _enc( $value, $uc ) )
    }
}

sub _cmp_ver {
    my ( $v1, $v2 ) = @_;
    my @v1 = split( /[.]/, $v1 );
    my @v2 = split( /[.]/, $v2 );
    while ( @v1 && @v2 ) {
        my $cmp = ( shift @v1 <=> shift @v2 );
        return $cmp if $cmp
    }
    return @v1 <=> @v2
}

=item xml( key/values )

Generate and return an XML string representation of the instance.

I<key/values> are (all optional):

Z<>    C<version>:        specifies the GPX XML version scheme to use (defaults to 1.0).
Z<>    C<unsafe_chars>:   the set of characters to be considered unsafe for the XML mark-up and encoded as an entity.

If C<version> is omitted, it defaults to the value of the C<version> attribute. Parsing a GPX document sets the version. If the C<version> attribute is unset defaults to 1.0.

C<unsafe_chars> can be provided to specify which characters to consider unsafe in generating the XML mark-up. This field is then passed through to L<HTML::Entities> function calls whose documentation describes that this field is "specified using the regular expression character class syntax (what you find within brackets in regular expressions)".

As of version I<1.11> of C<Geo::Gpx>, the default set of characters are the C<< '<' >>, C<'&'>, C<< '>' >>, C<'"'> characters. To revert to the pre-version I<1.11> default, which is equivalent to that in <C<HTML::Entities>, explicitely specify C<< unsafe_chars => undef >>. This will encode as the latter module describes the "control chars, high-bit chars, and the C<< '<' >>, C<'&'>, C<< '>' >>, C<< "'" >>, C<'"'> characters".

=cut

sub xml {
    my ($self, %opts)  = @_;
    my $version = $opts{version} || '1.0';

    my $uc;       # can exist and set as undef to encode everything
    if ( exists $opts{unsafe_chars} ) { $uc = $opts{unsafe_chars} }
    else { $uc = $unsafe_chars_default }

    my @ret = ();
    push @ret, qq{<?xml version="1.0" encoding="utf-8"?>\n};

    $self->{encoder} = {
        time => sub {
            my ( $n, $v ) = @_;
            return _tag( $uc, $n, {}, _enc( $self->{handler}->{time}->( $v ), $uc ) )
            },
        keywords => sub {
            my ( $n, $v ) = @_;
            return _tag( $uc, $n, {}, _enc( join( ', ', @{$v} ), $uc ) )
             }
        };

    # Limit to the latest version we know about
    if ( _cmp_ver( $version, '1.1' ) >= 0 ) {
        $version = '1.1';
    } else {
        # Modify encoder
        $self->{encoder}->{link} = sub {
            my ( $n, $v ) = @_;
            my @v = ();
            push @v, $self->_xml( $uc, 'url', $v->{href} )     if exists( $v->{href} );
            push @v, $self->_xml( $uc, 'urlname', $v->{text} ) if exists( $v->{text} );
            return join( '', @v )
            };
        $self->{encoder}->{email} = sub {
            my ( $n, $v ) = @_;
            if ( exists( $v->{id} ) && exists( $v->{domain} ) ) {
                return _tag( $uc, 'email', {}, _enc( join( '@', $v->{id}, $v->{domain} ), $uc ) )
            } else {
                return ''
            }
            };
        $self->{encoder}->{author} = sub {
            my ( $n, $v ) = @_;
            my @v = ();
            push @v, _tag( $uc, 'author', {}, _enc( $v->{name}, $uc ) ) if exists( $v->{name} );
            push @v, $self->_xml( $uc, 'email', $v->{email} )      if exists( $v->{email} );
            return join( '', @v )
            };
    }

    # Turn version into path element
    ( my $vpath = $version ) =~ s{[.]}{/}g;

    my $ns = "http://www.topografix.com/GPX/$vpath";
    my $schema = join( ' ', $ns, "$ns/gpx.xsd", @{ $self->{schema} } );

    push @ret, qq{<gpx xmlns:xsd="http://www.w3.org/2001/XMLSchema" },
        qq{xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" },
        qq{version="$version" creator="Geo::Gpx" },
        qq{xsi:schemaLocation="$schema" }, qq{xmlns="$ns">\n};

    my @meta = ();

    for my $fld ( @META ) {
        if ( exists( $self->{$fld} ) ) {
            push @meta, $self->_xml( $uc, $fld, $self->{$fld} )
        }
    }

    my $bounds = $self->bounds( $self->iterate_points() );
    if ( %{$bounds} ) {
        push @meta, _tag( $uc, 'bounds', $bounds )
    }

    # Version 1.1 nests metadata in a metadata tag
    if ( _cmp_ver( $version, '1.1' ) >= 0 ) {
        push @ret, _tag( $uc, 'metadata', {}, "\n", @meta )
    } else {
        push @ret, @meta
    }

    my @existing_keys;        # waypoints should be generated first, applications like MapSource croak if not
    for my $k ( sort keys %XMLMAP ) {
        if ( exists( $self->{$k} ) ) {
            if ($k eq 'waypoints') { unshift @existing_keys, $k }
            else { push @existing_keys, $k }
        }
    }
    for my $k ( @existing_keys ) {
        push @ret, $self->_xml( $uc, $k, $self->{$k}, $XMLMAP{$k} )
    }
    push @ret, qq{</gpx>\n};
    return join( '', @ret )
}

=item TO_JSON

For compatibility with L<JSON> modules. Convert this object to a hash with keys that correspond to the above methods. Generated ala:

    my %json = map { $_ => $self->$_ }
        qw( name desc author keywords copyright
            time link waypoints tracks routes version );
    $json{bounds} = $self->bounds( $iter );

With one difference: the keys will only be set if they are defined.

=back

=cut

sub TO_JSON {
    my $self = shift;
    my %json;    #= map {$_ => $self->$_} ...
    my @keys = (@META, @ATTR);
    push @keys, 'waypoints' if  $self->waypoints_count;
    push @keys, 'routes'    if  $self->routes_count;
    push @keys, 'tracks'    if  $self->tracks_count;

    for my $key ( @keys ) {
        my $val = $self->$key;
        $json{$key} = $val if defined $val
    }
    if ( my $bounds = $self->bounds ) {
        $json{bounds} = $self->bounds
    }
    return \%json
}

=over 4

=item save( filename => $fname, key/values )

Saves the C<Geo::Gpx> instance as a file.

The filename field is optional unless the instance was created without a filename (i.e with an XML string or a filehandle) and C<set_filename()> has not been called yet. If the filename is a relative path, the file will be saved in the instance's working directory (not the caller's, C<Cwd>).

I<key/values> are (all optional):

Z<>    C<force>:      overwrites existing files if true, otherwise it won't.
Z<>    C<extensions>: save C<< <extensions>…</extension> >> tags if true (defaults to false).
Z<>    C<meta_time>:  save the C<< <time>…</time> >> tag in the file's meta information tags if true (defaults to false). Some applications like MapSource return an error if this tags is present. (All other time tags elsewhere are kept.)
Z<>    C<unsafe_chars>:   see the documentation for C<xml()> above.

=back

=cut

sub save {
    my ($o, %opts) = @_;
    my ($fh, $fname, $xml_string);
    if ( $opts{filename} ) { $fname = $o->set_filename( $opts{filename} ) }
    else { $fname = $o->set_filename() }
    croak "$fname already exists" if -f $fname and !$opts{force};

    my $uc;       # can exist and set as undef to encode everything
    if ( exists $opts{unsafe_chars} ) { $uc = $opts{unsafe_chars} }
    else { $uc = $unsafe_chars_default }

    $xml_string = $o->xml( unsafe_chars => $uc );
    if ( ! $opts{extensions} ) {
        $xml_string =~ s/\n*\w*<extensions>[^<]*<\/extensions>//gs
    }
    if ( ! $opts{meta_time} ) {
        $xml_string =~ s/\n*\w*<time>[^<]*<\/time>//;
    }

    if (defined ($opts{encoding}) and ( $opts{encoding} eq 'latin1') ) {
        open( $fh, ">:encoding(latin1)", $fname) or  die "can't open file $fname: $!";
    } else {
        open( $fh, ">", $fname)  or  die "can't open file $fname: $!";
    }
    print $fh $xml_string
}

=over 4

=item set_filename( $filename )

Sets/gets the filename. Returns the name of the file with the complete path.

=back

=cut

sub set_filename {
    my ($o, $fname) = (shift, shift);
    return $o->{_fileABSOLUTENAME} unless $fname;
    croak 'set_filename() takes only a single name as argument' if @_;
    my $wd;
    if ($o->_is_wd_defined) { $wd = $o->set_wd }
    # set_filename gets called before set_wd by new() so can't access work_dir until initialized

    my ($name, $path, $ext);
    ($name, $path, $ext) = fileparse( $fname, '\..*' );
    if ($wd) {
        my $is_relative_path;
        $is_relative_path = 1 if $fname =~ m,^[^/],;
        $is_relative_path = 0 if $^O eq 'MSWin32' and $fname =~ m/^[A-Z]:/;
        if ($is_relative_path) {
            ($name, $path, $ext) = fileparse( $wd . $fname, '\..*' )
        }
    }
    $o->{_fileABSOLUTEPATH} = abs_path( $path ) . '/';
    $o->{_fileABSOLUTENAME} = $o->{_fileABSOLUTEPATH} . $name . $ext;
    croak 'directory ' . $o->{_fileABSOLUTEPATH} . ' doesn\'t exist' unless -d $o->{_fileABSOLUTEPATH};
    $o->{_fileNAME} = $name;
    $o->{_filePATH} = $path;
    $o->{_fileEXT} = $ext;
    $o->{_filePARSEDNAME} = $fname;
    # _file* keys only for debugging, should not be used anywhere else
    return $o->{_fileABSOLUTENAME}
}

=over 4

=item set_wd( $folder )

Sets/gets the working directory for any eventual saving of the *.gpx file and checks the validity of that path. It can be set as a relative path (i.e. relative to the actual L<Cwd>) or as an absolute path, but is always returned as a full path.

This working directory is always defined. The previous one is also stored in memory, such that C<set_wd('-')> switches back and forth between two directories. The module never actually C<chdir>'s, it just keeps track of where the user wishes to save files.

=back

=cut

sub set_wd {
    my ($o, $dir) = (shift, shift);
    croak 'set_wd() takes only a single folder as argument' if @_;
    my $first_call = ! $o->_is_wd_defined;  # ie if called for 1st time -- at construction by new()

    if (! $dir) {
        return $o->{work_dir} unless $first_call;
        my $fname = $o->set_filename;
        if ($fname) {
            my ($name, $path, $ext) = fileparse( $fname );
            $o->set_wd( $path )
        } else { $o->set_wd( cwd )  }
    } else {
        $dir =~ s/^\s+|\s+$//g;                 # some clean-up
        $dir =~ s/~/$ENV{'HOME'}/ if $dir =~ /^~/;
        $dir = $o->_set_wd_old    if $dir eq '-';

        my $is_relative_path;
        $is_relative_path = 1 if $dir =~ m,^[^/],;
        $is_relative_path = 0 if $^O eq 'MSWin32' and $dir =~ m/^[A-Z]:/;

        if ($is_relative_path) {                # convert rel path to full
            $dir =  $first_call ? cwd . '/' . $dir : $o->{work_dir} . $dir
        }
        $dir =~ s,/*$,/,;                       # some more cleaning
        1 while ( $dir =~ s,/\./,/, );          # support '.'
        1 while ( $dir =~ s,[^/]+/\.\./,, );    # and '..'
        croak "$dir not a valid directory" unless -d $dir;

        if ($first_call) { $o->_set_wd_old( $dir ) }
        else {             $o->_set_wd_old( $o->{work_dir} ) }
        $o->{work_dir} = $dir
    }
    return $o->{work_dir}
}

# if ($o->set_filename) { $o->set_wd() }      # if we have a filename
# else {                  $o->set_wd( cwd ) } # if we don't

sub _set_wd_old {
    my ($o, $dir) = @_;
    $o->{work_dir_old} = $dir if $dir;
    return $o->{work_dir_old}
}

sub _is_wd_defined { return defined shift->{work_dir} }

=head2 Accessors

=over 4

=item name( $str )

=item desc( $str )

=item copyright( $str )

=item keywords( $aref )

Accessors to get or set the C<name>, C<desc>, C<copyright>, or C<keywords> fields of the C<Geo::Gpx> instance.

=item author( $href )

The author information is stored in a hash that reflects the structure of a GPX 1.1 document. To set it, supply a hash reference as (C<link> and C<email> are optional):
  {
    link  => { text => 'Hexten', href => 'http://hexten.net/' },
    email => { domain => 'hexten.net', id => 'andy' },
    name  => 'Andy Armstrong'
  },

=item link( $href )

The link is stored similarly to the author information, it can be set by supplying a hash reference as:
  { link  => { text => 'Hexten', href => 'http://hexten.net/' } }

=item time( $epoch )

Accessor for the <time> element of a GPX. The time is converted to a Unix epoch time when a GPX document is parsed, therefore only epoch time is supported for setting.

=item version()

Returns the schema version of a GPX document. Versions 1.0 and 1.1 are supported.

=back

=head1 DEPENDENCIES

L<DateTime>,
L<DateTime::Format::ISO8601>,
L<Geo::Coordinates::Transform>,
L<HTML::Entities>,
L<Math::Trig>,
L<Scalar::Util>,
L<XML::Descent>

The C<< waypoints_clip() >> method is only supported on unix-based systems that have the C<xclip> utility installed.

=head1 SEE ALSO

L<JSON>

=head1 BUGS AND LIMITATIONS

Prior to version 1.11, C<xml()> and C<save()> encoded "unsafe characters" as per the default in L<HTML::Entities> which resulted in erroneous codes for some multi-byte unicode characters. The current default is to only encode a short list of characters -- see C<xml()> above. This change is motivated by the now prevalent use of unicode as the default encoding in many applications that read XML markup and *.gpx files.

Please report any bugs or feature requests on the github project page. Alternatively, you may submit them to C<bug-geo-gpx@rt.cpan.org> or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Originally by Rich Bowen C<< <rbowen@rcbowen.com> >> and Andy Armstrong  C<< <andy@hexten.net> >>.

This version by Patrick Joly C<< <patjol@cpan.org> >>.

Please visit the project page at: L<https://github.com/patjoly/geo-gpx>.

=head1 VERSION

1.11

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004-2022, Andy Armstrong C<< <andy@hexten.net> >>, Patrick Joly C<< patjol@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;

