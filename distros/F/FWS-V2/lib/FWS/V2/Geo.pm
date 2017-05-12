package FWS::V2::Geo;

use 5.006;
use strict;
use warnings;

=head1 NAME

FWS::V2::Geo - Framework Sites version 2 geo location methods

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;

    my $fws = FWS::V2->new();

    #
    # Return the center of grand rapids michigan zip codes
    #
    my %locationCenterHash = $fws->locationCenterHash( city => 'Grand Rapids', state => 'mi' );



=head1 DESCRIPTION

Framework Sites version 2 geographic methods for use with zip code and city searching.

=head1 METHODS


=head2 countryArray

Return the array of countries from the DB with name, twoCharacter, and threeCharacter keys.

=cut

sub countryArray {
    my ( $self, %paramHash ) = @_;
    my %countryHash;
    my @countryArray;
    my @countryPull;

    if ( !$paramHash{countryCode} ) { @countryPull = @{$self->runSQL( SQL => "select name,twoCharacter,threeCharacter from country" )} }
    else { @countryPull = @{$self->runSQL( SQL => "select name,twoCharacter,threeCharacter from country where twoCharacter like '" . $self->safeSQL( $paramHash{countryCode} ) . "' LIMIT 1" )} }

    if ( !@countryPull ) {
        $countryHash{name}            = 'United States';
        $countryHash{twoCharacter}    = 'US';
        $countryHash{threeCharacter}  = 'USA';
        push( @countryArray, {%countryHash} );
    }
    else {
        while ( @countryPull ) {
            $countryHash{name}              = shift( @countryPull );
            $countryHash{twoCharacter}      = shift( @countryPull );
            $countryHash{threeCharacter}    = shift( @countryPull );
            push( @countryArray, {%countryHash} );
        }
    }
    return @countryArray;
}



=head2 locationCenterHash

Find the lat and long of a city based on its zip codes located in it.

=cut

sub locationCenterHash {
    my ( $self, %paramHash ) = @_;

    my $whereStatement = '1=1';

    #
    # if state is passed constrain to that
    #
    if ( $paramHash{state} && $paramHash{city} ) { $whereStatement .= " and city like '" . $self->safeSQL( $paramHash{city} ) . "' and stateAbbr like '" . $self->safeSQL( $paramHash{state} ) . "'" }

    #
    # if zip is passed constrain to that
    #
    if ( $paramHash{zip} ) { $whereStatement .= " and zipCode like '" . $self->safeSQL( $paramHash{zip} ) . "'" }

    my @zipArray = @{$self->runSQL( SQL => "select latitude,longitude from zipcode where " . $whereStatement )};

    my $dirCount;
    my $totalLat;
    my $totalLong;
    while ( @zipArray ) {
        $dirCount++;
        my $lat     = shift( @zipArray );
        my $long    = shift( @zipArray );
        $totalLat  += $lat;
        $totalLong += $long;
    }
    $paramHash{locationCount} = $dirCount;
    if ( $dirCount > 0 ) {
        $paramHash{latitude}  = $totalLat / $dirCount;
        $paramHash{longitude} = $totalLong / $dirCount;
    }
    return %paramHash;
}


=head2 cityArray

return a list of cities based on keywords, state, or autoComplete style which will search based on an uncomplete query text.

=cut

sub cityArray {
    my ( $self, %paramHash ) = @_;
    my $city            = $self->safeSQL( $paramHash{city} );
    my $keywords        = $self->safeSQL( $paramHash{keywords} );
    my $state           = $self->safeSQL( $paramHash{state} );
    my $autoComplete    = $self->safeSQL( $paramHash{autoComplete} );

    
    my $whereStatement = '1=1';
    my $score = '1 as score';

    #
    # if state is passed constrain to that
    #    
    if ( $autoComplete ) { $whereStatement .= " and city like '" . $autoComplete . "%'" }
    
    #
    # if state is passed constrain to that
    #    
    if ( $state ) { $whereStatement .= " and stateAbbr like '" . $state . "'" }

    #
    # if city is passed constrain to that
    #    
    if ( $city ) { $whereStatement .= " and city like '" . $city . "'" }

    #
    # if keywords is passed constrain to that
    #    
    if ( $keywords ) { 
        $score = "match(city) against('" . $keywords . "' IN NATURAL LANGUAGE MODE) as score";
        $whereStatement .= " and match(city) against('" . $keywords . "' IN NATURAL LANGUAGE MODE)";
    }

    my @zipcodes = @{$self->runSQL( SQL =>  "select city, " . $score . ",zipCode, stateAbbr,areaCode,UTC,latitude,longitude from zipcode where " . $whereStatement . " order by score desc" )};

    my @returnArray;
    while ( @zipcodes ) {
        my %zipHash;
        $zipHash{city}        = shift( @zipcodes );
        $zipHash{score}       = shift( @zipcodes );
        $zipHash{zip}         = shift( @zipcodes );
        $zipHash{state}       = shift( @zipcodes );
        $zipHash{areaCode}    = shift( @zipcodes );
        $zipHash{UTC}         = shift( @zipcodes );
        $zipHash{latitude}    = shift( @zipcodes );
        $zipHash{longitude}   = shift( @zipcodes );
        push( @returnArray, {%zipHash} );
    }
    
    return @returnArray;
}


