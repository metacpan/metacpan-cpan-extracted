package KiokuDB::Test::Company;
BEGIN {
  $KiokuDB::Test::Company::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Company::VERSION = '0.57';
use Moose;

use namespace::clean -except => 'meta';

has name => (
    isa => "Str",
    is  => "rw",
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Company

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
