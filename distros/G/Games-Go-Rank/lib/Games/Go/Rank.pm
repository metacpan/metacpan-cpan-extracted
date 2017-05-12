use 5.008;
use strict;
use warnings;

package Games::Go::Rank;
our $VERSION = '1.100860';
# ABSTRACT: Represents a player's rank in the game of Go
use Moose;
use overload
  '""'  => 'stringify',
  '<=>' => 'num_cmp';
has 'rank' => (is => 'rw');

sub stringify {
    my $self = shift;
    $self->rank;
}

sub as_value {
    my $self = shift;
    my $rank = $self->rank;
    return unless defined $rank;    # so m// doesn't complain
    if    ($rank =~ /^\s*(\d+)[\s-]*k/) { return -$1 + 1 }
    elsif ($rank =~ /^\s*(\d+)[\s-]*d/) { return $1 }
    elsif ($rank =~ /^\s*(\d+)[\s-]*p/) { return $1 + 7 }
    else                                { return }
}

sub from_value {
    my ($self, $value) = @_;
    if ($value <= 0) {
        $self->rank(sprintf "%sk" => -$value + 1);
    } elsif ($value > 0 && $value <= 7) {
        $self->rank(sprintf "%sd" => $value);
    } elsif ($value > 7) {
        $self->rank(sprintf "%sp" => $value - 7);
    } else {
        $self->clear_rank;
    }
    return $self;
}

sub num_cmp {
    my ($lhs, $rhs, $reversed) = @_;
    for ($lhs, $rhs) {
        if (ref $_ eq __PACKAGE__) {
            $_ = $_->as_value;
        } else {
            $_ = __PACKAGE__->new(rank => $_)->as_value;
        }
    }
    ($lhs, $rhs) = ($rhs, $lhs) if $reversed;
    for ($lhs, $rhs) { $_ = -99 unless defined($_) }
    $lhs <=> $rhs;
}
1;


__END__
=pod

=for stopwords dan kyu

=head1 NAME

Games::Go::Rank - Represents a player's rank in the game of Go

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    use Games::Go::Rank;

    my $black_rank = Games::Go::Rank->new(rank => '1k');
    my $white_rank = Games::Go::Rank->new(rank => '2d');
    if ($white_rank > $black_rank) {
        # ...
    }

=head1 DESCRIPTION

This class represents a player's rank in the game of Go. Rank objects can be
compared to see whether two ranks are equal or whether one rank is higher than
the other. Rank objects stringify to the rank notation.

Use the standard notation for ranks such as C<30k>, C<5k>, C<1d>, C<2p> and so
on. You can also use other common formats such as C<6-dan> or C<2 dan>.
Anything after the first C<k>, C<d> or C<p> is ignored. So C<6-dan*> is the
same as C<6-dan>, which is the same as C<6d>.

=head1 METHODS

=head2 as_value

Returns a number representing the rank. C<1k> is returned as C<0>, lower kyu
ranks are returned as negative numbers (C<2K> is C<-1>, C<3k> is C<-2> etc.).
Dan ranks are returned as positive numbers, with pro ranks coming immediately
after dan ranks. For example, C<1d> == C<1>, C<7d> == C<7>, C<1p> == C<8>,
C<2p> == C<9>. Only dan ranks up to 7d are recognized as amateur ranks -
that is, C<8d> == C<1p>.

=head2 from_value

Sets the rank from a numerical value that is interpreted as described above.

=head2 num_cmp

FIXME

=head2 stringify

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Games-Go-Rank>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Games-Go-Rank/>.

The development version lives at
L<http://github.com/hanekomu/Games-Go-Rank/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

