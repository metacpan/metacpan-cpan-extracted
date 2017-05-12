#
# $Id$
#

use strict;
use warnings;
use 5.010;

package Geo::Parse::OSM;
BEGIN {
  $Geo::Parse::OSM::VERSION = '0.42';
}
use base qw{ Exporter };

our @EXPORT_OK = qw(
    object_to_xml
);

=head1 NAME

Geo::Parse::OSM - OpenStreetMap XML file regexp parser

=head1 VERSION

version 0.42

=head1 SYNOPSIS

    use Geo::Parse::OSM;

    my $osm = Geo::Parse::OSM->new( 'planet.osm.gz' );
    $osm->seek_to_relations;
    $osm->parse( sub{ warn $_[0]->{id}  if  $_[0]->{user} eq 'Alice' } );

=cut


use Carp;

use Encode;
use HTML::Entities;
use IO::Uncompress::AnyUncompress qw($AnyUncompressError);




=head1 METHODS

=head2 new

Creates parser instance and opens file

    my $osm = Geo::Parse::OSM->new( 'planet.osm' );

Compressed files (.gz, .bz2) are also supported.

=cut

sub new {
    my $class = shift;

    my $self = {
        file        => shift,
        node        => undef,
        way         => undef,
        relation    => undef,
    };

    $self->{stream} = IO::Uncompress::AnyUncompress->new( $self->{file}, MultiStream => 1 )
        or croak "Error with $self->{file}: $AnyUncompressError";

    bless ($self, $class);
    return $self;
}




=head2 parse

Parses file and executes callback function for every object.
Stops parsing if callback returns 'stop'

    $osm->parse( sub{ warn $_[0]->{id} and return 'stop' } );

It's possible to filter out unnecessary object types

    $osm->parse( sub{ ... }, only => 'way' );
    $osm->parse( sub{ ... }, only => [ 'way', 'relation' ] );

=cut

my @obj_types = qw{ node way relation bound bounds };
my $obj_types = join q{|}, @obj_types;

