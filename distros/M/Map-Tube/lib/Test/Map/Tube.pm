package Test::Map::Tube;

$Test::Map::Tube::VERSION   = '3.97';
$Test::Map::Tube::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Test::Map::Tube - Module for testing Map::Tube data and features.

=head1 VERSION

Version 3.97

=head1 DESCRIPTION

The module may be used for two complementary purposes: during development of a
tube map, it checks for map authors whether the data structures are consistent
and follow the rules for Map::Tube data. The other use case is during installation
of a map by the user, where it ensures a functioning installation.

=head1 SYNOPSIS

=head2 Validate ONLY map data.

    use strict;
    use warnings;
    use Test::More;

    my $min_ver = 3.93;
    eval "use Test::Map::Tube $min_ver";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    ok_map_data(Map::Tube::London->new);

=head2 Validate ONLY map functions.

    use strict;
    use warnings;
    use Test::More;

    my $min_ver = 3.93;
    eval "use Test::Map::Tube $min_ver";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;
    plan skip_all => 'These tests are for authors only!'
        unless ( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} );

    use Map::Tube::London; # or any other Map::Tube map
    ok_map_functions(Map::Tube::London->new);

=head2 Validate BOTH map data and functions.

    use strict;
    use warnings;
    use Test::More;

    my $min_ver = 3.93;
    eval "use Test::Map::Tube $min_ver tests => 2";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London; # or any other Map::Tube map
    my $map = Map::Tube::London->new;
    ok_map_data($map);
    ok_map_functions($map);

=head2 Validate map data, functions and routes.

    use strict;
    use warnings;
    use Test::More;

    my $min_ver = 3.75;
    eval "use Test::Map::Tube $min_ver tests => 3";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London; # or any other Map::Tube map
    my $map = Map::Tube::London->new;
    ok_map_data($map);
    ok_map_functions($map);

    my @routes = (
        "Route 1|Tower Gateway|Aldgate|Tower Gateway, Tower Hill, Aldgate",
        "Route 2|Liverpool Street|Monument|Liverpool Street, Bank, Monument",
    );
    ok_map_routes($map, \@routes);


For testing at install time, there are only two tests: C<ok_map_functions( )> and
C<ok_map_routes( )>. C<ok_map_functions( )> internally runs several different subtests.

For testing during development, there are a number of separate tests, each checking for a
particular issue. Usually, though, a portmanteau test, C<ok_map_data( )>, is employed which will
run almost all the individual tests in one go. Details are provided below.

=cut

# ###### All further documentation at the end of this file ######

use strict; use warnings;
use 5.012;
use Test::More;
use Data::Compare;
use Map::Tube::Route;

my %testnames = (
    ok_map_data                    => -1,
    ok_map                         => -1,
    not_ok_map_data                => -1,
    not_ok_map                     => -1,
    ok_map_routes                  => -1,
    ok_map_functions               => -1, # = -1 => never use this from within ok_map_data
    ok_map_loadable                =>  2, # >  1 => always use this first from within ok_map_data
    ok_map_connected               =>  1, # =  1 => by default use this from within ok_map_data
    ok_line_definitions            =>  1,
    ok_line_names_unique           =>  1,
    ok_line_ids_unique             =>  1,
    ok_lines_used                  =>  1,
    ok_lines_indexed               =>  1,
    ok_lines_run_through           =>  1,
    ok_links_bidirectional         =>  0,
    ok_station_ids                 =>  1,
    ok_station_names_different     =>  0, # =  0 => by default don't use this from within ok_map_data
    ok_station_names_complete      =>  0,
    ok_stations_linked             =>  1,
    ok_stations_self_linked        =>  1,
    ok_stations_multilinked        =>  1,
    ok_stations_multilined         =>  1,
    ok_stations_linked_share_lines =>  1,
);

sub import {
    my ($self, %plan) = @_;
    my $caller = caller;

    for my $function (keys %testnames) {
        no strict 'refs';
        *{$caller . "::" . $function} = \&$function;
    }

    Test::More->builder( )->exported_to($caller);
    Test::More->builder( )->plan(%plan);

    return;
}


sub ok_map_data($;$$) {
    my( $map, $argref, $message ) = @_;
    my $tb = Test::More->builder( );
    if ( defined($argref) && ( ref($argref) eq '' ) ) {
        $message //= $argref;
        undef($argref);
    }
    my %args;
    $args{name} = $message if defined $message;
    $args{$_} = $argref->{$_} for keys %{ $argref };
    my $want_array = wantarray;

    # Default set of tests to use (unless we're told not to):
    my %tests2use;
    %tests2use = map { $_ => defined($args{name}) ? { name => $args{name} } : { } }
                 grep { $testnames{$_} > 0 }
                 keys %testnames unless $args{only};

    # Check which tests are to exclude, to include or to configure:
    for my $testname( grep { exists( $testnames{$_} ) } keys %args ) {
        if ( $args{$testname} && ( $testnames{$testname} >= 0 ) ) {
            # Include this test
            $tests2use{$testname} //= { };
            $tests2use{$testname}{name} = $args{name} if defined( $args{name} );
            if ( ref( $args{$testname} ) eq 'HASH' ) {
                # ... and pass these arguments:
                $tests2use{$testname}{$_} = $args{$testname}->{$_} for keys %{ $args{$testname} };
            }
        } else {
            # Do not include this test:
            delete( $tests2use{$testname} ) unless ( $testnames{$testname} > 1 );
        }
    }

    # Now call them all:
    my $all_ok = 1;
    my @all_results;
    my $test_level = $tb->level( );
    $tb->level( $test_level+1 );

    # All the individual tests will be counted as just one top-level test:
    subtest 'ok_map_data' => sub {
        for my $testname( sort { ( $testnames{$b} <=> $testnames{$a} ) || ( $a cmp $b ) } keys %tests2use ) {
            no strict 'refs';
            my( $ok, @results );
            if ($want_array) {
                ( $ok, @results ) = (\&{ $testname })->( $map, $tests2use{$testname} );
                push( @all_results, @results );
            } else {
                $ok = (\&{ $testname })->( $map, $tests2use{$testname} );
            }
            $all_ok &&= $ok;
        }
    };

    $tb->level( $test_level );
    return $want_array ? ( $all_ok, @all_results ) : $all_ok;
}


sub ok_map($;$$) {
    # Deprecated alias of ok_map_data( )
    my( $map, $argref, $message ) = @_;
    my $tb = Test::More->builder( );

    my $test_level = $tb->level( );
    $tb->level( $test_level+1 );

    if (wantarray) {
        my( $ok, @messages ) = ok_map_data( $map, $argref, $message );
        $tb->level( $test_level );
        return ( $ok, @messages );
    } else {
        my $ok = ok_map_data( $map, $argref, $message );
        $tb->level( $test_level );
        return $ok;
    }
}


