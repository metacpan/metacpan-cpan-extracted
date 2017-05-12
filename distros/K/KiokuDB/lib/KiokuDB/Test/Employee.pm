package KiokuDB::Test::Employee;
BEGIN {
  $KiokuDB::Test::Employee::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Employee::VERSION = '0.57';
use Moose;

use namespace::clean -except => 'meta';

extends qw(KiokuDB::Test::Person);

has company => (
    isa => "KiokuDB::Test::Company",
    is  => "rw",
);

sub lalala { 333 }

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Employee

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
