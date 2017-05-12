package KiokuDB::Backend::DBI::Schema;
BEGIN {
  $KiokuDB::Backend::DBI::Schema::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::DBI::Schema::VERSION = '1.23';
use Moose;

use namespace::clean -except => 'meta';

extends qw(DBIx::Class::Schema);

__PACKAGE__->load_components(qw(Schema::KiokuDB));

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::DBI::Schema

=head1 VERSION

version 1.23

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
