package Math::Calc::Units;

use Math::Calc::Units::Compute qw(compute);
use Math::Calc::Units::Rank qw(render render_unit choose_juicy_ones);
use Math::Calc::Units::Convert;

use base 'Exporter';
use vars qw($VERSION @EXPORT_OK);
BEGIN {
    $VERSION = '1.07';
    @EXPORT_OK = qw(calc readable convert equal exact);
}
use strict;

# calc : string -> string
# calc : string x true -> magnitude x string
sub calc ($;$) {
    my ($expr, $exact) = @_;
    my $v = compute($expr);
    return $exact ? ($v->[0], render_unit($v->[1])) : render($v);
}

# readable : string -> ( string )
sub readable {
    my $expr = shift;
    my %options;
    if (@_ == 1) {
        $options{verbose} = shift;
    } else {
        %options = @_;
    }
    my $v = compute($expr);
    return map { render($_, \%options) } choose_juicy_ones($v, \%options);
}

# convert : string x string [ x boolean ] -> string
sub convert ($$;$) {
    my ($expr, $units, $exact) = @_;
    my $v = compute($expr);
    my $u = compute("# $units");
    my $c = Math::Calc::Units::Convert::convert($v, $u->[1]);
    return $exact ? ($c->[0], render_unit($c->[1])) : render($c);
}

# equal : string x string -> boolean
use constant EPSILON => 1e-12;
sub equal {
    my ($u, $v) = @_;
    $u = compute($u);
    $v = compute($v);
    $v = Math::Calc::Units::Convert::convert($v, $u->[1]);
    $u = $u->[0];
    $v = $v->[0];
    return 1 if ($u == 0) && abs($v) < EPSILON;
    return abs(($u-$v)/$u) < EPSILON;
}

if (!(caller)) {
    my $verbose;
    my %options;
    if ($ARGV[0] eq '-v') { shift; $options{verbose} = 1; }
    if ($ARGV[0] eq '-a') { shift; $options{abbreviate} = 1; }
    print "$_\n" foreach readable($ARGV[0], %options);
}

=head1 NAME

Math::Calc::Units - Human-readable unit-aware calculator

=head1 SYNOPSIS

    use Math::Calc::Units qw(calc readable convert equal);

    print "It will take ".calc("10MB/(384Kbps)")." to download\n";

    my @alternative_descriptions = readable("10MB/(384Kbps)");

    print "A week is ".convert("1 week", "seconds")." long\n";

    if (equal("$rate bytes / sec", "1 MB/sec")) { ... };

=head1 DESCRIPTION

C<Math::Calc::Units> is a simple calculator that keeps track of units. It
currently handles combinations of byte sizes and duration only,
although adding any other multiplicative types is easy. Any unknown
type is treated as a unique user type (with some effort to map English
plurals to their singular forms).

The primary intended use is via the C<ucalc> script that prints out
all of the "readable" variants of a value. For example, C<"3 bytes">
will only produce C<"3 byte">, but C<"3 byte / sec"> produces the
original along with C<"180 byte / minute">, C<"10.55 kilobyte / hour">,
etc.

The C<Math::Calc::Units> interface only provides for string-based
computations, which could result in a large loss of precision for some
applications. If you need the exact result, you may pass in an extra
parameter C<'exact'> to C<calc> or C<convert>, causing them to return a
2-element list containing the numerical result and a string describing
the units of that result:

    my ($value, $units) = convert("10MB/sec", "GB/day");

(In scalar context, they just return the numeric value.)

=head2 Examples of use

=over 4

=item * Estimate transmission rates (e.g., 10MB at 384 kilobit/sec)

=item * Estimate performance characteristics (e.g., disk I/O rates)

=item * Figure out how long something will take to complete

=back

I tend to work on performance-sensitive code that involves a lot of
network and disk traffic, so I wrote this tool after I became very
sick of constantly converting KB/sec to GB/day when trying to figure
out how long a run is going to take, or what the theoretical maximum
performance would be if we were 100% disk bound. Now I can't live
without it.

=head2 Contraindications

If you are just trying to convert from one unit to another, you'll
probably be better off with C<Math::Units> or C<Convert::Units>. This
module really only makes sense when you're converting to and from
human-readable values.

=head1 AUTHOR

Steve Fink <sfink@cpan.org>

=head1 SEE ALSO

ucalc, Math::Units, Convert::Units.

=cut

1;