sub not_ok_map_data($;$$) {
    my( $map, $argref, $message ) = @_;
    my $tb = Test::More->builder( );

    my $test_level = $tb->level( );
    $tb->level( $test_level+1 );

	my( $ok, @messages ) = ok_map_data( $map, $argref, $message );
    if (wantarray) {
        if ($ok) {
            my $name = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                           ? $argref->{name}
                           : ( $map->name( ) // 'A Map::Tube' );
            $tb->level( $test_level );
            return ( !$ok, 'No errors found in map data for ' . $name );
        } else {
            $tb->level( $test_level );
            return (!$ok);
        }
    } else {
        $tb->level( $test_level );
        return $ok;
    }
}


sub not_ok_map($;$$) {
    # Deprecated alias of not_ok_map_data( )
    my( $map, $argref, $message ) = @_;
    my $tb = Test::More->builder( );

    my $test_level = $tb->level( );
    $tb->level( $test_level+1 );

	my( $ok, @messages ) = not_ok_map_data( $map, $argref, $message );
    if (wantarray) {
        $tb->level( $test_level );
        return ( $ok, @messages );
    } else {
        $tb->level( $test_level );
        return $ok;
    }
}


sub ok_map_functions ($;$) {
    my ($object, $message) = @_;
    Test::More->builder( )->is_num( _ok_map_functions($object), 1, $message );
    return;
}


sub ok_map_routes($$;$) {
    my ( $object, $routes, $message ) = @_;
    my @errors = _ok_map_routes( $object, $routes );
    if (!@errors) {
      return Test::More->builder( )->is_num( 1, 1, $message );
    }
    for (@errors) {
      my ( $g, $e, $d ) = @$_;
      my ( $gs, $es ) = map join( "\n", @{$_->nodes} ), $g, $e;
      Test::More->builder( )->is_eq( $gs, $es, $message||$d )
    }
    return;
}


sub ok_map_loadable($;$) {
    # Check whether the map object is defined, looks like a Map::Tube object
    # and contains valid data as per Map::Tube built-in base line checks.
    # It does not perform any deep data validity checks beyond.
    #
    # Arguments:
    #  $map    : an object, presumably a Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $object, $argref ) = @_;
    my $tb        = Test::More->builder( );
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : 'An object';
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $ok        = 1;
    my @results;

    if ( !defined($object) ) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok, 'Object undefined', \@results );
    } elsif ( !$object->does('Map::Tube') ) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok, 'Not a Map::Tube object', \@results, $max_msg );
    } else {
        # Don't need to test the following, because that is already tested on construction of the
        # Map::Tube object, so if this is amiss, we'll never even get here.
        # eval { $object->get_map_data; };
        # return 'No map data found' if $@;
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_line_names_unique($;$) {
    # Line names must be unique.
    # Station names must also be unique, but since newer versions of Map::Tube already test this
    # on init, we don't repeat this.
    # This test presupposes that the map is loadable as per ok_map_loadable( ).
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    # Check that no line name comes up more than once (taking into account exact spelling):
    my @dup_names = sort grep { scalar( @{ $rawinfo->{line_names}{$_} } ) > 1 } keys %{ $rawinfo->{line_names} };
    ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                           "Line name $_ defined more than once (ids " .
                                           join( ', ', @{ $rawinfo->{line_names}{$_} } ) . ')',
                                           \@results, $max_msg
                                         ) for @dup_names;

    # Check that no line name comes up more than once after upper-casing:
    @dup_names = ( );
    for my $uc_name ( sort keys %{ $rawinfo->{line_names_uc} } ) {
        my @names = keys %{ $rawinfo->{line_names_uc}{$uc_name} };
        push( @dup_names, $uc_name ) if ( scalar(@names) > 1 );
    }
    ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                           "Line name $_ defined more than once with different spelling: " .
                                           join( ', ', sort keys( %{ $rawinfo->{line_names_uc}{$_} } ) ),
                                           \@results, $max_msg
                                         ) for @dup_names;

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_line_ids_unique($;$) {
    # Line ids must be unique.
    # This test presupposes that the map is loadable as per ok_map_loadable( ).
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    my @dup_ids = sort grep { $rawinfo->{line_ids_defined}->{$_} > 1 } keys %{ $rawinfo->{line_ids_defined} };
    ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok, "Line id $_ defined more than once", \@results,
                                           $max_msg ) for @dup_ids;

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_station_names_different($;$) {
    # Station ids must be unique, but since newer versions of Map::Tube already test this on init,
    # we don't repeat this. Instead, we check here whether no two station names look "similar
    # enough" to assume one might be a typo for the other.
    # This is in many ways a fallible test and cannot be applied indiscriminately.
    # Hence, it can be tweaked in two ways:
    #    a) by setting the maximum Levenshtein distance for two names to be considered equal. Set
    #       to 0 in order not to test at all.
    #    b) by setting a threshold for the total number of similar entries below which no problem
    #       will be reported. Default is 0 (so all issues will be reported). Set it, e.g., to 5
    #       if you know that your map contains 5 legitimate pairs of similar entries.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             The entry for name will be used as a name to identify the map to the user.
    #             dist_limit sets the maximum distance as outlined above. Default: 2.
    #             max_allowed sets the threshold on the number of issues as outlined above.
    #             Default: 0.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb            = Test::More->builder( );
    $map            = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name        = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                          ? $argref->{name}
                          : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg     = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                          ? $argref->{max_messages}
                          : 0;
    my $dist_limit    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{dist_limit}  ) )
                          ? $argref->{dist_limit}
                          : 2;
    my $max_allowed = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_allowed} ) )
                          ? $argref->{max_allowed}
                          : 0;
    my $rawinfo     = $map->{_rawinfo};
    my $ok            = 1;
    my @results;

    eval 'use Text::Levenshtein::XS qw(distance)';
    return _emit_diagnostics( $name, wantarray, $ok,
                              'Module Text::Levenshtein::XS required for name similarity testing',
                              \@results, $max_msg ) if $@;

    my @similar_names;
    my @station_names = sort keys %{ $rawinfo->{station_names} };
    while (@station_names) {
        my $station = shift(@station_names);
        push( @similar_names, map { ":$station:$_:" } grep { ( $station ne $_ ) &&
                                                              ( distance( $station, $_ ) <= $dist_limit )
                                                           } @station_names );
    }

    if ( scalar(@similar_names) > $max_allowed ) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               scalar(@similar_names) .
                                               ' similar name pair(s) found at or below distance ' .
                                               $dist_limit,
                                               \@results, $max_msg
                                             );
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               "Similar names maybe due to typo? $_",
                                               \@results, $max_msg
                                             ) for @similar_names;
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_station_names_complete($;$) {
    # Station ids must be unique, but since newer versions of Map::Tube already test this on
    # init, we don't repeat this. Instead, we check here that no station name is a proper prefix
    # of another one; otherwise, one might be an accidentally abbreviated name.
    # This is in many ways a fallible test and cannot be applied indiscriminately.
    # Hence, it can be tweaked by setting a threshold for the total number of similar entries
    # below which no problem will be reported. Default is 0 (so all issues will be reported).
    # Set it, e.g., to 5 if you know that your map contains 5 legitimate pairs of entries where
    # one looks like an abbreviated version of the other, but isn't.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             The entry for name will be used as a name to identify the map to the user.
    #             max_allowed sets the threshold on the number of issues as outlined above.
    #             Default: 0.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb            = Test::More->builder( );
    $map            = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name        = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                          ? $argref->{name}
                          : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg     = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                          ? $argref->{max_messages}
                          : 0;
    my $max_allowed = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_allowed} ) )
                          ? $argref->{max_allowed}
                          : 0;
    my $rawinfo     = $map->{_rawinfo};
    my $ok            = 1;
    my @results;

    my @incomplete_names;
    my @station_names = sort keys %{ $rawinfo->{station_names} };
    while (@station_names) {
        my $station = shift(@station_names);
        push( @incomplete_names, map { ":$station:$_:" } grep { ( $station ne $_ ) &&
                                                                ( $station eq substr( $_, 0, length($station) ) )
                                                              } @station_names );
    }

    if ( scalar(@incomplete_names) > $max_allowed ) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               scalar(@incomplete_names) . ' possibly partial name pair(s) found', \@results,
                                               $max_msg
                                             );
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok, "Incomplete name? $_", \@results, $max_msg
                                             ) for @incomplete_names;
    }
    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_lines_used($;$) {
    # All lines serving some station must be defined (does not apply to other_links),
    # but since newer versions of Map::Tube already test this on init, we don't repeat this.
    # All defined lines must be serving some station (possibly within other_links),
    # and, in fact, more than just one.
    # (It seems that Test::Map::Tube does test for the former, but the message is a bit cryptic:
    # "get_lines() returns incorrect line entries".)
    # Lines must not come up both in ordinary and in other_links.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    my @unserve_line_ids = sort grep { !$rawinfo->{line_ids_used}{$_} && !exists( $rawinfo->{other_link_used}{$_} ) }
                                keys %{ $rawinfo->{line_ids_defined} };
    if (@unserve_line_ids) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               "Line id $_ defined but serves no stations (not even as other_link)",
                                               \@results, $max_msg
                                             ) for @unserve_line_ids;
    }

    my @serve1_line_ids = sort grep { ( $rawinfo->{line_ids_used}{$_} == 1 ) && !exists( $rawinfo->{other_link_used}{$_} ) }
                               keys %{ $rawinfo->{line_ids_defined} };
    if (@serve1_line_ids) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               "Line id $_ defined but serves only one station",
                                               \@results, $max_msg
                                             ) for @serve1_line_ids;
    }

    my @line_and_other_link = sort grep { $rawinfo->{line_ids_used}{$_} && exists( $rawinfo->{other_link_used}{$_} ) }
                                   keys %{ $rawinfo->{line_ids_used} };
    if (@line_and_other_link) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               "Line id $_ used both as ordinary link and in other_link",
                                               \@results, $max_msg
                                             ) for @line_and_other_link;
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_stations_linked_share_lines($;$) {
    # Stations that are linked must share at least one line (possibly through other_link).
    # Lines serving some station must also serve at least one linked station (ordinary link).
    # other_links at some station must also be named at at least one of the linked stations.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    for my $station1 ( sort keys %{ $rawinfo->{station_linked_to_stations} } ) {
        for my $station2 ( sort grep { $_ gt $station1 } keys %{ $rawinfo->{station_linked_to_stations}{$station1} } ) {
            my $linect = scalar( grep { exists( $rawinfo->{station_served_by_lines}{$station2}{$_} ) }
                                 keys %{ $rawinfo->{station_served_by_lines}{$station1} }
                               );
            ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                   "Stations id $station1 and $station2 are linked but share no line",
                                                   \@results, $max_msg
                                                 ) unless $linect;
        }
    }

    for my $station ( sort keys %{ $rawinfo->{station_served_by_lines} } ) {
        for my $line( grep { $rawinfo->{station_served_by_lines}{$station}{$_} == 1 }
                      keys %{ $rawinfo->{station_served_by_lines}{$station} }
                    ) {
            my $stationct = grep { exists( $rawinfo->{station_served_by_lines}{$_}{$line} ) }
                            keys %{ $rawinfo->{station_linked_to_stations}{$station} };
            ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                   "Line id $line at station id $station does not serve any linked station",
                                                   \@results, $max_msg
                                                 ) unless $stationct;
        }
    }

    for my $station ( sort keys %{ $rawinfo->{station_served_by_lines} } ) {
        for my $line( grep { $rawinfo->{station_served_by_lines}{$station}{$_} == 2 }
                      keys %{ $rawinfo->{station_served_by_lines}{$station} }
                    ) {
            my $stationct = grep { exists( $rawinfo->{station_served_by_lines}{$_}{$line} ) }
                            keys %{ $rawinfo->{station_linked_to_stations}{$station} };
            ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                   "Other_link id $line at station id $station does not serve any linked station",
                                                   \@results, $max_msg
                                                 ) unless $stationct;
        }
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_links_bidirectional($;$) {
    # Are stations all linked symmetrically?
    # This is optional -- links may legally be unidirectional.
    # This is in many ways a fallible test and cannot be applied indiscriminately. Hence,
    # it is optional to use this. Also, it can be tweaked by passing the ids (not names!) of
    # lines that are known to be at least partially unidirectional.
    # In general it is a good idea to check all those lines that are fully bidirectional (which
    # in general is the vast majority) in order to catch accidental omissions of links.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             The entry for name will be used as a name to identify the map to the user.
    #             The entry for exclude is the id of a single line to be excluded from
    #             the bidi check, or a reference to an array of such ids.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb               = Test::More->builder( );
    $map               = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name           = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                             ? $argref->{name}
                             : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg        = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                             ? $argref->{max_messages}
                             : 0;
    my %skip_lines_ids = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{exclude} ) )
                             ? ( map { $_ => 1 } ( ( ref($argref->{exclude}) eq 'ARRAY' )
                                                         ? @{ $argref->{exclude} }
                                                         : $argref->{exclude}
                                                   )
                               )
                             : ( );
    my $rawinfo        = $map->{_rawinfo};
    my $ok               = 1;
    my @results;

    for my $station( sort keys %{ $rawinfo->{station_linked_to_stations} } ) {
        for my $station1( grep { !exists( $rawinfo->{station_linked_to_stations}{$_}{$station} ) }
                          keys %{ $rawinfo->{station_linked_to_stations}{$station} }
                        ) {
            my $linect     = 0;
            my @involved_lines;
            my $exceptct = 0;
            for my $line( keys( %{ $rawinfo->{station_served_by_lines}->{$station} } ) ) {
                next unless exists $rawinfo->{station_served_by_lines}->{$station1}->{$line};
                next if exists( $skip_lines_ids{$line} );
                push( @involved_lines, $line );
            }
            ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                   "Station id $station linked to $station1 but not vice versa " .
                                                   "via line(s) id " . join( ',', sort @involved_lines ),
                                                   \@results, $max_msg
                                                 ) if @involved_lines;
        }
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_lines_indexed($;$) {
    # Each line must have either all or no stations indexed (but not some aye, some nay).
    # Each line's indices must be unique.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    my @partially_indexed = sort grep { ( $rawinfo->{line_ids_indexed}{$_} != 0 ) &&
                                        ( $rawinfo->{line_ids_indexed}{$_} != $rawinfo->{line_ids_used}{$_} )
                                      } keys %{ $rawinfo->{line_ids_used} };
    if (@partially_indexed) {
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               "Line id $_ is partially indexed but not completely", \@results, $max_msg
                                             ) for @partially_indexed;
    }

    my @messed_up_lines;
    for my $line( sort keys %{ $rawinfo->{line_id_has_indices} } ) {
        my @nonuniq_idx = grep { $rawinfo->{line_id_has_indices}{$line}{$_} > 1 }
                          keys %{ $rawinfo->{line_id_has_indices}{$line} };
        ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                               "Line id $line has non-unique indices: " .
                                                   join( ',', sort { $a <=> $b } @nonuniq_idx ),
                                               \@results, $max_msg
                                             ) if @nonuniq_idx;
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_lines_run_through($;$) {
    # Each line should be weakly connected, i.e., there should be no gaps in lines (at least
    # not when disregarding directionality).
    # If exceptionally this is known not to hold for certain lines, their ids (not names) can
    # be passed to this method.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             The entry for name will be used as a name to identify the map to the user.
    #             The entry for exclude is the id of a single line to be excluded from
    #             the connectivity check, or a reference to an array of such ids.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb               = Test::More->builder( );
    $map               = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name           = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                             ? $argref->{name}
                             : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg        = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                             ? $argref->{max_messages}
                             : 0;
    my %skip_lines_ids = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{exclude} ) )
                             ? ( map { $_ => 1 } ( ( ref($argref->{exclude}) eq 'ARRAY' )
                                                         ? @{ $argref->{exclude} }
                                                         : $argref->{exclude}
                                                 )
                               )
                             : ( );
    my $rawinfo        = $map->{_rawinfo};
    my $ok               = 1;
    my @results;

    eval 'use Graph';
    return _emit_diagnostics( $name, wantarray, $ok, 'Module Graph required for testing connectedness of map', \@results,
                              $max_msg ) if $@;

    # For each line separately:
    # Build a list of pairs of (directly) linked stations on this line
    for my $line_id( grep { !exists( $skip_lines_ids{$_} ) } keys %{ $rawinfo->{line_ids_defined} } ) {
        my @all_links;
        for my $station( grep { exists( $rawinfo->{station_served_by_lines}->{$_}->{$line_id} ) }
                              keys %{ $rawinfo->{station_linked_to_stations} }
                       ) {
            push( @all_links, [ $station, $_ ] ) for grep { ( $rawinfo->{station_served_by_lines}->{$_}->{$line_id} ) }
                                                              keys %{ $rawinfo->{station_linked_to_stations}->{$station}
                                                          };
        }

        my $graph = Graph->new( directed => 1, edges => \@all_links );
        if ( !$graph->is_weakly_connected( ) ) {
            my @components = $graph->weakly_connected_components( );
            ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                   "Line id $line_id consists of " . scalar(@components) .
                                                   ' separate components',
                                                   \@results, $max_msg );
        }
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_map_connected($;$) {
    # Is the whole map connected, i.e., are there routes between any two stations?
    # If so: are there connections between any two stations? (Might not be if there are
    # unidirectional links).
    # In either case, show examples of stations in different components if any.
    # For maps that are known not to be connected, the expected maximum number of components
    # may be specified. Defaults to 1.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             The entry for name will be used as a name to identify the map to the user.
    #             max_allowed sets the threshold on the number of issues as outlined above.
    #             Default: 0
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb            = Test::More->builder( );
    $map            = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name        = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                          ? $argref->{name}
                          : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg     = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                          ? $argref->{max_messages}
                          : 0;
    my $max_allowed = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_allowed} ) )
                          ? $argref->{max_allowed}
                          : 0;
    my $rawinfo     = $map->{_rawinfo};
    my $ok            = 1;
    my @results;

    eval 'use Graph';
    return _emit_diagnostics( $name, wantarray, $ok,
                              'Module Graph required for testing connectedness of map', \@results,
                              $max_msg ) if $@;

    # Build a list of pairs of (directly) linked stations (possibly by other_link)
    my @all_links;
    for my $station( keys %{ $rawinfo->{station_linked_to_stations} } ) {
        push( @all_links, [ $station, $_ ] ) for keys %{ $rawinfo->{station_linked_to_stations}->{$station} };
    }
    # note( "*** Total number of links: ", scalar(@all_links) );

    my $graph = Graph->new( directed => 1, edges => \@all_links );

    # Check whether map is (somehow) connected, ignoring possible unidirectionality:
    if ( !$graph->is_weakly_connected( ) ) {
        my @components = sort { ( scalar(@$b) <=> scalar(@$a) ) ||
                                ( join( ':', sort(@$a) ) cmp join( ':', sort(@$b) ) )
                              } $graph->weakly_connected_components( );
        if ( scalar(@components) > $max_allowed ) {
            my @examples = sort map { ( sort(@$_) )[0] } @components;
            ( $ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                   'Map has ' . scalar(@components) .
                                                   ' separate components; e.g., stations with ids ' .
                                                   join( ', ', @examples ),
                                                   \@results, $max_msg
                                                 );
        }
    }

    if ($ok) {
        # Map is at least weakly connected, but maybe not all stations reachable from
        # each other station?
        if ( !$graph->is_strongly_connected( ) ) {
            my @components = sort { ( scalar(@$b) <=> scalar(@$a) ) ||
                                    ( join( ':', sort(@$a) ) cmp join( ':', sort(@$b) ) )
                                  } $graph->strongly_connected_components( );
            # Components sorted descending by size in a strictly reproducible order
            if ( scalar(@components) > $max_allowed ) {
                my( $station1, @examples ) = map { ( sort(@$_) )[0] } @components;
                # $station1 is taken from the largest component, because we assume that one
                # to be the "healthiest"
                my @unlinked;
                diag('For big maps this test may take long... ') if ( scalar(@all_links) > 50 );
                                        # because the Graph module has to do a lot of work upfront
                for (sort @examples) {
                  my $unlink = $graph->is_reachable( $station1, $_ ) ? ( $_ . '//' . $station1 ) : ( $station1 . '//' . $_ );
                  push( @unlinked, $unlink );
                }
                ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                                      'Not every station reachable from every other station -- map has ' .
                                                      scalar(@components) .
                                                      ' separate components; e.g., stations with ids ' .
                                                      join( ', ', sort @unlinked ),
                                                      \@results, $max_msg
                                                    );
            }
        }
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_line_definitions($;$) {
    # Line Ids must not contain comma or colon (for syntactical reasons).
    # Color specifications must be either hex (#RRGGBB) or from a pre-defined set of
    # color names (see Map::Tube::Utils).
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                          "Line ID '$_' must not contain comma (,) or colon (:)",
                                          \@results, $max_msg
                                        ) for grep { /[,:]/ } sort keys %{ $rawinfo->{line_names} };

    eval 'use Map::Tube::Utils';
    return _emit_diagnostics( $name, wantarray, $ok,
                              'Map::Tube::Utils required for testing color names', \@results,
                              $max_msg ) if $@;

    ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                          'Line ' . $_->{name} . ' has invalid color ' . $_->{color},
                                          \@results, $max_msg
                                        ) for grep { defined( $_->{color} ) && !Map::Tube::Utils::is_valid_color($_->{color}) }
                                              @{ $map->{lines} };

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_station_ids($;$) {
    # Station Ids must not contain comma or colon (for syntactical reasons).
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $ok        = 1;
    my @results;

    ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                          "Station ID '$_' must not contain comma (,) or colon (:)",
                                          \@results, $max_msg
                                        ) for grep { /[,:]/ } sort keys %{ $map->{nodes} };

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_stations_linked($;$) {
    # Linked-to stations must be defined as stations.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $ok       = 1;
    my @results;

    my %linked;
    for my $id( sort keys %{ $map->{nodes} } ) {
        $linked{$_}{$id}++ for ( sort grep { !exists( $map->{nodes}->{$_} ) } split( /\,/, $map->{nodes}->{$id}->{link} ) );
    }

    ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                          "Undefined station ID $_ is linked to from station(s) " .
                                              join( ',', sort keys %{ $linked{$_} } ),
                                          \@results, $max_msg
                                        ) for sort keys %linked;

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_stations_self_linked($;$) {
    # Stations should not be linked to themselves.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                          "Station ID $_ links to itself", \@results, $max_msg
                                        ) for sort grep { exists( $rawinfo->{station_linked_to_stations}{$_}{$_} ) }
                                                   keys %{ $rawinfo->{station_linked_to_stations} };

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_stations_multilinked($;$) {
    # Stations should not name linked stations more than once.
    # (Any two stations may be linked by more than one line, but the link should still name
    # each station only once.)
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $ok        = 1;
    my @results;

    for my $station ( sort keys %{ $map->{nodes} } ) {
        my %links;
        $links{$_}++ for split( /,/, $map->{nodes}->{$station}->{link} );
        ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                              "Station ID $station links to station ID $_ " .
                                                  $links{$_} . ' times',
                                              \@results, $max_msg
                                            ) for sort grep { $links{$_} > 1 } keys %links;
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


sub ok_stations_multilined($;$) {
    # Stations should not name the same line more than once.
    # This applies only to regular links, not to other_links, where multiple mentions are
    # quite normal.
    #
    # Arguments:
    #  $map    : a loadable Map::Tube object
    #  $argref : an optional hash ref with further arguments for the test.
    #             Only the entry for name will be used as a name to identify the map to the user.
    #
    # Return:
    #  in scalar context: a boolean indicating success (truey) or failure (falsey).
    #                      Any diagnostics will have been output at the time of return.
    #  in array contect:  a list containing a boolean (as above), followed by all diagnostic
    #                      messages (if any).
    #                      It is the responsibility of the caller to display these messages
    #                      to the user.
    #
    my ( $map, $argref ) = @_;
    my $tb        = Test::More->builder( );
    $map        = _prepare_raw_map($map) unless exists $map->{_rawinfo};
    my $name    = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{name} ) )
                      ? $argref->{name}
                      : ( $map->name( ) // 'A Map::Tube' );
    my $max_msg = ( defined($argref) && ( ref($argref) eq 'HASH' ) && exists( $argref->{max_messages} ) )
                      ? $argref->{max_messages}
                      : 0;
    my $rawinfo = $map->{_rawinfo};
    my $ok        = 1;
    my @results;

    for my $station ( sort keys %{ $rawinfo->{station_line_count} } ) {
        ($ok, @results ) = _emit_diagnostics( $name, wantarray, $ok,
                                              "Station ID $station names line ID $_ " .
                                                  $rawinfo->{station_line_count}->{$station}->{$_} . ' times',
                                              \@results, $max_msg
                                              ) for sort grep { $rawinfo->{station_line_count}->{$station}->{$_} > 1 }
                                                keys %{ $rawinfo->{station_line_count}->{$station} };
    }

    $ok = $tb->ok( 1, $name ) if $ok;

    return wantarray ? ( $ok, @results ) : $ok;
}


