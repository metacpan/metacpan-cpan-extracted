package IO::Mark::Buffer;

use strict;
use warnings;
use Carp;

use IO::Mark::Cache;

use version; our $VERSION = qv( '0.0.1' );

my %cache;

sub _cache_key {
    # This is nasty - not all handles have a fileno. I can't find any
    # other way, short of using a localised package var to share a
    # single buffer amongst multiple handles.
    return fileno shift ;
}

sub _upgrade_handle {
    my $fh  = shift;

    my $key = _cache_key( $fh );
    unless ( $cache{$key} ) {
        binmode( $fh, ':via(' . __PACKAGE__ . ')' );
    }
}

sub _get_cache {
    my $key = shift;

    return $cache{$key}
      or die "Internal: No cache for handle";
}

sub PUSHED {
    my ( $class, $mode, $fh ) = @_;

    my $key = _cache_key( $fh );
    $cache{$key} = IO::Mark::Cache->_new( $fh );

    return bless { key => $key }, $class;
}

sub READ {
    my $self = shift;

    my $cache = _get_cache($self->{key});

    my $pos = $cache->_get_master_pos;
    my $got = $cache->_read( $_[0], $_[1], $pos );
    $cache->_inc_master_pos( $got );

    return $got;
}

sub WRITE {
    my ( $self, $buffer, $fh ) = @_;

    # warn "WRITE $self, $buffer, $fh\n";

    return $fh->write( $buffer );
}

sub BINMODE {
    my ( $self, $fh ) = @_;

    # warn "BINMODE $self, $fh\n";

    # What should we do here? We don't want to be popped. Is that
    # success or failure?
    return 0;
}

sub CLOSE {
    my ( $self, $fh ) = @_;
    my $cache = _get_cache($self->{key});
    if ( 0 == $cache->_dec_ref_count ) {
        delete $cache{$self->{key}};
    }
}

1;

=head1 NAME

IO::Mark::Buffer - Stream buffer for IO::Mark

=head1 VERSION

This document describes IO::Mark version 0.0.1

=head1 SYNOPSIS

Don't use IO::Mark::Buffer directly; it has no usable public interface.
Use instead L<IO::Mark>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-mark@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
