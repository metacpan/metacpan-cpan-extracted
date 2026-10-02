package Langertha::Moment;
# ABSTRACT: Instant on the wire — a Time::Moment that numifies to its Unix epoch
our $VERSION = '0.503';
use strict;
use warnings;
use parent 'Time::Moment';
use Scalar::Util qw( blessed );

# NOT a Moose class, and deliberately so — the one place in this distribution
# that departs from the "Moose exclusively / always make_immutable" house rule.
#
# Time::Moment is XS. Its instances are blessed SCALARs holding an opaque
# struct, and every constructor (from_string, from_epoch, now, ...) as well as
# every derivation (plus_days, with_offset_same_instant, ...) blesses into the
# invocant's class from inside XS, never through Moose::Object::new. A Moose
# metaclass laid over that would describe an object system nothing here uses:
# make_immutable would inline a constructor that no Time::Moment code path
# calls, and Moose's default hash-based meta-instance does not fit a blessed
# SCALAR at all.
#
# MooseX::NonMoose (already a dependency, used by Langertha::Request::HTTP)
# was considered and rejected for the same reason. It exists to give a Moose
# class Moose *attributes* on top of a foreign parent, by routing
# Moose::Object::new through FOREIGNBUILDARGS into the parent's new. This
# class adds no attributes, and the constructors that actually matter here
# (from_string / from_epoch / from_wire) bypass new entirely — so NonMoose
# would add a metaclass, a wrapped new nobody calls, and a hash-instance
# assumption that is false, in exchange for nothing.
#
# What this class *is* is the overload set: subclassing is the only way to
# attach one to Time::Moment without polluting every other consumer of it in
# the process.
use overload
  # The back-compat contract. Langertha::Response->created was a Unix
  # timestamp Int for its whole life; numeric context must keep yielding
  # exactly that number. Note this is not inherited: Time::Moment overloads
  # '""' but not '0+', so a plain Time::Moment numifies through its string
  # form and evaluates to its *year*.
  '0+'  => sub { $_[0]->epoch },
  # Same as the inherited '""', declared explicitly: the pair of "'0+' is the
  # epoch, '""' is the full ISO-8601 stamp" is the contract of this class, and
  # it should not silently follow a change in the parent.
  '""'  => sub { $_[0]->to_string },
  '<=>' => \&_compare_numeric,
  'cmp' => \&_compare_string,
  # An instant that exists is true, the same call Langertha::Response makes for
  # itself (karr #100). Declared rather than left to autogeneration: perl
  # derives bool from '0+' here, which makes the epoch-0 moment -- a perfectly
  # real instant -- false, and which overload it picks is not something to
  # depend on across perl versions.
  'bool' => sub { 1 },
  fallback => 1;


sub TO_JSON { return 0 + $_[0]->epoch }


sub _compare_numeric {
  my ( $self, $other, $swapped ) = @_;
  my $result = ( blessed($other) && $other->isa('Time::Moment') )
    ? $self->compare($other)
    : ( $self->epoch <=> $other );
  return $swapped ? -$result : $result;
}

sub _compare_string {
  my ( $self, $other, $swapped ) = @_;
  my $result = $self->to_string cmp "$other";
  return $swapped ? -$result : $result;
}