# add more test definitions here...


#
#
# PRIVATE METHODS


sub _ok_map_functions {
    my ($object) = @_;

    return 0 unless ( defined $object && $object->does('Map::Tube') );

    my $actual;
    eval { $actual = $object->get_map_data };
    ($@) and ( carp('no map data found' ) and return 0 );

    # get_shortest_route()
    eval { $object->get_shortest_route };
    ($@) or ( carp('get_shortest_route() with no param') and return 0 );
    eval { $object->get_shortest_route('Foo') };
    ($@) or ( carp('get_shortest_route() with one param') and return 0 );
    eval { $object->get_shortest_route( 'Foo', 'Bar' ) };
    ($@) or ( carp('get_shortest_route() with two invalid params') and return 0 );
    my $from_station = $actual->{stations}->{station}->[0]->{name};
    my $to_station   = $actual->{stations}->{station}->[1]->{name};
    eval { $object->get_shortest_route( $from_station, 'Bar' ) };
    ($@) or ( carp('get_shortest_route() with invalid to station') and return 0 );
    eval { $object->get_shortest_route( 'Foo', $to_station ) };
    ($@) or ( carp('get_shortest_route() with invalid from station') and return 0 );
    eval { $object->get_shortest_route( $from_station, $to_station ) };
    ($@) and carp($@) and return 0;

    # get_name()
    if ( exists $actual->{name} && defined $actual->{name}) {
        ( $object->name eq $actual->{name} )
            or ( carp('name() returns incorrect map name') and return 0 );
    }

    # get_lines()
    my $lines_count = scalar(@{$actual->{lines}->{line}});
    ( scalar( @{ $object->get_lines} ) == $lines_count )
        or ( carp('get_lines() returns incorrect line entries') and return 0 );

    # get_stations()
    eval { $object->get_stations('Not-A-Valid-Line-Name') };
    ($@) or ( carp('get_stations() with invalid line name') and return 0 );
    my $line_name = $actual->{lines}->{line}->[0]->{name};
    ( scalar( @{ $object->get_stations($line_name)} ) > 0 )
        or ( carp('get_stations() returns incorrect station entries') and return 0 );

    # get_next_stations()
    eval { $object->get_next_stations };
    ($@) or ( carp('get_next_stations() with no param' . Dumper($@) ) and return 0 );
    eval { $object->get_next_stations('Not-A-Valid-Station-Name') };
    ($@) or ( carp('get_next_stations() with invalid station name') and return 0 );
    ( scalar( @{ $object->get_next_stations($from_station) } ) > 0 )
        or (carp('get_next_stations() returns incorrect station entries') and return 0 );

    # get_line_by_id()
    eval { $object->get_line_by_id };
    ($@) or ( carp('get_line_by_id() with no param') and return 0 );
    eval { $object->get_line_by_id('Not-A-Valid-Line-ID') };
    ($@) or ( carp('get_line_by_id() with invalid id') and return 0 );
    my $line_id = $actual->{lines}->{line}->[0]->{id};
    eval { $object->get_line_by_id($line_id) };
    ($@) and ( carp($@) and return 0 );

    # get_line_by_name() - handle in case Map::Tube::Plugin::FuzzyNames is installed.
    eval { $object->get_line_by_name($line_name) };
    ($@) and ( carp($@) and return 0 );
    eval { my $l = $object->get_line_by_name('Not-A-Valid-Line-Name'); croak() unless defined $l };
    ($@) or ( carp('get_line_by_name() with invalid line name') and return 0 );
    eval { my $l = $object->get_line_by_name; croak() unless defined $l; };
    ($@) or ( carp('get_line_by_name() with no param') and return 0 );

    # get_node_by_id()
    eval { $object->get_node_by_id };
    ($@) or ( carp('get_node_by_id() with no param') and return 0 );
    eval { $object->get_node_by_id('Not-A-Valid-Node-ID') };
    ($@) or ( carp('get_node_by_id() with invalid node id') and return 0 );
    my $station_id = $actual->{stations}->{station}->[0]->{id};
    eval { $object->get_node_by_id($station_id) };
    ($@) and ( carp($@) and return 0 );

    # add_station()
    eval { $object->get_line_by_id($line_id)->add_station };
    ($@) or ( carp('add_station() with no param') and return 0 );
    eval { $object->get_line_by_id($line_id)->add_station('Not-A-Valid-Station') };
    ($@) or ( carp('add_station() with invalid node object') and return 0 );
    eval { $object->get_line_by_id($line_id)->add_station($object->get_node_by_id($station_id)) };
    ($@) and ( carp($@) and return 0 );

    # get_node_by_name()
    eval { $object->get_node_by_name };
    ($@) or ( carp('get_node_by_name() with no param') and return 0 );
    eval { $object->get_node_by_name('Not-A-Valid-Node-Name') };
    ($@) or ( carp('get_node_by_name() with invalid node name') and return 0 );
    eval { $object->get_node_by_name($from_station) };
    ($@) and ( carp($@) and return 0 );

    return 1;
}

