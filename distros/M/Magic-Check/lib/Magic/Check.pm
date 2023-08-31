package Magic::Check;
$Magic::Check::VERSION = '0.001';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 'import';
our @EXPORT = qw/check_variable/;

1;

# ABSTRACT: Add type/value checks to variables

__END__

=pod

=encoding UTF-8

=head1 NAME

Magic::Check - Add type/value checks to variables

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Magic::Check;
 use Types::Standard 'Int';

 check_variable(my $var = 1, Int);

 $var = "abc"; # this will throw

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 check_variable

 check_variable($variable, $checker)

This function takes a variable and adds set magic to check if the variable matches. This callback must be an object with a C<validate> like provided by L<Type::Tiny|Type::Tiny>: in must have a C<validate> method that returns C<undef> on success and an error message on failure. If the new value does not match, the old value is restored and the message is thrown as an exception.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
