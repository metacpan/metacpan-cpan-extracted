package Graphics::Primitive::Brush;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;

with 'MooseX::Clone';
with Storage (format => 'JSON', io => 'File');

enum 'LineCap' => [qw(butt round square)];
enum 'LineJoin' => [qw(miter round bevel)];

has 'color' => ( is => 'rw', isa => 'Graphics::Color', traits => [qw(Clone)] );
has 'dash_pattern' => ( is => 'rw', isa => 'ArrayRef' );
has 'width' => ( is => 'rw', isa => 'Int', default => sub { 0 } );
has 'line_cap' => ( is => 'rw', isa => 'LineCap', default => 'butt' );
has 'line_join' => ( is => 'rw', isa => 'LineJoin', default => 'miter' );

__PACKAGE__->meta->make_immutable;

sub derive {
    my ($self, $args) = @_;

    return unless ref($args) eq 'HASH';
    my $new = $self->clone;
    foreach my $key (keys %{ $args }) {
        $new->$key($args->{$key}) if($new->can($key));
    }
    return $new;
}

sub equal_to {
    my ($self, $other) = @_;

    return 0 unless defined($other);

    unless($self->width == $other->width) {
        return 0;
    }

    unless($self->line_cap eq $other->line_cap) {
        return 0;
    }

    unless($self->line_join eq $other->line_join) {
        return 0;
    }

    if(defined($self->color)) {
        unless($self->color->equal_to($other->color)) {
            return 0;
        }
    } else {
        if(defined($other->color)) {
            return 0;
        }
    }

    if(defined($self->dash_pattern)) {
        unless(scalar(@{ $self->dash_pattern }) == scalar(@{ $other->dash_pattern })) {
            return 0;
        }

        for(my $i = 0; $i < scalar(@{ $self->dash_pattern }); $i++) {
            unless($self->dash_pattern->[$i] == $other->dash_pattern->[$i]) {
                return 0;
            }
        }
    } else {
        if(defined($other->dash_pattern)) {
            return 0;
        }
    }

    return 1;
}

sub not_equal_to {
    my ($self, $other) = @_;

    return !$self->equal_to($other);
}

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive::Brush - Description of a stroke

=head1 DESCRIPTION

Graphics::Primitive::Brush represents the visible trace of 'ink' along a
path.

=head1 SYNOPSIS

  use Graphics::Primitive::Brush;

  my $stroke = Graphics::Primitive::Brush->new({
    line_cap => 'round',
    line_join => 'miter',
    width => 2
  });

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Brush.  Defaults to a width of 1,
a line_cap 'butt' and a line_join of 'miter'.

=back

=head2 Instance Methods

=over 4

=item I<color>

Set/Get this brush's color.

=item I<dash_pattern>

Set/Get the dash pattern.  A dash pattern is an arrayref of numbers
representing the lengths of the various line segments of the dash.  Even
numbered elements are considered opaque and odd elements are transparent.

=item I<derive>

Clone this brush but change one or more of it's attributes by passing in a
hashref of options:

  my $new = $brush->derive({ attr => $newvalue });
  
The returned font will be identical to the cloned one, save the attributes
specified.

=item I<equal_to ($other)>

Returns 1 if this brush is equal to the supplied one, else returns 0.

=item I<line_cap>

Set/Get the line_cap of this stroke.  Valid values are butt, round and square.

=item I<line_join>

Set/Get the line_join of this stroke. Valid values are miter, round and bevel.

=item I<not_equal_to ($other)>

Opposite of equal_to.

=item I<width>

Set/Get the width of this stroke.  Defaults to 1

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.