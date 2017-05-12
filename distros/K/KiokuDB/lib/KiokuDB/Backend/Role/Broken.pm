package KiokuDB::Backend::Role::Broken;
BEGIN {
  $KiokuDB::Backend::Role::Broken::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::Broken::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Skip test fixtures

use namespace::clean -except => 'meta';

requires "skip_fixtures";

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::Broken - Skip test fixtures

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Backend::Role::Broken);

    # e.g. if your backend can't tell apart update from insert:
    use constant skip_fixtures => qw(
        Overwrite
    );

=head1 DESCRIPTION

If your backend can't pass a test fixture you can ask to skip it using this role.

Simply return the fixture's name from the C<skip_fixtures> sub.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
