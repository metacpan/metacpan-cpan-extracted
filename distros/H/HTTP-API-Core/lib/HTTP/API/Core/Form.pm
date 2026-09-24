package HTTP::API::Core::Form;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(form_urlencode);

sub form_urlencode {
    my ($params) = @_;
    die "form parameters must be a hash reference\n" if ref($params) ne 'HASH';

    return join '&', map {
        my $key = $_;
        my $value = $params->{$key};
        die "form parameter values must be scalars, array references, or undef\n"
            if ref($value) && ref($value) ne 'ARRAY';
        my @values = ref($value) eq 'ARRAY' ? @$value : ($value);
        die "form parameter array values must contain only scalars or undef\n"
            if grep { defined($_) && ref($_) } @values;
        map { _escape($key) . '=' . _escape($_) } @values;
    } sort keys %$params;
}

sub _escape {
    my ($value) = @_;
    $value = '' if !defined $value;
    my $bytes = "$value";
    utf8::encode($bytes) if utf8::is_utf8($bytes);
    $bytes =~ s/([^A-Za-z0-9*_. -])/sprintf('%%%02X', ord($1))/ge;
    $bytes =~ tr/ /+/;
    return $bytes;
}

1;
