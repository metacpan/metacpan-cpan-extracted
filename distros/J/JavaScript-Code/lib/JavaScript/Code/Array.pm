package JavaScript::Code::Array;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Type ];

__PACKAGE__->mk_accessors(qw[ elements size ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Array - A JavaScript Array Type

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;
    use JavaScript::Code::Array;

    my $array = JavaScript::Code::Array->new( elements => [] );

=head1 METHODS

=head2 new( ... )

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;

    my $self = $class->SUPER::new(@_);

    # cleanup the elements
    my $array = delete $self->{elements} || [];
    push @{$array}, @{ delete $self->{value} || [] };
    $self->elements( [] );
    $self->push_back($array) if defined $array;

    return $self;
}

=head2 $self->push_back( $value | \@values )

Add one or more element(s) to the end of array.

=cut

sub push_back {
    my ( $self, $array ) = @_;

    die 'Nothing to add.'
      unless defined $array;

    $array = [$array] unless ref $array eq 'ARRAY';

    my $elements = $self->elements;
    foreach my $value ( @{$array} ) {

        $value = JavaScript::Code::Type->build( value => $value )
          unless ref $value;

        die "'$value' is not a 'JavaScript::Code::Value'."
          unless ref $value
          and $value->isa('JavaScript::Code::Value');

        foreach my $t (qw[ JavaScript::Code::Array JavaScript::Code::Hash ]) {
            die "Can not add '$t'." if $value->isa($t);
        }

        push @{$elements}, $value;
    }

    $self->elements($elements);

    return $self;
}

=head2 $self->at( $index, < $value > )

Gets or sets the value on the given index.

Dies if the index is out of range.

=cut

sub at {
    my $self = shift;
    my $ndx  = shift || 0;

    die "Out of range."
      if $ndx >= $self->length;

    if (@_) {
        my $value = shift;

        die "'$value' is not a 'JavaScript::Code::Value'."
          unless ref $value
          and $value->isa('JavaScript::Code::Value');

        $self->elements->[$ndx] = $value;

        return $self;
    }

    return $self->elements->[$ndx];
}

=head2 $self->length( )

Returns the number of elements stored in the array.

=cut

sub length {
    my ($self) = @_;

    return scalar @{ $self->elements };
}

=head2 $self->type( )

=cut

sub type {
    return "Array";
}

=head2 $self->output( )

=cut

sub output {
    my ($self) = @_;

    my $output = 'new Array(';
    unless ( $self->length ) {
        my $size = $self->size || 0;
        $output .= $size if $size;
    }
    else {

        my $values = '';
        foreach my $value ( @{ $self->elements } ) {

            $values .= ', ' if $values;
            $values .= "$value";
        }

        $output .= $values;
    }

    $output .= ')';

    return $output;
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
