package MARC::Spec::Structure;

use Moo;
use Const::Fast;
use Carp qw(croak);
use namespace::clean;

our $VERSION = '2.0.3';

const my $NO_LENGTH => -1;
const my $LAST => '#';

has base => (
    is      => 'rwp',
    lazy    => 1,
    builder => '_base'
);

sub _base {
    my ($self) = @_;

    my $base = ($self->can('tag')) ? $self->tag : '$'.$self->code;

    $base .= '['.$self->index_start;
    if($self->index_start ne $self->index_end) { $base .= '-'.$self->index_end }
    $base .= ']';

    if(defined $self->char_start) {
        my $char_start = $self->char_start;
        my $char_end   = $self->char_end;
        unless($char_start eq '0' && $char_end eq '#') {
            $base .= '/'.$char_start;
            if($char_end ne $char_start) { $base .= '-'.$char_end }
        }
    }

    return $base;
}


has index_start => (
    is      => 'rw',
    default => sub {0},
    trigger => sub {
        my ($self, $index_start) = @_;
        if ($LAST ne $self->index_end && $LAST ne $index_start && $self->index_end < $index_start) {
            $self->index_end($index_start);
        } else {
            $self->_set_base( $self->_base() );
        }
        $self->_set_index_length( _calculate_length($index_start, $self->index_end) )
    }
);

has index_end => (
    is      => 'rw',
    default => sub {$LAST},
    trigger => sub {
        my ($self, $index_end) = @_;
        if ($LAST ne $self->index_start && $LAST ne $index_end && $self->index_start > $index_end) {
            $self->index_start($index_end);
        } else {
            $self->_set_base( $self->_base() );
        }
        $self->_set_index_length( _calculate_length($self->index_start, $index_end) )
    }
);
    
has index_length => (
    is      => 'rwp',
    default => sub {$NO_LENGTH}
);

has char_start => (
    is      => 'rw',
    trigger => sub {
        my ($self, $char_start) = @_;
        if(!defined $self->char_end) { $self->char_end($char_start) }
        $self->_set_char_pos($self->char_start.'-'.$self->char_end);
        $self->_set_char_length( _calculate_length($char_start, $self->char_end) );
        $self->_set_base( $self->_base() )
    },
    predicate => 1
);

has char_end => (
    is      => 'rw',
    trigger => sub {
        my ($self, $char_end) = @_;
        if(!defined $self->char_start) { $self->char_start($char_end) }
        $self->_set_char_pos($self->char_start.'-'.$self->char_end);
        $self->_set_char_length( _calculate_length($self->char_start, $char_end) );
        $self->_set_base( $self->_base() )
    },
    predicate => 1
);

has char_pos => (
    is => 'rwp',
    predicate => 1
);

has char_length => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return _calculate_length($self->char_start, $self->char_end)
    }
);

has subspecs => (
    is  => 'rwp',
    isa => sub {
        foreach my $and (@{$_[0]}) {
            if(ref $and eq 'ARRAY') {
                foreach my $or (@{$and}) {
                    croak('Subspec is not an instance of MARC::Spec::Subspec.')
                        if(ref $or ne 'MARC::Spec::Subspec')
                }
            } else {
                croak('Subspec is not an instance of MARC::Spec::Subspec.')
                    if(ref $and ne 'MARC::Spec::Subspec')
            }
        }
    },
    predicate => 1
);

sub set_index_start_end {
    my ($self, $indizes) = @_;
    my @pos = _validate_pos($indizes);
    $self->index_start($pos[0]);
    defined $pos[1] ? $self->index_end($pos[1]) : $self->index_end($pos[0])
}

sub set_char_start_end {
    my ($self, $charpos) = @_;
    my @pos = _validate_pos($charpos);
    $self->char_start($pos[0]);
    defined $pos[1] ? $self->char_end($pos[1]) : $self->char_end($pos[0])
}

sub add_subspec {
    my ($self, $subspec) = @_;
    if(!$self->has_subspecs) {
        $self->_set_subspecs([$subspec]);
    } else {
        my @subspecs = ( @{$self->subspecs}, $subspec );
        $self->_set_subspecs( \@subspecs )
    }
}

sub add_subspecs {
    my ($self, $subspecs) = @_;
    if (ref $subspecs ne 'ARRAY') { 
        croak('Subspecs is not an ARRAYRef!')
    }
    if(!$self->has_subspecs) {
        $self->_set_subspecs($subspecs)
    } else {
        my @merged = @{$self->subspecs};
        push @merged, @{$subspecs};
        $self->_set_subspecs( \@merged )
    }
}

sub to_string {
    my ($self) = @_;
    my $string = $self->base;
    if($self->has_subspecs) {
        my @outer = ();
        foreach my $ss (@{$self->subspecs}) {
            if(ref $ss eq 'ARRAY') {
                my $inner = join '|', map {$_->to_string()} @{$ss};
                push @outer, $inner;
            } else {
                push @outer, $ss->to_string();
            }
        }
        my $joined = join '}{', @outer;
        $string .= '{'. $joined .'}';
    }
    return $string;
}

