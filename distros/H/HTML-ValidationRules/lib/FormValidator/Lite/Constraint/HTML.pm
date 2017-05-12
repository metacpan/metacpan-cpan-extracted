package FormValidator::Lite::Constraint::HTML;
use strict;
use warnings;
use Carp qw(croak);

use Scalar::Util::Numeric ();
use FormValidator::Lite;
use FormValidator::Lite::Constraint;

FormValidator::Lite->load_constraints(qw(URL Email));

our $VERSION = '0.01';

sub rule_of ($) {
    $FormValidator::Lite::Rules->{$_[0]};
}

rule HTML_URL   => rule_of('HTTP_URL');
rule HTML_EMAIL => rule_of('EMAIL');

rule HTML_NUMBER => sub {
    Scalar::Util::Numeric::isnum($_) ? 1 : 0;
};

rule HTML_RANGE => rule_of('HTML_NUMBER');

rule HTML_MAXLENGTH => sub {
    rule_of('LENGTH')->(0, shift);
};

rule HTML_MAX => sub {
    my ($max) = @_;

    return if !Scalar::Util::Numeric::isnum($_);
    croak 'Validation HTML_MAX requires numeric value'
        if !defined $max || !Scalar::Util::Numeric::isnum($max);

    $_ <= $max ? 1 : 0;
};

rule HTML_MIN => sub {
    my ($min) = @_;

    return if !Scalar::Util::Numeric::isnum($_);
    croak 'Validation HTML_MIN requires numeric value'
        if !defined $min || !Scalar::Util::Numeric::isnum($min);

    $_ >= $min ? 1 : 0;
};

rule HTML_PATTERN => sub {
    rule_of('REGEX')->('^(?:' . shift() . ')$');
};

!!1;
