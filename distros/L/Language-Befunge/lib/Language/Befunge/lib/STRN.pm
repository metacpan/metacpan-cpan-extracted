#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::lib::STRN;
# ABSTRACT: string extension
$Language::Befunge::lib::STRN::VERSION = '5.000';
sub new { return bless {}, shift; }

sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $b = $ip->spop_gnirts;
    my $a = $ip->spop_gnirts;
    $ip->spush_args( $b . $a );
}

sub C {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $a = $ip->spop_gnirts;
    my $b = $ip->spop_gnirts;
    $ip->spush_args( $a cmp $b );
}

sub D {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $a = $ip->spop_gnirts;
    print $a;
}

sub F {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $b = $ip->spop_gnirts;
    my $a = $ip->spop_gnirts;
    my $i = index $b, $a;
    $ip->spush_args( $i==-1 ? '' : substr $b, $i );
}

sub G {
    my ($self, $interp) = @_;
    my $ip      = $interp->get_curip;
    my $storage = $interp->get_storage;

    # pop vector
    my $pos  = $ip->spop_vec + $ip->get_storage;

    # create virtual ip to walk the storage
    my $myip = Language::Befunge::IP->new( $pos->get_dims );
    $myip->set_position($pos);

    # really walk the storage
    my $str;
    my $val = $storage->get_value( $pos );
    my %seen = ( $pos => 1 );
    while ( $val != 0 ) {
        $str .= chr $val;
        # let's move the virtual ip
        $interp->_move_ip_once($myip);
        $pos = $myip->get_position;
        return $ip->dir_reverse if $seen{$pos}++;
        $val = $storage->get_value($pos);
    }
    $ip->spush_args( $str );
}


sub I {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $in = $lbi->get_input;
    return $ip->dir_reverse unless defined $in;

    while ( $in ne "\n" ) {
        $ip->spush( ord $in );
        $in = $lbi->get_input;
        return $ip->dir_reverse unless defined $in;
    }
}

sub L {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $n = $ip->spop;
    my $a = $ip->spop_gnirts;
    return $ip->dir_reverse if $n < 0;
    return $ip->spush( $a ) if $n > length $a;
    $ip->spush_args( substr( $a, 0, $n ) );
}

sub M {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $n = $ip->spop;
    my $m = $ip->spop;
    my $a = $ip->spop_gnirts;
    return $ip->dir_reverse if ($m < 0 || $m > length($a) || $n < 0);
    $ip->spush_args( substr($a, $m, $n) );
}

sub N {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $a = $ip->spop_gnirts;
    $ip->spush_args( $a, length $a );
}


sub P {
    my ($self, $interp) = @_;
    my $ip      = $interp->get_curip;
    my $storage = $interp->get_storage;

    # pop arguments
    my $pos = $ip->spop_vec + $ip->get_storage;
    my $str = $ip->spop_gnirts;
    $storage->store_binary( $str . chr(0), $pos);
}

sub R {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $n = $ip->spop;
    my $a = $ip->spop_gnirts;
    return $ip->dir_reverse if $n < 0;
    return $ip->spush( $a ) if $n > length $a;
    $ip->spush_args( substr($a, -$n) );
}

sub S {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $n = $ip->spop;
    $ip->spush( $_ ) for reverse map {ord} split //, $n.chr(0);  # force string.
}    

sub V {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $n = $ip->spop_gnirts;
    $ip->spush( 0+$n );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::STRN - string extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The STRN fingerprint (0x5354524E) allows to work with strings.

=head1 FUNCTIONS

=head2 new

Create a new STRN instance.

=head2 I/O subroutines

=over 4

=item D($str)

Print C<$str> on STDOUT.

=item ($str) = I()

Input a string and push it back on the stack.

=back

=head2 String manipulation

=over 4

=item ($str) = A( $s1, $s2 )

Push back C<$s1 . $s2> on the stack.

=item ($cmp) = C( $1, $s2 )

Push back C<$s1 cmp $s2> on the stack.

=item ($str) = F( $s1, $s2 )

Push back the longest suffix of C<$s1> starting with C<$s2>.

=item ($str) = L( $s, $n )

Push back on the stack C<substr $s, 0, $n> (left of string).

=item ($str) = M( $s, $m, $n )

Push back on the stack C<substr $s, m, $n> (middle of string).

=item ($length) = N( $str )

Push back C<$length> of C<$str>.

=item ($str) = R( $s, $n )

Push back on the stack C<substr $s, -$n> (right of string).

=back

=head2 Strings within storage

The following functions take the storage offset into account.

=over 4

=item ($str) = G( $vec )

Read string from C<$vec>, using a velocity of (1,0, ..) till it finds a
null cell. Reflects if no null cell found.

=item P( $str, $vec )

Put string C<$str> at position C<$vec>.

=back

=head2 Conversion functions

=over 4

=item ($str) = S( $n )

Push back the string representation of C<$n>.

=item ($n) = V( $str )

Push back the numerical value of C<str>.

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#STRN>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
