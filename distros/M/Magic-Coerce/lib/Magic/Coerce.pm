package Magic::Coerce;
$Magic::Coerce::VERSION = '0.001';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 5.57 'import';
our @EXPORT = qw/coerce_int coerce_float coerce_string coerce_callback/;

1;

# ABSTRACT: magical coercers for scalar values

__END__

=pod

=encoding UTF-8

=head1 NAME

Magic::Coerce - magical coercers for scalar values

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 coerce_int(my $intval = 0);

 coerce_callback($value, sub($value) { Math::Bigint->new($value) });

=head1 FUNCTIONS

=head2 C<coerce_int($var, $delayed = false)>

This will coerce any value assigned to C<$var> to an integer. Unless C<$delayed> is true it will immediately coerce the value.

=head2 C<coerce_float($var, $delayed = false)>

This will coerce any value assigned to C<$var> to a floating point number. Unless C<$delayed> is true it will immediately coerce the value.

=head2 C<coerce_string($var, $delayed = false)>

This will coerce any value assigned to C<$var> to a string. Unless C<$delayed> is true it will immediately coerce the value.

=head2 C<coerce_callback($var, &callback, $delayed = false)>

This will coerce the value on assignment using the callback. Unless C<$delayed> is true it will immediately coerce the value.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