sub _ok_map_routes {
    my ( $object, $routes ) = @_;
    return 0 unless ( defined $object && $object->does('Map::Tube') );
    eval { $object->get_map_data };
    ($@) and ( carp('no map data found') and return 0 );
    my @failed;
    foreach (@$routes) {
        chomp;
        next if /^\#/;
        next if /^\s+$/;
        my ( $description, $from, $to, $route ) = split /\|/;
        my $got = $object->get_shortest_route( $from, $to );
        my $expected = _expected_route( $object, $route );
        next if Compare( $got, $expected );
        push @failed, [ $got, $expected, $description ];
    }
    return @failed;
}

sub _expected_route {
    my ($object, $route) = @_;

    my $nodes   = [];
    foreach my $name ( split /\,/,$route ) {
        my @_names = $object->get_node_by_name($name);
        push @$nodes, $_names[0];
    }

    return Map::Tube::Route->new(
       { from  => $nodes->[0],
         to    => $nodes->[-1],
         nodes => $nodes
       });
}


sub _emit_diagnostics($$$$$$) {
    # Handle the nitty-gritty of producing (negative) diagnostics in various contexts
    my( $name, $want_array, $ok, $msg, $results, $max_msg ) = @_;
    my $tb = Test::More->builder( );
    my $test_level = $tb->level( );
    $tb->level( $test_level+1 );

    if ($want_array) {
        $ok = 0;
    } else {
        diag($msg) if ( !$max_msg || ( scalar( @{ $results } ) < $max_msg ) );
        $ok &&= $tb->ok( 0, $name );
    }
    push( @{ $results }, $msg ) if ( !$max_msg || ( scalar( @{ $results } ) < $max_msg ) );

    $tb->level( $test_level );
    return $want_array ? ( $ok, @{ $results } ) : $ok;
}