sub _calculate_length {
    my ($start, $end) = @_;

    # start eq end
    if ($start eq $end) { return 1 }

    # start = #, end != #
    if($LAST eq $start && $LAST ne $end) { return $end + 1 }

    # start != #, end = #
    if($LAST ne $start && $LAST eq $end) { return $NO_LENGTH }

    my $length = $end - $start + 1;

    if(1 > $length) {
        _throw("Ending character or index position must be equal or higher than starting character or index position.", "$start-$end");
    }

    return $length;
}

sub _validate_pos {
    my ($charpos) = @_;

    if($charpos =~ /[^0-9\-#]/s) {
        _throw("Assuming index or character position or range. Only digits, the character '#' and one '-' is allowed.", $charpos);
    }

    # something like 123- is not valid
    if('-' eq substr $charpos, -1) {
        _throw("Assuming index or character range. At least two digits or the character '#' must be present." ,$charpos);
    }

    # something like -123 is not valid
    if('-' eq substr $charpos, 0, 1) {
        _throw("Assuming index or character position or range. First character must not be '-'.", $charpos);
    }

    my @pos = split /\-/, $charpos, 2;

    # set end pos to start pos if no end pos
    if(!defined $pos[1]) { push (@pos, $pos[0]) }

    return @pos;
}

sub _throw {
    my ($message, $hint) = @_;
    croak 'MARCspec Parser exception. '.$message.' Tried to parse: '.$hint;
}
1;
__END__

=encoding utf-8

=head1 NAME

MARC::Spec::Structure - base class

=head1 SYNOPSIS

    use MARC::Spec::Field;
    
    # create a new field
    my $field = MARC::Spec::Field->new('246');
    
    # field does inherit all attributes, predicates and methods
    say $field->DOES('MARC::Spec::Structure'); # 1


=head1 DESCRIPTION

Is the base class for L<MARC::Spec::Field|MARC::Spec::Field> and L<MARC::Spec::Subfield|MARC::Spec::Subfield>.

=head1 METHODS

=head2 set_index_start_end (Str)

Sets MARC::Spec::Structure::$index_start and MARC::Spec::Structure::$index_end from an index position or range.

=head2 set_char_start_end (Str)

Sets MARC::Spec::Structure::$char_start and MARC::Spec::Structure::$char_end from an character position or range.

=head2 add_subspec(MARC::Spec::Subspec)

Appends a subspec to the array of the attribute subspecs. Parameter must be an instance of 
L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head2 add_subspecs(ArrayRef[MARC::Spec::Subspec])

Appends subspecs to the array of the attribute subspecs. Parameter must be an ArrayRef and 
elements must be instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head1 PREDICATES

=head2 has_char_start

True if attribute char_start has an value and false otherwise.

=head2 has_char_end

True if attribute char_end has an value and false otherwise.

=head2 has_char_pos

True if attribute char_pos has an value and false otherwise.

=head2 has_subspecs

Returns true if attribute subspecs has an value and false otherwise.

=head1 ATTRIBUTES

=head2 base

Obligatory. Scalar. Normalized MARCspec without Subspecs.

=head2 char_start

If defined, the beginning character position of a character position or range.

=head2 char_end

If defined, the ending character position of a character position or range.
Only present if MARC::Spec::Structure::$char_start is defined.

=head2 char_length

The difference of MARC::Spec::Structure::$char_start and MARC::Spec::Structure::$char_end if both are numeric
(or else -1).
Only present if MARC::Spec::Structure::$char_start is defined.

=head2 char_pos

If defined, the character position or range.
Only present if MARC::Spec::Structure::$char_start is defined.

=head2 index_start

Obligatory. The beginning index of field repetitions. Maybe a positiv integer or the character '#'.
Default is 0.

=head2 index_end

Obligatory. The ending index of field repetitions. Maybe a positiv integer or the character '#'.
Default is '#'.

=head2 index_length

Obligatory. The difference of MARC::Spec::Structure::$index_start and MARC::Spec::Structure::$index_end if both are numeric.
Default is -1.

=head1 AUTHOR

Carsten Klee C<< <klee at cpan.org> >>

=head1 CONTRIBUTORS

=over

=item * Johann Rolschewski, C<< <jorol at cpan> >>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Carsten Klee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs to L<https://github.com/MARCspec/MARC-Spec/issues|https://github.com/MARCspec/MARC-Spec/issues>

=head1 SEE ALSO

=over

=item * L<MARC::Spec|MARC::Spec>

=item * L<MARC::Spec::Field|MARC::Spec::Field>

=item * L<MARC::Spec::Subfield|MARC::Spec::Subfield>

=item * L<MARC::Spec::Indicator|MARC::Spec::Indicator>

=item * L<MARC::Spec::Subspec|MARC::Spec::Subspec>

=item * L<MARC::Spec::Comparisonstring|MARC::Spec::Comparisonstring>

=item * L<MARC::Spec::Parser|MARC::Spec::Parser>

=back

=cut
