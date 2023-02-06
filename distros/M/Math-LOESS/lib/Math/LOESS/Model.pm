package Math::LOESS::Model;

# ABSTRACT: Math::LOESS model configurations

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001000'; # VERSION

use Math::LOESS::_swig;
use Type::Params qw(compile_named);
use Types::Standard qw(ArrayRef Enum Object);

sub new {
    my $class = shift;
    state $check = compile_named( _obj => Object );

    my $arg = $check->(@_);
    return bless( $arg, $class );
}

sub _obj { $_[0]->{_obj} };

for my $attr (qw(span degree normalize)) {
    no strict 'refs';
    *{$attr} = sub {
        my ($self, $value) = @_;

        if (defined $value) {
            $self->_obj->{$attr} = $value;
        }
        return $self->_obj->{$attr};
    };
}

sub family {
    my ($self, $value) = @_;

    if (defined $value) {
        state $check = Type::Params::compile(Enum[qw(gaussian symmetric)]);
        ($value) = $check->($value);
        $self->_obj->{family} = $value;
    }
    return $self->_obj->{family};
}

for my $attr (qw(parametric drop_square)) {
    no strict 'refs';
    *{$attr} = sub {
        my ($self, $value) = @_;

        if (defined $value) {
            $self->_obj->{$attr} = $value;
        }
        return $self->_obj->{$attr};
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::LOESS::Model - Math::LOESS model configurations

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

You normally don't need to construct object of this class yourself.
Instead you get the object from an L<Math::LOESS> object.

=head1 NAME

Math::LOESS::Model - Math::LOESS model configurations

=head1 VERSION

version 0.0000_02

=head1 ATTRIBUTES

=head2 span

The parameter controls the degree of smoothing. Default is 0.75.

For C<span> < 1, the neighbourhood used for the fit includes proportion
C<span> of the points, and these have tricubic weighting (proportional to
C<(1 - (dist/maxdist)^3)^3)>. For C<span> > 1, all points are used, with
the "maximum distance" assumed to be C<span^(1/p)> times the actual
maximum distance for p explanatory variables.

=head2 degree

The degree of the polynomials to be used, normally 1 or 2. Default is 2.

=head2 parametric

Should any terms be fitted globally rather than locally? Default is false.
Terms can be specified by name, number or as a logical vector of the same
length as the number of predictors.

=head2 drop_square

For fits with more than one predictor and degree = 2, should the quadratic
term be dropped for particular predictors? Default is false.
Terms are specified in the same way as for parametric.

=head2 normalize

Should the predictors be normalized to a common scale if there is more
than one? The normalization used is to set the 10% trimmed standard
deviation to one. Set to false for spatial coordinate predictors and
others known to be on a common scale.

=head2 family

If C<"gaussian"> fitting is by least-squares, and if C<"symmetric"> a
re-descending M estimator is used with Tukey's biweight function.

=head1 SEE ALSO

L<Math::LOESS>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