use Carp;

sub _prepare_raw_map {
  # analyse the original map data (XML or JSON) and store it
  # surreptitiously in the Map::Tube object for later use.
  my $map = shift;
  return _prepare_xml_map($map ) if $map->can('xml');
  return _prepare_json_map($map) if $map->can('json');
  croak( "Don't know how to access underlying map data" );
}


sub _prepare_xml_map {
  # analyse the original map data (XML format) and store it
  # surreptitiously in the Map::Tube object for later use.
  eval 'use XML::Twig';
  plan skip_all => 'XML::Twig required' if $@;

  my $map = shift;
  my $xml = XML::Twig->new( );
  $xml->parsefile( $map->xml( ) );
  my $root = $xml->root( );
  my( %line_names,            %line_names_uc,       %line_ids_defined, %line_ids_used,              %line_ids_indexed,
      %line_id_has_indices, %other_link_used,
      %station_names,        %station_ids_defined, %station_ids_used, %station_linked_to_stations, %station_served_by_lines,
      %station_line_count,
    );

  my $line = $root->first_child('lines')->first_child('line');
  while ($line) {
    my $id     = $line->att('id');
    my $name = $line->att('name');
    $line_names_uc{uc($name)} //= { };
    $line_names{$name} //= [ ];
    $line_names_uc{uc($name)}{$name}++;
    push( @{ $line_names{$name} }, $id );
    $line_ids_defined{$id}++;
    $line_ids_used{$id}    = 0;
    $line_ids_indexed{$id} = 0;
    $line = $line->next_sibling( );
  }

  my $station = $root->first_child('stations')->first_child('station');
  while ($station) {
    my $id      = $station->att('id');
    my $name  = $station->att('name');
    $station_names{$name} //= [ ];
    push( @{ $station_names{$name} }, $id );
    $station_ids_defined{$id}++;
    $station_ids_used{$_}++                   for map { ( split(/:/) )[0] } split( /,/, $station->att('link') );
    $station_linked_to_stations{$id}{$_} |= 1 for map { ( split(/:/) )[0] } split( /,/, $station->att('link') );

    for ( map { ( split( /:/) )[0] } split( /,/, $station->att('line') ) ) {
      $line_ids_used{$_}++;
      $station_served_by_lines{$id}{$_} |= 1;
      $station_line_count{$id}{$_}++;
    }
    for ( grep { scalar( split(/:/) ) > 1 } split( /,/, $station->att('line') ) ) {
      my( $line, $idx ) = split( /:/, $_ );
      $line_ids_indexed{$line}++;
      $line_id_has_indices{$line}{$idx}++;
    }

    if ( defined( $station->att('other_link') ) ) {
      for my $other_link ( split( /,/, $station->att('other_link') ) ) {
        my( $ol, $target ) = split( /:/, $other_link );
        $other_link_used{$ol}++;
        $station_ids_used{$target}++;
        $station_linked_to_stations{$id}{$target} |= 2;
        $station_served_by_lines{$id}{$ol}          |= 2;
      }
    }

    $station = $station->next_sibling( );
  }

  $map->{_rawinfo} = { line_names                  => \%line_names,
                       line_names_uc              => \%line_names_uc,
                       line_ids_defined           => \%line_ids_defined,
                       line_ids_used              => \%line_ids_used,
                       line_ids_indexed           => \%line_ids_indexed,
                       line_id_has_indices          => \%line_id_has_indices,
                       station_names              => \%station_names,
                       station_ids_defined          => \%station_ids_defined,
                       station_ids_used           => \%station_ids_used,
                       station_line_count          => \%station_line_count,
                       other_link_used              => \%other_link_used,
                       station_linked_to_stations => \%station_linked_to_stations,
                       station_served_by_lines      => \%station_served_by_lines,
                     };
  return $map;
}


