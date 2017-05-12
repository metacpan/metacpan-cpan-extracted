#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper::Concise;
use HTML::TreeBuilder;
use Text::Trim qw/ trim /;

my $WIKIPEDIA_URL
    = q{http://en.wikipedia.org/wiki/List_of_postcode_districts_in_the_United_Kingdom};

my $html = HTML::TreeBuilder->new_from_url($WIKIPEDIA_URL);

my ($table) = $html->look_down(
    _tag  => 'table',
    class => 'wikitable sortable'
);

my ( undef, @rows ) = $table->look_down( _tag => 'tr' );

my %districts;

foreach my $row (@rows) {

    my ( $td_area, $td_districts, $td_post_town, $td_former_post_county )
        = $row->look_down( _tag => 'td' );

    my ($area) = $td_area->content_list;

    ($area) = ( $td_area->look_down( _tag => 'a' ) )[0]->content_list
        if ref $area;

    next if $area eq 'BX';    # TODO handle BX non-geo codes

    my ($post_town)
        = ( $td_post_town->look_down( _tag => 'a' ) )[0]->content_list;

    my @found;
    foreach my $c ( $td_districts->content_list ) {
        if ( ref $c ) {
            next if $c->tag eq 'br';

            $found[-1]->{non_geographical} = 1
                if $c->attr('id') && $c->attr('id') eq 'ref_non-geo';

        } else {

            foreach ( map {trim} split /,/, trim $c ) {
                push @found,
                    {
                    district         => $_,
                    non_geographical => 0,
                    post_town        => $post_town
                    };
            }

        }
    }

    foreach my $f (@found) {
        my $district = $f->{district};

        my ( $area, $digits ) = $district =~ m{^([A-Z]+)(\d+)}
            or die "can't parse district";

        $districts{$district} ||= {
            district         => $district,
            area             => $area,
            digits           => $digits,
            post_town        => [],
            non_geographical => $f->{non_geographical},
        };

        push @{ $districts{$district}->{post_town} }, $f->{post_town};
    }

}

foreach my $district (
    sort { $a->{area} cmp $b->{area} || $a->{digits} <=> $b->{digits} }
    values %districts )
{

    printf "%s,%d,%s\n", $district->{district},
        $district->{non_geographical},
        join( ',', @{ $district->{post_town} } );
}

__END__
<tr>
<td><span id=" AB "></span><a href=" / wiki / AB_postcode_area
    " title=" AB postcode area ">AB</a></td>
<td>AB10, AB11, AB12, AB15, AB16,<br />
AB21, AB22, AB23, AB24, AB25,<br />
AB99<sup class=" reference plainlinks nourlexpansion " id=" ref_non-geo
    "><a href="    #endnote_non-geo">non-geo</a></sup></td>
    < td > <a href="/wiki/Aberdeen" title="Aberdeen"> ABERDEEN </a> < /td>
<td><a href="/ wiki / Aberdeenshire " title=" Aberdeenshire
    ">Aberdeenshire</a></td>
</tr>
<tr>
<td>AB</td>
<td>AB13</td>
<td><a href=" / wiki / Milltimber " title=" Milltimber ">MILLTIMBER</a></td>
<td>Aberdeenshire</td>
</tr>

