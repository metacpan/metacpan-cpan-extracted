package GitHub::MergeVelocity::Types;

use strict;
use warnings;

our $VERSION = '0.000009';

use DateTime::Format::ISO8601;
use Type::Library -base, -declare => ('Datetime');
use Type::Utils;
use Types::Standard -types;

class_type Datetime, { class => "DateTime" };

coerce Datetime, from Str,
    via { DateTime::Format::ISO8601->parse_datetime($_) };
1;

=pod

=encoding UTF-8

=head1 NAME

GitHub::MergeVelocity::Types - Custom types for use by GitHub::MergeVelocity modules

=head1 VERSION

version 0.000009

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Custom types for use by GitHub::MergeVelocity modules
