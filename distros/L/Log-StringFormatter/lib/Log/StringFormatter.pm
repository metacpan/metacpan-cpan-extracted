package Log::StringFormatter;

use 5.008005;
use strict;
use warnings;
use base qw/Exporter/;

our $VERSION = "0.02";
our @EXPORT = qw/stringf/;

sub stringf {
    my $message = '';
    if ( @_ == 1 && defined $_[0]) {
        $message = '' . Log::StringFormatter::Dumper->new($_[0]);
    }
    elsif ( @_ >= 2 )  {
        $message = sprintf(shift, map { Log::StringFormatter::Dumper->new($_) } @_);
    }
    return $message;
}

1;

package
    Log::StringFormatter::Dumper;

use strict;
use warnings;
use base qw/Exporter/;
use Data::Dumper;
use Scalar::Util qw/blessed/;

use overload
    '""' => \&stringfy,
    '0+' => \&numeric,
    fallback => 1;

sub new {
    my ($class, $value) = @_;
    bless \$value, $class;
}

sub stringfy {
    my $self = shift;
    my $value = $$self;
    if ( blessed($value) && (my $stringify = overload::Method( $value, '""' ) || overload::Method( $value, '0+' )) ) {
        $value = $stringify->($value);
    }
    dumper($value);
}

sub numeric {
    my $self = shift;
    my $value = $$self;
    if ( blessed($value) && (my $numeric = overload::Method( $value, '0+' ) || overload::Method( $value, '""' )) ) {
        $value = $numeric->($value);
    }
    $value;
}

sub dumper {
    my $value = shift;
    if ( defined $value && ref($value) ) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0; 
        local $Data::Dumper::Sortkeys = 1; 
        $value = Data::Dumper::Dumper($value);
    }
    $value;
}


1;


1;
__END__

=encoding utf-8

=head1 NAME

Log::StringFormatter - string formatter for logs

=head1 SYNOPSIS

    use Log::StringFormatter;
    use Scalar::Util qw/dualvar/;

    stringf('foo') -> 'foo'
    stringf('%s bar','foo') -> 'foo bar'
    stringf([qw/foo bar/]) -> ['foo','bar']
    stringf('uri %s',URI->new("http://example.com/")) -> 'uri http://example.com/'
    my $dualvar = dualvar 10, "Hello";
    stringf('%s , %d', $dualvar, $dualvar) -> 'Hello , 10'

=head1 DESCRIPTION

Log::StringFormatter provides a string formatter function that suitable for log messages.
Log::StringFormatter's formatter also can serialize non-scalar variables.

=head1 FUNCTION

=over 4

=item stringf($format:Str,@variables) / stringf($variable)

format and serialize given values

=back

=head1 SEE ALSO

L<Log::Minimal>, L<String::Flogger>

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