=head2 updateZipArray

Recompile a zip code array adding extra keys that relate to the passed zip code.

The following keys will be added:
    zipState
    zipStateAbbr
    zipAreaCode
    zipUTC
    zipLatitude
    zipLongitude
    zipCounty
    zipDistance

=cut

sub updateZipArray {
    my ( $self, $fromZip, @dataArray ) = @_;
    #
    # clean the from zip
    #
    $fromZip = $self->safeSQL( $fromZip );

    #
    # get the zipArray and create a , delemented string or the sql
    #
    my @zipArray;
    for my $i ( 0 .. $#dataArray ) {
        if( $dataArray[$i]{zip} =~ /^\d{5}$/ ) {push( @zipArray,$dataArray[$i]{zip} ) }
    }

    #
    # convert the zip into an array
    #
    my $destIn = join( ',', @zipArray );

    #
    # trap to make sure its not blank
    #
    $destIn ||= '0';

    #
    # build the SQL
    #
    my $SQL = "select distinct destination.zipCode,destination.stateAbbr,destination.areaCode,destination.UTC,";
    $SQL .= "destination.latitude,destination.longitude,";
    $SQL .= " round(3956 * 2 * ASIN(SQRT( ";
    $SQL .=     " POWER(SIN((origin.latitude - destination.latitude) * 0.0174532925 / 2), 2) +";
    $SQL .=     " COS(origin.latitude * 0.0174532925) * ";
    $SQL .=     " COS(destination.latitude * 0.0174532925) * ";
    $SQL .=     " POWER(SIN((origin.longitude - destination.longitude) * 0.0174532925 / 2), 2) "; 
    $SQL .= " ))) as distance ";
    $SQL .= " from zipcode origin, zipcode destination ";
    $SQL .= " where origin.zipCode = '" . $self->safeSQL( $fromZip ) . "' and destination.zipCode in (" . $self->safeSQL( $destIn ) .") ";


    
    #
    # execute the array
    #
    my @distanceArray = @{$self->runSQL( SQL => $SQL )};
       
    #
    # loop though the array creating an hash array
    # 
    my %zipHash;
    while ( @distanceArray ) {
        my $zip                   = shift( @distanceArray );
        $zipHash{$zip}{state}     = shift( @distanceArray );
        $zipHash{$zip}{areaCode}  = shift( @distanceArray );
        $zipHash{$zip}{UTC}       = shift( @distanceArray );
        $zipHash{$zip}{latitude}  = shift( @distanceArray );
        $zipHash{$zip}{longitude} = shift( @distanceArray );
        $zipHash{$zip}{distance}  = shift( @distanceArray );

        if ( $zip eq $fromZip ) { $zipHash{$zip}{distance} = 2 }

    }

    #
    # recycle the dataArray we started with and add the goods
    #    
    for my $i ( 0 .. $#dataArray ) {
        my $zip = $dataArray[$i]{zip};
        $dataArray[$i]{zipState}      = $zipHash{$zip}{state};
        $dataArray[$i]{zipStateAbbr}  = $zipHash{$zip}{state};
        $dataArray[$i]{zipAreaCode}   = $zipHash{$zip}{areaCode};
        $dataArray[$i]{zipUTC}        = $zipHash{$zip}{UTC};
        $dataArray[$i]{zipLatitude}   = $zipHash{$zip}{latitude};
        $dataArray[$i]{zipLongitude}  = $zipHash{$zip}{longitude};
        $dataArray[$i]{zipCounty}     = $zipHash{$zip}{county};
        $dataArray[$i]{zipDistance}   = $zipHash{$zip}{distance};
    }
    
    return @dataArray;
}       


=head2 zipHash

Return information about a zip code by passing zip

=cut

sub zipHash {
    my ( $self, %paramHash ) = @_;
    my @zipArray;
    if ( $paramHash{zip} ) {
          @zipArray = @{$self->runSQL( SQL => "select zipCode,stateAbbr,city,areaCode,UTC,latitude,longitude from zipcode where zipCode = '" . $self->safeSQL( $paramHash{zip} ) . "' limit 1" )};
    }
    if ( $paramHash{ip} ) {
        my @ipSplit     = split( /\./, $paramHash{ip} );
        my $ipNumber    = ( 16777216 * $ipSplit[0] ) + ( 65536 * $ipSplit[1] ) + ( 256 * $ipSplit[2] ) + $ipSplit[3];
        @zipArray       = @{$self->runSQL( SQL => "select zipcode.zipCode,zipcode.stateAbbr,zipcode.city,zipcode.areaCode,zipcode.UTC,zipcode.latitude,zipcode.longitude from geo_block left join zipcode on geo_block.loc_id = zipcode.loc_id  where " . $ipNumber . " > start_ip and " . $ipNumber . " < end_ip" )};
    }
    my %zipHash;
    $zipHash{zip}         = shift( @zipArray );
    $zipHash{state}       = shift( @zipArray );
    $zipHash{city}        = shift( @zipArray );
    $zipHash{areaCode}    = shift( @zipArray );
    $zipHash{UTC}         = shift( @zipArray );
    $zipHash{latitude}    = shift( @zipArray );
    $zipHash{longitude}   = shift( @zipArray );
    return %zipHash;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Geo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Geo
