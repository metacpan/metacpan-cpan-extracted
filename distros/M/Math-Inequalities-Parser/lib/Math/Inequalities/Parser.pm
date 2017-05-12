package Math::Inequalities::Parser;
use strict;
use warnings;
use Carp qw/ croak /;
use Exporter qw/ import /;

our @EXPORT = qw/ parse_inequality /;

our $VERSION = '0.002';

sub parse_inequality {
    my ($string) = @_;
    $string ||= '';
    if ($string =~ /^\s*(\d+)\s*<\s*n\s*<\s*(\d+)\s*$/ ) {
        return ($1+1, $2-1);
    }
    elsif ($string =~ /^\s*(\d+)\s*<(=)?\s*n/ ) {
        return ($1 + ($2 ? 0 : 1), undef);
    }
    elsif ($string =~ /^\s*(\d+)\s*>(=)?\s*n\s*$/ ) {
        return (undef, $1 - ($2 ? 0 : 1));
    }
    elsif ($string =~ /^\s*n\s*>(=)?\s*(\d+)\s*$/ ) {
        return ($2 + ($1 ? 0 : 1), undef);
    }
    elsif ($string =~ /^\s*n\s*<(=)?\s*(\d+)\s*$/ ) {
        return (undef, $2 - ($1 ? 0 : 1));
    }
    elsif ($string =~ /^\s*(\d+)\s*$/ ) {
        return ($1, $1);
    }
    elsif (length $string && $string !~ /^\s+$/) {
        croak "Cannot parse '$string' as an inequality.";
    }
    return (undef, undef);
}

1;

=head1 NAME

Math::Inequalities::Parser - Minimum and maximum values allowed by an inequality.

=head1 SYNOPSIS

    use Math::Inequalities::Parser;
    
    my ($min, $max) = parse_inequality( ' 10 < n < 20 ' );
    # $min = 11
    # $max = 19

=head1 DESCRIPTION

Tiny library for parsing integer maximum and minimum out when given an arbitrary inequality.

Because getting this simple thing right was far harder
than it looked, and I never want to have to think about it again.

=head1 FUNCTIONS

=head2 parse_inequality

Parses an inequality string and returns a list of two values, the minimum and the maxium value
that string will allow.

=head1 TYPES OF INEQUALITY

=head2 VALUE

The simplest type, a single value, e.g. C<< 42 = Min 42, Max 42 >>.

=head2 n < VALUE

Maximum is VALUE - 1, Minimum is undefined, e.g. C<< n < 42 = Min undef, Max 41 >>.

=head2 n > VALUE

Minimum is VALUE +1, Maximum is undefined, e.g. C<< n > 42 = Min 43, Max undef >>.

=head2 n <= VALUE

Maximum is VALUE, Minimum is undefined, e.g. C<< n < 42 = Min undef, Max 42 >>.

=head2 n >= VALUE

Minimum is VALUE, Maximum is undefined, e.g. C<< n > 42 = Min 42, Max undef >>.

=head2 Cases with VALUE, followed by N.

Handled as above, but with minimum and maximum reversed as expected.

=head2 VALUE1 < n < VALUE2

Minimum is VALUE1 + 1, maximum is VALUE2 - 1, e.g C<< 42 < n < 200 = Min 43, Max 199 >>.

=head1 BUGS

=over

=item Does not handle C<< VALUE1 <= n <= VALUE2 >> or similar. Patches welcome.

=item Does not complain at impossible C<<VALUE1 < n < VALUE 2 >> combinations (e.g. C<< 5 < n < 4 >>) which result in a higher minumum than the maxiumum. Patches welcome.

=item Does not work with negative numbers. Patches welcome.

=item Always uses C<< n >> as the number identifier, this should be configureable at import time.

=item Uses Exporter (should use Sub::Exporter)

=item B<DOES NOT> work with floating point numbers. I consider this a feature.

=back

=head1 AUTHORS

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

Dave Lambley

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