sub _prepare_json_map {
  # analyse the original map data (JSON format) and store it
  # surreptitiously in the Map::Tube object for later use.
  eval 'use Map::Tube::Utils';
  plan skip_all => 'Map::Tube::Utils required (should have been installed along with Map::Tube)' if $@;

  my $map = shift;
  my( %line_names,            %line_names_uc,       %line_ids_defined, %line_ids_used,              %line_ids_indexed,
      %line_id_has_indices, %other_link_used,
      %station_names,        %station_ids_defined, %station_ids_used, %station_linked_to_stations, %station_served_by_lines,
      %station_line_count,
    );

  my $json = Map::Tube::Utils::to_perl( $map->json( ) );

  for my $line ( @{ $json->{lines}{line} } ) {
    my $id     = $line->{id};
    my $name = $line->{name};
    $line_names_uc{uc($name)} //= { };
    $line_names{$name} //= [ ];
    $line_names_uc{uc($name)}{$name}++;
    push( @{ $line_names{$name} }, $id );
    $line_ids_defined{$id}++;
    $line_ids_used{$id}    = 0;
    $line_ids_indexed{$id} = 0;
  }

  for my $station ( @{ $json->{stations}{station} } ) {
    my $id      = $station->{id};
    my $name  = $station->{name};
    $station_names{$name} //= [ ];
    push( @{ $station_names{$name} }, $id );
    $station_ids_defined{$id}++;
    $station_ids_used{$_}++                   for map { ( split(/:/) )[0] } split( /,/, $station->{link} );
    $station_linked_to_stations{$id}{$_} |= 1 for map { ( split(/:/) )[0] } split( /,/, $station->{link} );

    for ( map { ( split( /:/) )[0] } split( /,/, $station->{line} ) ) {
      $line_ids_used{$_}++;
      $station_served_by_lines{$id}{$_} |= 1;
      $station_line_count{$id}{$_}++;
    }
    for ( grep { scalar( split(/:/) ) > 1 } split( /,/, $station->{line} ) ) {
      my( $line, $idx ) = split( /:/, $_ );
      $line_ids_indexed{$line}++;
      $line_id_has_indices{$line}{$idx}++;
    }

    if ( exists( $station->{other_link} ) ) {
      for my $other_link ( split( /,/, $station->{other_link} ) ) {
        my( $ol, $target ) = split( /:/, $other_link );
        $other_link_used{$ol}++;
        $station_ids_used{$target}++;
        $station_linked_to_stations{$id}{$target} |= 2;
        $station_served_by_lines{$id}{$ol}          |= 2;
      }
    }

  }

  $map->{_rawinfo} = { line_names                  => \%line_names,
                       line_names_uc              => \%line_names_uc,
                       line_ids_defined           => \%line_ids_defined,
                       line_ids_used              => \%line_ids_used,
                       line_ids_indexed           => \%line_ids_indexed,
                       line_id_has_indices          => \%line_id_has_indices,
                       station_names              => \%station_names,
                       station_ids_defined          => \%station_ids_defined,
                       station_ids_used           => \%station_ids_used,
                       station_line_count          => \%station_line_count,
                       other_link_used              => \%other_link_used,
                       station_linked_to_stations => \%station_linked_to_stations,
                       station_served_by_lines      => \%station_served_by_lines,
                     };
  return $map;
}

