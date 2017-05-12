# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: Range.pm,v 1.4 2004/07/22 07:42:35 jhoblitt Exp $

package HTTP::Range;

use strict;

use vars qw( $VERSION );
$VERSION = 0.02;

require IO::String;
require HTTP::Request;
require HTTP::Response;
require Set::Infinite;
use HTTP::Status qw( RC_OK );
use Params::Validate qw( :all );
use UNIVERSAL qw( isa can );
use Carp qw( croak );

my $DEBUG = 0;

sub split
{
    my $class = shift;
 
    my %args = validate( @_,
        {
            request => {
                type        => OBJECT,
                isa         => 'HTTP::Request',
            },
            length => {
                type        => SCALAR,
                callbacks   => {
                    'length is > 0'         => sub { $_[0] > 0 },
                    'length is + integer'   => sub { $_[0] =~ /^\d+$/ },
                },
            },
            segments => {
                type        => SCALAR,
                default     => 4,
                callbacks   => {
                    'segments is > 1'       => sub { $_[0] > 1 },
                    'segments is + integer' => sub { $_[0] =~ /^\d+$/ },
                    'segments is <= length' => sub { $_[0] <= $_[1]->{ 'length' } },
                },
            },
        },
    );

    # size of byte range per requested segment
    $args{ 'seg_size' } = int ( $args{ 'length' } / $args{ 'segments' } );

    # if the length is not evenly divisible by the number of segments we have to 
    # account for the leftover bytes
    $args{ 'seg_extras' } = $args{ 'length' } % $args{ 'segments' };

    # total number of bytes to process
    $args{ 'len_remain' } = $args{ 'length' };

    my @requests;
    while ( $args{ 'len_remain' } || $args{ 'seg_extras' } ) {
        # size of this segment
        my $seg_len = $args{ 'seg_size' };

        # do we have extra bytes?
        if ( $args{ 'seg_extras' } ) {
            $seg_len++;
            $args{ 'seg_extras' }--;
        }

        # offset into length
        $args{ 'len_index' } = $args{ 'length' } - $args{ 'len_remain' };
        
        # bytes remaining
        $args{ 'len_remain' } -= $seg_len;

        # copy the request object - this must be a deep clone
        my $req = $args{ 'request' }->clone;

        # start-end of byte offset for this segment
        $req->header( Range => "bytes=$args{ 'len_index' }-"
                . ( $args{ 'len_index' } + $seg_len - 1 ) );

        push( @requests, $req );
    }

    return( wantarray ? @requests : \@requests );
}

sub join
{
    my $class = shift;
 
    my %args = validate( @_,
        {
            responses => {
                type        => ARRAYREF,
            },
            length => {
                type        => SCALAR,
                optional    => 1,
                callbacks   => {
                    'length is > 0'         => sub { shift > 0 },
                    'length is + integer'   => sub { $_[0] =~ /^\d+$/ },
                },
            },
            segments => {
                type        => SCALAR,
                optional    => 1,
                callbacks   => {
                    'segments is > 1'           => sub { $_[0] > 1 },
                    'segments is + integer'     => sub { $_[0] =~ /^\d+$/ },
                    'segments is == responses'  => sub {
                        $_[0] == @{ $_[1]->{ 'responses' } };
                    },
                    'segments is <= length'     => sub {
                        if ( $_[1]->{ 'length' } ) {
                            return $_[0] <= $_[1]->{ 'length' };
                        } else {
                            return 1;
                        }
                    },
                },
            },
        },
    );

    # validate each object in the responses arrayref
    foreach my $res ( @{ $args{ 'responses' } } ) {
        croak "not isa HTTP::Response" unless isa( $res, 'HTTP::Response' );
        croak "not a successful HTTP status" unless HTTP::Status::is_success( $res->code );
        croak "multi-part messages are not supported" if @{[ $res->parts ]};
        croak "segment has invalid content length" unless length $res->content == $res->content_length;
    }

    # scalar w/ IO::Handle interface to hold the reassembled segments
    my $content = IO::String->new;

    # set of content ranges processed
    my @ranges;

    # put segments in order
    my @responses = sort _byrange @{ $args{ 'responses' } };

    foreach my $res ( @responses ) {
        # figure out the offset and size of the segment and write it to the file handle
        my ( $start, $end ) = _parse_range( $res );
        my $len = $end - $start + 1;

        # add a span per content range
        push( @ranges, Set::Infinite->new( [ $start, $end ] ) );

        # seek to the appropriate location and write the current segment
        # functions (instead of methods) are used for compatibility with IO::Handle
        unless ( defined sysseek( $content, $start, 0 ) ) {
            croak "sysseeking response content";
        }
        if ( syswrite( $content, $res->content, $res->header( 'Content-Length' ), 0 ) != $len ){
            croak "syswriting response content";
        }

        # free the contents memory
        $res->content( undef );
    }

    # if a content length was specified check it against what was received
    if ( defined $args{ 'length' } ) {
        if ( $args{ 'length'} != length ${ $content->string_ref } ) {
            croak "specified content length does not equal received content length";
        }

        # create a set of spans representing our segments
        my $set = Set::Infinite->new;
        $set = $set->union( $_ ) for @ranges;
        $set = $set->integer;
        # work around a bug in Set::Infinite
        $set->_cleanup;
        warn "ranges are @ranges\n" if $DEBUG;
        warn "range set is: $set\n" if $DEBUG;

        # create a span representing our content length
        my $len_set = Set::Infinite->new( [ 0, $args{ 'length' } -1  ] );

        # look for differences between our segments and content length
        $len_set = $len_set->minus( $set );
        warn "left over set is: $len_set\n" if $DEBUG;
        croak "missing or incomplete segments" if $len_set;
    
    }

    # sort the segment spans
    # these should already be in order as they were created in order of the
    # sorted responses
    @ranges = sort { $a <=> $b } @ranges;

    # look for spans (segments) that overlap each other
    my $last_span;
    foreach my $span ( @ranges ) {
        if ( ! defined( $last_span ) ) {
            $last_span = $span;
            next;
        }

        croak "segments overlap" if $last_span->intersection( $span );
    }

    # create the return HTTP::Response object as a clone of the first object passed in
    my $r =  @{ $args{ 'responses' } }[0]->clone;

    # attempt to look like a single request by removing the Content-Range and
    # resetting the HTTP status code + message
    $r->remove_header( 'Content-Range' );
    $r->code( RC_OK );
    $r->message( HTTP::Status::status_message( $r->code ) );

    # set the content and it's length
    $r->content_ref( $content->string_ref );
    $r->header( content_length => length ${ $r->content_ref } );
    
    return( $r );
}

sub _parse_range
{
    my $res = shift;

    return $res->header( 'Content-Range' ) =~ /bytes (\d+)-(\d+)/;
}

sub _byrange
{
    (_parse_range( $a ))[0] <=> (_parse_range( $b ))[0];
}

1;

__END__