sub from_wire {
  my ( $class, $value ) = @_;
  return undef unless defined $value;

  my $moment;
  if ( blessed($value) ) {
    return undef unless $value->isa('Time::Moment');
    return $value if $value->isa($class);
    # A plain Time::Moment (or a foreign subclass): re-parse its own canonical
    # string. That carries nanoseconds and offset across without assuming
    # anything about how the other class was built.
    $moment = eval { $class->from_string( $value->to_string ) };
  }
  elsif ( $value =~ /\A [-+]? [0-9]+ (?: \. [0-9]+ )? \z/x ) {
    # The OpenAI-compatible wire sends an epoch integer, and Ollama-compatible
    # shims sometimes send epoch seconds where Ollama itself sends RFC3339.
    #
    # Seconds and milliseconds are told apart by magnitude, not by any wire
    # flag: Time::Moment's whole representable range (through year 9999) tops
    # out at epoch 253402300799 -- 12 digits -- so a genuine seconds epoch is
    # always below 1e12. A 13-digit value is out of range as seconds but is a
    # sane milliseconds epoch (1e12 ms is year 2001), so scale it down instead
    # of letting from_epoch reject it and silently drop the field. The division
    # keeps the sub-second part. A normal ~10-digit seconds epoch is untouched
    # (karr #171).
    my $epoch = 0 + $value;
    $epoch /= 1000 if abs($epoch) >= 1e12;
    $moment = eval { $class->from_epoch( $epoch ) };
  }
  else {
    # lenient => 1 is chosen, not a default: it is what makes this accept the
    # same set the hand-rolled RFC3339 regex it replaced accepted — a space
    # instead of the T, an offset written without its colon, lowercase t/z.
    # It does not widen the door to non-timestamps: bare '2026' and
    # '2026-02-22' are still rejected, with or without it.
    $moment = eval { $class->from_string( "$value", lenient => 1 ) };
  }

  return undef unless defined $moment;
  # Ollama emits "0001-01-01T00:00:00Z" — Go's zero time.Time — as its "no
  # timestamp" sentinel, and it is a perfectly valid RFC3339 string that
  # Time::Moment parses without complaint. Treat the whole pre-1000 band as
  # absent rather than as a real instant; nothing an LLM provider reports
  # belongs there (karr #92).
  return undef if $moment->year < 1000;
  return $moment;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Moment - Instant on the wire — a Time::Moment that numifies to its Unix epoch

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $m = Langertha::Moment->from_wire('2026-05-05T02:53:03.138043625Z');

    print 0 + $m;        # 1777949583   — the Unix epoch
    print "$m";          # 2026-05-05T02:53:03.138043625Z
    print $m->nanosecond;# 138043625
    print $m->year;      # 2026 — every Time::Moment method is available

    my $o = Langertha::Moment->from_wire(1777949583);   # OpenAI-shaped epoch
    my $x = Langertha::Moment->from_wire('garbage');    # undef, never dies

=head1 DESCRIPTION

Canonical value object for an instant reported by a provider — currently
L<Langertha::Response/created>.

C<Langertha::Moment> is a subclass of L<Time::Moment> and inherits its whole
API: nanosecond resolution, UTC offsets, comparison, arithmetic. What it adds
is an overload set that makes the object drop into the places a plain Unix
timestamp used to sit:

=over

=item * C<0+> yields L<Time::Moment/epoch> — whole seconds since the epoch.
This is the compatibility contract. Every provider on the OpenAI-compatible
wire reports C<created> as an epoch integer, and that is the number
L<Langertha::Response/to_hash> keeps emitting.

=item * C<""> yields L<Time::Moment/to_string> — the full ISO-8601 stamp,
sub-seconds included. Nothing is rounded away on the way in, so an Ollama
stamp round-trips byte for byte.

=item * C<< <=> >> compares instants. Against another L<Time::Moment> it
delegates to L<Time::Moment/compare> and is nanosecond-exact; against a plain
number it compares whole epoch seconds. The inherited overload would
C<die> on the second case ("can only be compared to another Time::Moment
object"), which is precisely what code written against the old C<Int> does.

=item * C<cmp> compares the ISO-8601 strings.

=item * C<bool> is a constant true — an instant that exists is true, including
the epoch-0 one. Note this differs from the plain C<Int> the attribute used to
hold, where C<0> was false; L<Langertha::Response/has_created> is the predicate
for "did the provider report a stamp at all", and it is unaffected.

=back

=head2 Why a subclass rather than an attribute pair

The alternative — keep an C<Int> and hang a second "and here are the
nanoseconds" field beside it — is the shape ADR 0011 already rejected once for
timing. One value, one object, and the provider's native form stays reachable
under L<Langertha::Response/raw>.

=head2 JSON

C<TO_JSON> returns the epoch B<number>, so an encoder with C<convert_blessed>
enabled serializes a moment exactly where an C<Int> used to sit — inside
L<Langertha::Response/to_hash> and anywhere else a caller drops the value into
a structure of their own.

This overrides L<Time::Moment>'s own C<TO_JSON>, which returns the ISO-8601
string. Inheriting it would have been the quieter bug of the two: no error,
just a field that silently changed from number to string in every trace and
log that carries a response. The number is the compatibility surface; the
string is one C<"$moment"> away.

An encoder B<without> C<convert_blessed> still dies on the object, as it does
on every other value object a L<Langertha::Response> carries
(L<Langertha::Usage>, L<Langertha::ToolCall>, L<Langertha::RateLimit>). That
is a real break against the old plain C<Int> — see
L<Langertha::Response/"Comparing and printing created">.

=head2 TO_JSON

Returns the Unix epoch as a number, so a moment encodes as the plain integer
the field held before this class existed. Overrides L<Time::Moment>'s
C<TO_JSON>, which returns the ISO-8601 string.

=head2 from_wire

    my $m = Langertha::Moment->from_wire( $value );   # or undef

The lenient inbound constructor: the one entry point that turns whatever a
provider put in a timestamp field into a C<Langertha::Moment>, and returns
C<undef> — never dies — when it cannot.

Accepts, in this order:

=over

=item * an existing C<Langertha::Moment> (returned unchanged), or any other
L<Time::Moment>, re-parsed from its canonical string;

=item * an epoch number, integer or fractional, as a number or as a
digit string — the OpenAI-compatible wire form; a 13-digit value is read as a
millisecond epoch and scaled to seconds, keeping its sub-second precision,
since no representable seconds epoch reaches that magnitude;

=item * an ISO-8601 / RFC3339 string, parsed with L<Time::Moment/from_string>
in C<lenient> mode, keeping sub-seconds at full precision.

=back

Returns C<undef> for anything else, for a value outside L<Time::Moment>'s
representable range, and for a stamp in year 1..999 — the band Go-based
servers use for their "no timestamp" zero value.

B<Leniency is the point.> A timestamp is metadata; it must never be able to
take a whole provider response down with it, which is exactly what happened
when L<Langertha::Response/created> was a C<Maybe[Int]> and Ollama sent a
string (GitHub issue #3, karr #92 / #117). Callers that want a parse failure
to be loud should use the inherited L<Time::Moment/from_string> or
L<Time::Moment/from_epoch> directly — those still die.

=head1 SEE ALSO

=over

=item * L<Time::Moment> - The parent class; its whole API is available here

=item * L<Langertha::Response> - Carries a C<Langertha::Moment> as C<created>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