1;

__END__


=head1 METHODS


=head2 The portmanteau tests


=head3 ok_map_functions( $map [, $message ] )

Validates the map functions. As its first argument, it expects an object of a package
that has taken the Moo role L<Map::Tube>. You can  optionally pass a C<$message>
that will be printed in case of a problem. For an example, see the L</SYNOPSIS>.
For this method, you would require C<Map::Tube> v3.75 or above.

This test should always run when installing.


=head3 ok_map_routes( $map, \@routes [, $message ] )

Validates the given routes. It expects an object of a package that has taken the Moo
role L<Map::Tube> and a reference to an array of strings each of which describes a route's
details in the format shown below:

    my @routes = (
        "Route 1|A1|A3|A1,A2,A3",
        "Route 2|A1|B1|A1,A2,B1",
    );

There are four elements for each route, separated by the C<|> character. The first element of
each route specification is a purely informative name. The next element is the name of a
starting station in the tube system, then the name of a target station. Finally, there is a
list of stations that the route is expected to be comprised of, including the starting and the
target station. The stations must be separated by a blank and a comma. For an example, see the
L</SYNOPSIS>. You can optionally pass a C<$message>.
For this method, you would require C<Test::Map::Tube> v0.15 or above.

This test should always run when installing.


=head3 ok_map_data($map [, \%args, $message ] )

Validates the map data. It expects an object of a package that has taken the Moo role
L<Map::Tube>. You can optionally pass arguments as described below and/or a C<$message>.
(If the second argument is a string, it is assumed to be the C<$message>.)
For full use of this method, you would require C<Test::Map::Tube> v3.93 or above.

This method is mainly of use while developing a map. It is designed to catch most (formal)
problems that are frequently introduced into the map data structures, usually by accident or
oversight, due to the complex nature of the structures. As such, it is a good strategy to
configure this test so that it is not run during installation by the end user, as shown
in the first example in the L</SYNOPSIS> above.

By default, this method just runs almost all of the individual tests described below. The only
exceptions (by default) are tests that have a substantial chance of flagging false positives, i.e.,
L<ok_station_names_different( )|/ok_station_names_different-map-args>,
L<ok_station_names_complete( )|/ok_station_names_complete-map-args>, and
L<ok_links_bidirectional( )|/ok_links_bidirectional-map-args>.
For details, see those individual methods below. A test using C<ok_map_data( )> counts as just one
test, no matter how many individual tests will be performed.

Thus, the most common way of using this method is as indicated in the first example in the
L</SYNOPSIS>. However, you are encouraged to include also the optional tests as described below.

The tests to be run can be configured by the (optional) second argument, which should be a hash
reference. The underlying hash may contain one or more of the following:

=over 4

=item * Under the key C<name> a name which will be displayed (possibly alongside a C<$message>)
        in case of a failing test.

=item * Under the key C<message> an additional message. This is just an alternative to specifying
        C<$message> as a third parameter.

=item * Under the key C<max_messages> a maximum number of messages on failed test items. This may
        be useful during early development phases in order not become overwhelmed.

=item * The name of any of the individual tests below may be used as a key. In this case, the value
        may be one of the following:

=over 4

=item * C<undef> or any other false value. In this case, the named test will not be performed (although
        by default it might).

=item * 1 or any other scalar regarded by Perl as true. In this case, the named test will be performed
        (although by default it might not), providing no further arguments to the test.

=item * A hash reference. In this case, the named test will be performed (although by default it might
        not), where the hash reference will be passed to the test as arguments.

=back

=back

If the method is called in a void or a scalar context, the tests are performed and diagnostics
on any issues will be output to STDERR. The return value will be true (if all individual tests
have passed) or false (fail). If the method is called in a list context, no diagnostics are
output. Instead, they are all gathered. The return value is either a list containing a single
true value (in case of all individual tests having passed), or it will be a list of a false value,
followed by the individual diagnostic messages. In this case it is the responsibility of the
caller to display these values in an appropriate fashion.

Here are two full examples:

    ok_map_data( Map::Tube::London->new,
                 { ok_map_connected => undef, # Do not check whether the map is connected
				   ok_links_bidirectional => { exclude => [ 'Elizabeth', 'Piccadilly' ] },
                                              # Do check whether all lines are fully bidirectional,
                                              # except the two named lines
                   ok_station_names_different => 1, # Check for similar-looking names
                 }
               );

    my( $ok, @messages) = ok_map_data( Map::Tube::London->new ); # perform default tests


=head3 ok_map( $map [, \%args, $message ] )

This is a synonym for L<ok_map_data( )|/ok_map_data-map-args-message>, for backward compatibility.


=head3 not_ok_map_data( $map [, \%args, $message ] )

This is the negation of L<ok_map_data( )|/ok_map_data-map-args-message>. It is used very rarely, if ever.


=head3 not_ok_map( $map [, \%args, $message ] )

This is a synonym for L<not_ok_map_data( )|/not_ok_map_data-map-args-message>, for backward compatibility.


=head2 The individual developer tests for the map as a whole


=head3 ok_map_loadable( $map [, \%args] )

Checks whether the map object is defined, looks like a Map::Tube object and contains valid data as
per Map::Tube built-in base line checks. It does not perform any deep data validity checks beyond.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.

The other individual tests presuppose that the map has successfully loaded, so it is good practice
to always check this condition first.


=head3 ok_map_connected( $map [, \%args] )

Checks whether the whole map is connected, i.e., whether there are routes between any two stations.
(This test disregards whether some links are unidirectional.)
If so, it checks reachability when honouring unidirectionality (if any); this is a stricter test.
If either form of universal reachability is not given, the diagnostics provide examples of stations
in different components.

It is extremely rare for maps not to be connected; hence, this test will catch many cases of
erroneously unidirectional links. However, for the case where a map is known not to be connected,
the expected maximum number of components may be specified in the optional arguments, using the
key C<max_allowed>. The value defaults to 1.

Otherwise, the only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head2 The individual developer tests focussing on lines


=head3 ok_line_definitions( $map [, \%args] )

