package HTTP::API::DataTypeMarker;
$HTTP::API::DataTypeMarker::VERSION = '1.04';
use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw( xCSV xBOOLEAN
    xTRUE xFALSE
    xTrue xFalse
    xtrue xfalse
    xt__e xf___e
);

sub xCSV {
    return bless \@_, 'CSV';
}

sub xBOOLEAN {
    return bless \@_, 'BOOL';
}

sub xTRUE {
    return xBOOLEAN(\1);
}

sub xFALSE {
    return xBOOLEAN(\0);
}

sub xTrue {
    return xBOOLEAN('True');
}

sub xFalse {
    return xBOOLEAN('False');
}

sub xtrue {
    return xBOOLEAN('true');
}

sub xfalse {
    return xBOOLEAN('false');
}

sub xt__e {
    return xBOOLEAN('t');
}

sub xf___e {
    return xBOOLEAN('f');
}

no Moo::Role;

1;
