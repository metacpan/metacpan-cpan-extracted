package KiokuDB::Backend::TypeMap::Default::JSON;
BEGIN {
  $KiokuDB::Backend::TypeMap::Default::JSON::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::TypeMap::Default::JSON::VERSION = '0.57';
use Moose::Role;

use KiokuDB::TypeMap::Default::JSON;

use namespace::clean -except => 'meta';

with qw(KiokuDB::Backend::TypeMap::Default);

sub _build_default_typemap {
    # FIXME options
    KiokuDB::TypeMap::Default::JSON->new
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::TypeMap::Default::JSON

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