sub parse {

    my $self = shift;
    my $callback = shift;

    my %prop = @_;

    my %filter;
    %filter = map { $_ => 1 } @{ $prop{only} }  if exists $prop{only} && ref $prop{only};
    %filter = ( $prop{only} => 1 )              if exists $prop{only} && !ref $prop{only};

    my %object;

    if ( exists $self->{saved} ) {
        my $res = &$callback( $self->{saved} );

        delete $self->{saved}   unless defined $res && $res eq 'stop' && $prop{save};
        return  if  defined $res && $res eq 'stop';
    }

    my $pos = tell $self->{stream};

    LINE:
    while ( my $line = decode( 'utf8', $self->{stream}->getline() ) ) {

        # start of object
        if ( my ($obj) = $line =~ m{ ^\s* <($obj_types) }xo ) {

            $self->{$obj} = $pos    unless defined $self->{$obj};
            
            next LINE if %filter && !exists $filter{$obj};

            %object = ( type => $obj );
            
            # ALL attributes
            my @res = $line =~ m{ (?<attr>\w+) = (?<q>['"]) (?<val>.*?) \k<q> }gx;
            while (@res) {
                my ( $attr, undef, $val ) = ( shift @res, shift @res, shift @res );
                $object{$attr} = decode_entities( $val );
            }
        }
        # tag
        elsif ( %object  &&  $line =~ m{ ^\s* <tag.*? \bk = (?<q>["']) (?<key>.*?) \k<q> .*? \bv = \k<q> (?<val>.*?) \k<q> }x ) {
            $object{tag}->{ $+{key} } = decode_entities( $+{val} );
        }
        # node ref
        elsif ( %object  &&  $line =~ m{ ^\s* <nd.*? \bref = (?<q>["']) (?<nref>.*?) \k<q> }x ) {
            push @{$object{chain}}, $+{nref};
        }
        # relation member
        elsif ( %object  &&  $line =~ m{ ^\s* <member.*? \btype = (?<q>["']) (?<type>.*?) \k<q> .*? \bref = \k<q> (?<ref>.*?) \k<q> .*? \brole = \k<q> (?<role>.*?) \k<q> }x ) {
            push @{$object{members}}, { type => $+{type}, ref => $+{ref}, role => $+{role} };
        }


        # end of object
        if ( %object  &&  $line =~ m{ ^\s* <(?: / $object{type} | $object{type} .* / > ) }x ) {
            my $res = &$callback( \%object );
            if ( defined $res && $res eq 'stop' ) {
                $self->{saved} = \%object    if $prop{save};
                return;
            }
            %object = ();
        }

    } continue { $pos = tell $self->{stream} }

    for my $type ( qw{ node way relation } ) {
        $self->{$type} = $pos    unless defined $self->{$type};
    }
}


=head2 seek_to

Seeks to the file position or to the first object of selected type.

    $osm->seek_to( 0 );
    $osm->seek_to( 'way' );

Can be slow on compressed files!

=cut

sub seek_to {
    my $self = shift;
    my $obj = shift;

    if ( !exists $self->{$obj} || defined $self->{$obj} ) {
        delete $self->{saved};
        my $pos = exists $self->{$obj} ? $self->{$obj} : $obj;
        $self->{stream} = IO::Uncompress::AnyUncompress->new( $self->{file}, MultiStream => 0|1 )
            if tell $self->{stream} > $pos;
        seek $self->{stream}, $pos, 0;
    }
    else {
        parse( $self, sub{ 'stop' }, only => $obj, save => 1 );
    }
}


=head2 seek_to_nodes

=head2 seek_to_ways

=head2 seek_to_relations

    $osm->seek_to_ways;     # same as seek_to('way');

=cut

sub seek_to_nodes     {  return seek_to( shift(), 'node' )  }

sub seek_to_ways      {  return seek_to( shift(), 'way' )  }

sub seek_to_relations {  return seek_to( shift(), 'relation' )  }


=head2 parse_file

Class method - creates parser instance and does one parser() pass.
Returns created parser object.

    use Data::Dumper;
    Geo::Parse::OSM->parse_file( 'planet.osm', sub{ print Dumper $_[0] } );

=cut

sub parse_file {
    my $class = shift;

    my ( $file, $callback ) = @_;

    my $obj = $class->new( $file );
    $obj->parse( $callback ); 

    return $obj;
}



=head1 FUNCTIONS

=head2 object_to_xml

Returns xml representation of the callback object.

    sub callback {
        print Geo::Parse::OSM::object_to_xml( shift @_);
    }
    Geo::Parse::OSM->parse_file( 'planet.osm', \&callback );

=cut

my @attrorder = qw(
    action
    id
    lat
    lon
    version
    changeset
    visible
    timestamp
    user
    uid
);

my %attrorder = map { $attrorder[$_-1] => $_ } ( 1 .. scalar @attrorder );

my $enc = q{\x00-\x19<>&"'};


sub object_to_xml {
    my %obj = %{ shift() };

    my $type = $obj{type}; 
    delete $obj{type};

    my $res = qq{  <$type }
        . join( q{ },
            map { qq{$_="} . encode( 'utf8', encode_entities( $obj{$_}, $enc ) ) . q{"} }
            grep { ! ref $obj{$_} }
            sort { (exists $attrorder{$a} ? $attrorder{$a} : 999) <=> (exists $attrorder{$b} ? $attrorder{$b} : 999) or $a cmp $b } keys %obj );

    if ( grep { ref } values %obj ) {
        $res .= qq{>\n};
        if ( exists $obj{chain} ) {
            for my $nd ( @{$obj{chain}} ) {
                $res .= qq{    <nd ref="$nd"/>\n};
            }
        }
        if ( exists $obj{members} ) {
            for my $nd ( @{$obj{members}} ) {
                $res .= qq{    <member type="$nd->{type}" ref="$nd->{ref}" role="$nd->{role}"/>\n};
            }
        }
        if ( exists $obj{tag} ) {
            for my $tag ( sort keys %{$obj{tag}} ) {
                $res .= q{    <tag k="}
                    . encode( 'utf8', encode_entities($tag, $enc) )
                    . q{" v="}
                    . encode( 'utf8', encode_entities($obj{tag}->{$tag}, $enc) )
                    . qq{"/>\n};
            }
        }
        $res .= qq{  </$type>\n};
    }
    else {
        $res .= qq{/>\n};
    }

    return $res;
}


=head1 AUTHOR

liosha, C<< <liosha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-parse-osm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Parse-OSM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Parse::OSM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Parse-OSM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Parse-OSM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Parse-OSM>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Parse-OSM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 liosha.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Geo::Parse::OSM