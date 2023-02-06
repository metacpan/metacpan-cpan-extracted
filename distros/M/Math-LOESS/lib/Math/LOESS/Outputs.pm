package Math::LOESS::Outputs;

# ABSTRACT: Math::LOESS basic fit outputs

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001000'; # VERSION

use Math::LOESS::_swig;
use Scalar::Util qw(weaken);
use Type::Params qw(compile_named);
use Types::Standard qw(Int Object Str);

sub new {
    my $class = shift;
    state $check = compile_named(
        _obj   => Object,
        _loess => Object,
    );

    my $arg = $check->(@_);
    my $self = bless( $arg, $class );
    weaken( $self->{_loess} );
    return $self;
}

sub _loess { $_[0]->{_loess} }

sub _obj {
    my ($self) = @_;
    unless ($self->_loess) {
        die 'Math::LOESS::Outputs object has been invalidated '
          . 'because its corresponding loess object has been destroyed. '
          . 'Make sure the loess object be living when calling '
          . 'Math::LOESS::Outputs object methods.'
    }
    return $self->{_obj};
}

sub _family { $_[0]->_loess->model->family }
sub _n { $_[0]->_loess->n }
sub _p { $_[0]->_loess->p }

for my $attr (
    qw(
    fitted_values fitted_residuals diagnal robust
    divisor
    )
  )
{
    no strict 'refs';
    *{$attr} = sub {
        my ($self) = @_;
        return Math::LOESS::_swig::darray_to_pdl( $self->_obj->{$attr},
            $self->_n );
    };
}

sub pseudovalues {
    my ($self) = @_;
    if ( $self->family ne 'symmetric' ) {
        die "pseudovalues are available only when robust fitting. "
          . "Use family='symmetric' for robust fitting";
    }
    return Math::LOESS::_swig::darray_to_pdl( $self->_obj->{pseudovalues},
        $self->_n );
}

for my $attr (
    qw(
    enp residual_scale one_delta two_delta trace_hat
    )
  )
{
    no strict 'refs';
    *{$attr} = sub {
        my ($self) = @_;
        return $self->_obj->{$attr};
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::LOESS::Outputs - Math::LOESS basic fit outputs

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

You normally don't need to construct object of this class yourself.
Instead you get the object from an L<Math::LOESS> object after its C<fit()>
method is called. 

=head1 ATTRIBUTES

=head2 fitted_values

Fitted values.

=head2 fitted_residuals

Fitted residuals.

=head2 pseudovalues

Adjusted values of the response when robust estimation is used.

=head2 diagnal

Diagonal of the operator hat matrix.

=head2 robust

Robustness weights for robust fitting.

=head2 divisor

Normalization divisors for numeric predictors.

=head2 enp

Equivalent number of parameters.

=head2 residual_scale

Estimate of the scale of residuals.

=head2 one_delta

Statistical parameter used in the computation of standard errors.

=head2 two_delta

Statistical parameter used in the computation of standard errors.

=head2 trace_hat

Trace of the operator hat matrix.

=head1 SEE ALSO

L<Math::LOESS>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
