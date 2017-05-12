package List::Range;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Class::Accessor::Lite ro => [qw/name lower upper/];
use overload '@{}'    => sub { [shift->all] },
             fallback => 1;

use Carp qw/croak/;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        lower => '-Inf',
        upper => '+Inf',
        name  => '',
        %args,
    } => $class;
    $self->{lower} <= $self->{upper}
        or croak "Cannot make a range by $self->{lower}..$self->{upper}";
    return $self;
}

sub includes {
    my $self = shift;
    if (ref $_[0] eq 'CODE') {
        my $code = shift;

        my $tmp; # for preformance
        return grep {
            $tmp = $code->($_);
            $self->{lower} <= $tmp && $tmp <= $self->{upper}
        } @_;
    }
    return grep { $self->{lower} <= $_ && $_ <= $self->{upper} } @_;
}

sub excludes {
    my $self = shift;
    if (ref $_[0] eq 'CODE') {
        my $code = shift;
        my $tmp; # for preformance
        return grep {
            $tmp = $code->($_);
            $tmp < $self->{lower} || $self->{upper} < $tmp
        } @_;
    }
    return grep { $_ < $self->{lower} || $self->{upper} < $_ } @_;
}

# for duck typing
sub ranges { [shift] }

sub all {
    my $self = shift;
    croak 'lower is infinit' if $self->lower == '-Inf';
    croak 'upper is infinit' if $self->upper == '+Inf';
    return ($self->lower..$self->upper);
}

1;
__END__

=encoding utf-8

=head1 NAME

List::Range - Range processor for integers

=head1 SYNOPSIS

    use List::Range;

    my $range = List::Range->new(name => "one-to-ten", lower => 1, upper => 10);
    $range->includes(0);   # => false
    $range->includes(1);   # => true
    $range->includes(3);   # => true
    $range->includes(10);  # => true
    $range->includes(11);  # => false

    $range->includes(0..100); # => (1..10)
    $range->includes(sub { $_ + 1 }, 0..100); # => (1..11)

    $range->excludes(0..100); # => (11..100)
    $range->excludes(sub { $_ + 1 }, 0..100); # => (0, 12..100)

=head1 DESCRIPTION

List::Range is range object of integers. This object likes C<0..10>.

=head1 METHODS

=head2 List::Range->new(%args)

Create a new List::Range object.

=head3 ARGUMENTS

=over 4

=item name

Name of the range. Defaults C<"">.

=item lower

Lower limit of the range. Defaults C<-Inf>.

=item upper

Upper limit of the range. Defaults C<+Inf>.

=back

=head2 $range->includes(@values)

Returns the values that is included in the range.

=head2 $range->excludes(@values)

Returns the values that is not included in the range.

=head2 $range->all

Returns all values in the range. (likes C<$lower..$upper>)
C<@$range> is alias of this.

=head1 SEE ALSO

L<Number::Range> L<Range::Object> L<Parse::Range>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
