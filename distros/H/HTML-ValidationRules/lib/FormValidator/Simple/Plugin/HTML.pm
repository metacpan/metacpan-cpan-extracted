package FormValidator::Simple::Plugin::HTML;
use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util::Numeric ();
use FormValidator::Simple::Constants;
use FormValidator::Simple::Exception;

sub HTML_URL {
    my ($self, $params, $args) = @_;
    $self->HTTP_URL($params, $args);
}

sub HTML_EMAIL {
    my ($self, $params, $args) = @_;
    $self->EMAIL($params, $args);
}

sub HTML_NUMBER {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FAIL if !defined $data;
    Scalar::Util::Numeric::isnum($data) ? SUCCESS : FAIL;
}

*HTML_RANGE = \&HTML_NUMBER;

sub HTML_MAXLENGTH {
    my ($self, $params, $args) = @_;
    my $data      = $params->[0] || '';
    my $maxlength = $args->[0];

    FormValidator::Simple::Exception->throw(
        'Validation HTML_MAXLENGTH needs one numeric argument.'
    ) if !defined $maxlength || !Scalar::Util::Numeric::isnum($maxlength);

    length $data <= $maxlength ? SUCCESS : FAIL;
}

sub HTML_MAX {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FAIL if !Scalar::Util::Numeric::isnum($data);

    my $max = $args->[0];
    FormValidator::Simple::Exception->throw(
        'Validation HTML_MAX needs one numeric argument.'
    ) if !defined $max || !Scalar::Util::Numeric::isnum($max);

    $data <= $max ? SUCCESS : FAIL;
}

sub HTML_MIN {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FAIL if !Scalar::Util::Numeric::isnum($data);

    my $min = $args->[0];
    FormValidator::Simple::Exception->throw(
        'Validation HTML_MIN needs one numeric argument.'
    ) if !defined $min || !Scalar::Util::Numeric::isnum($min);

    $data >= $min ? SUCCESS : FAIL;
}

sub HTML_PATTERN {
    my ($self, $params, $args) = @_;
    my $data    = defined $params->[0] ? $params->[0] : '';
    my $pattern = defined $args->[0] ? $args->[0] : '';

    $data =~ qr/^(?:$pattern)$/ ? SUCCESS : FAIL;
}

!!1;
