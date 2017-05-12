package Flux::Log::Types;
{
  $Flux::Log::Types::VERSION = '1.00';
}

use Type::Library
    -base,
    -declare => qw( ClientName );
use Type::Utils;
use Types::Standard -types;

declare ClientName,
    as Str,
    where { /^\w+$/ };

1;

__END__

=pod

=head1 NAME

Flux::Log::Types

=head1 VERSION

version 1.00

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
