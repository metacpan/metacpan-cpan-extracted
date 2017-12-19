package MARC::Spec::Indicator;

use Moo;
use Carp qw(croak);
use namespace::clean;

our $VERSION = '2.0.3';

has position => (
    is => 'rw',
    isa => sub {
        croak('For indicator position, only digit "1" or "2" is allowed.')
            if($_[0] !~ /1|2/)
    },
    required => 1
);

has base => (
    is      => 'rwp',
    lazy    => 1,
    builder => '_base'
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

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args % 2 == 1) { unshift @args, "position" }
    return { @args };
}

sub _base {
    my ($self) = @_;

    return '^'.$self->position;
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

1;
__END__

=encoding utf-8

=head1 NAME

MARC::Spec::Indicator - indicator specification

=head1 SYNOPSIS

    use MARC::Spec::Indicator;
    
    my $indicator = MARC::Spec::Indicator->new('2');
    say ref $indicator;           # MARC::Spec::Indicator
    say $field->position;         # 2

=head1 DESCRIPTION

MARC::Spec::Indicator is the indicator specification of a L<MARC::Spec|MARC::Spec>.

See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/> for further 
details on the syntax.

=head1 METHODS

=head2 new(Str)

Create a new MARC::Spec::Indicator instance. Parameter must be a valid MARCspec indicatorPosition.

=head2 add_subspec(MARC::Spec::Subspec)

Appends a subspec to the array of the attribute subspecs. Parameter must be an instance of 
L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head2 add_subspecs(ArrayRef[MARC::Spec::Subspec])

Appends subspecs to the array of the attribute subspecs. Parameter must be an ArrayRef and 
elements must be instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head2 to_string

Returns the spec as a string.

=head1 PREDICATES

=head2 has_position

True if attribute position has an value and false otherwise.

=head2 has_subspecs

Returns true if attribute subspecs has an value and false otherwise.

=head1 ATTRIBUTES

Some attributes are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 base

Obligatory. Scalar. The base Field spec without subspecs.

=head2 position

Obligatory. The indicator position.

=head2 subspecs

Optional. An array of instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>, thus all subspecs in this 
array MUST be validated as a combination with the boolean 'AND',
and/or an array of arrays (AoA) of instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>, thus all subspecs 
in this AoA must be validated as a combination with the boolean 'OR'.

See L<MARC::Spec::Subspec|MARC::Spec::Subspec> for description of attributes of L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

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

=item * L<MARC::Spec::Subspec|MARC::Spec::Subspec>

=item * L<MARC::Spec::Structure|MARC::Spec::Structure>

=item * L<MARC::Spec::Comparisonstring|MARC::Spec::Comparisonstring>

=item * L<MARC::Spec::Parser|MARC::Spec::Parser>

=back

=cut