Checks whether any line IDs contain a comma or a colon, which is forbidden for syntactical reasons.
Also checks whether color specifications are either a standard hex HTML color code (#RRGGBB) or
a name from a pre-defined set of color names (see L<Map::Tube::Utils>).

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_line_names_unique( $map [, \%args] )

Checks whether line names are unique, even when disregarding case.
(Station names must also be unique, but this is checked by L<Map::Tube> on load, so we do
not need to repeat that test.)

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_line_ids_unique( $map [, \%args] )

Checks whether line ids are unique. Note that line IDs (as opposed to station IDs) are
case-sensitive, i.e., C<"LINE"> and C<"line"> are two different lines.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_lines_used( $map [, \%args] )

Checks whether all the lines defined in the map are actually serving at least two stations
(either as an ordinary line or using the C<other_link> construct).
(Conversely, all lines serving some station must be defined in the map (except for lines
used within the C<other_link> construct), but this is already checked by L<Map::Tube>, so
we do not ned to repeat that test.) Also, lines must not come up both in ordinary links
and in C<other_link>.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_lines_indexed( $map [, \%args] )

Checks whether each line has either all or no station at all indexed (but not some aye,
some nay). Example: If there is a station with an attribute such as C<line="LINE1:42">,
then there must not be any station with the attribute C<line="LINE1">. (This is a
syntactical requirement of L<Map::Tube> needed for proper functioning.)

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_lines_run_through( $map [, \%args] )

Checks whether each line is at least weakly connected, i.e., there should be no gaps
in any lines (at least not when disregarding directionality).

It is extremely rare for lines not to be (weakly) connected; hence, this test will catch many
cases of erroneously missing links. However, for the case where a line is known not to be
connected, one or more lines can be exempted from this check. Use the optional hash ref argument
with the key C<exclude>; the value may be a single line ID (not a line name!) or a reference to
a list of line IDs. Here are two examples:

    ok_lines_run_through( Map::Tube::London->new, { exclude => 'Piccadilly' } );

    ok_lines_run_through( Map::Tube::London->new, { exclude => [ 'Piccadilly', 'Jubilee' ] } );

Otherwise, the only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_links_bidirectional( $map [, \%args] )

Checks whether all links are bidirectional, i.e., whether all links work symmetrically in both
directions. Note that it is perfectly legal for this not to be the case, however, so this is a
fallible test. For this reason, this is one of the tests that is not performed by
L<ok_map_data( )|/ok_map_data-map-args-message> by default, because the rate of false positives is considered to be too high.

It is, however, good practice to include this optional test when starting to develop a map,
because it catches a substantial part of hard-to-notice accidental omissions of links. If
your map turns out to include lines that have (at least partially) unidirectional links, this
will most likely be confined to one or very few lines. In this case, use the optional hash
ref argument with the key C<exclude>; the value may be a single line ID (not a line name!)
or a reference to a list of line IDs. Here are two examples:

    ok_links_bidirectional( Map::Tube::London->new, { exclude => 'Piccadilly' } );

    ok_links_bidirectional( Map::Tube::London->new, { exclude => [ 'Piccadilly', 'Elizabeth' ] } );

Otherwise, the only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head2 The individual developer tests focussing on stations


=head3 ok_station_ids( $map [, \%args] )

Checks whether any station IDs contain a comma or a colon, which is not allowed for syntactical reasons.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_station_names_different( $map [, \%args] )

Station names must be unique, but since L<Map::Tube> already tests this on init, we do not
repeat this test here. Instead, this method checks whether no two station names look
"similar enough" to assume one might be a typo for the other. Name similarity is determined
using the Levenshtein edit distance (see L<Text::Levenshtein::XS>). By default, any two names
having a distance of at most 2 are considered "too similar".

It is, of course, perfectly legal for two station names to look "similar". Hence, this is in
many ways a fallible test and cannot be applied indiscriminately. For that reason, it is not
among the tests carried out by L<ok_map_data( )|/ok_map_data-map-args-message> by default. During development, it is
nevertheless a good idea to use this test. It can be tweaked in two ways using the optional
hash ref argument in order to prevent over-alerting. Both ways may be used at the same time.

=over 4

=item * Use the hash key C<dist_limit> to set the maximum ciritical distance to a value other
        than 2. Setting it to 3 or more will in general produce more hits, setting it to 1 will
        in general produce fewer hits, and setting it to 0 will disable this test.

=item * Use the hash key C<max_allowed> to declare that a certain number of hits is expected
        and is not considered to be problematic. Only if this threshold is exceeded will the
        test be considered a fail.

=back

Two examples:

    ok_station_names_different( Map::Tube::London->new, { dist_limit => 1 } )

    ok_station_names_different( Map::Tube::London->new, { dist_limit => 1, max_allowed => 3 } )

While this test is useful to find accidental typos, there do exist maps where the false positive
rate is so high that this test becomes useless.

Otherwise, the only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_station_names_complete( $map [, \%args] )

This checks whether no station name is a proper prefix of another station's name. This catches
accidental double entries for a single station, e.g. once as C<Baker St> and once as
C<Baker Street>.

It is, of course, perfectly legal for such a situation to happen, e.g., C<New Cross> and
C<New Cross Gate>. Hence, this is in many ways a fallible test and cannot be applied
indiscriminately. For that reason, it is not among the tests carried out by L<ok_map_data( )|/ok_map_data-map-args-message>
by default. During development, it is nevertheless a good idea to use this test. It can be
tweaked using the optional hash ref argument with the key C<max_allowed> to declare that a
certain number of hits is expected and is not considered to be problematic. Only if this
threshold is exceeded will the test be considered a fail. The default threshold is 0 so that
all issues will be reported, but if you know that your map contains five legitimate pairs of
such station names, specify C<{ max_allowed =E<gt> 5 }>.

Otherwise, the only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_stations_linked( $map [, \%args] )

This checks whether all stations that are named as the target of a link are also explicitly
declared as a station.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_stations_self_linked( $map [, \%args] )

This checks whether any station declares a link to itself, which should not happen.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_stations_multilinked( $map [, \%args] )

This checks whether any station lists another station as the target of a link more than once.
(Any two stations may be linked by more than one line, but the link should still name
each linked station once only.)

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_stations_multilined( $map [, \%args] )

This checks whether any station lists the same line more than once. (This applies only to regular
lines using the C<line> attribute. By contrast, in C<other_link> it is perfectly normal for any
given "line" to occur more than once.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head3 ok_stations_linked_share_lines( $map [, \%args] )

This checks whether two stations that are linked share at least one line (via an ordinary link
or via C<other_link>). Conversely, it checks whether lines serving a particular station (as per
the ordinary C<line> attribute) are also listed as serving one of the linked stations using the
C<line> attribute. E.g., if a station with ID C<A> has the attributes C<line="Line1" link="B,C">,
then at least one of the stations C<B> and C<C> must also contain C<line="Line1">.

Finally, lines named within an C<other_link> at some station must also occur within an
C<other_link> at the target station. E.g., if station with ID C<D> has the attribute
C<other_link="tunnel:E">, then station C<E> must have the attribute C<other_link="tunnel:D">.

The only optional arguments used are C<name> and C<max_messages>, as described for
L<ok_map_data( )|/ok_map_data-map-args-message>. The return value is as for L<ok_map_data( )|/ok_map_data-map-args-message>.


=head1 CONTRIBUTORS

=over 2

=item * Ed J

=item * Gisbert W. Selke, C<< <gws@cpan.org> >>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Map::Tube

You can also look for information at:

=over 4

=item * perldoc Map::Tube

=item * BUG Report

L<https://github.com/manwar/Map-Tube/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2025 Mohammad Sajid Anwar.

This  program  is  free software; you can redistribute it  and/or modify it under
the  terms  of the the Artistic License (2.0). You may  obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# End of Test::Map::Tube
