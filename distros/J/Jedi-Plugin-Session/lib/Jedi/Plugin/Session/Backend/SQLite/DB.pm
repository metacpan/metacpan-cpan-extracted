#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Backend::SQLite::DB;

# ABSTRACT: Schema for SQLite Session

use strict;
use warnings;

our $VERSION = 1;    #Schema Version

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes( { __PACKAGE__ . '::Result' => [qw/Session/] } );

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Backend::SQLite::DB - Schema for SQLite Session

=head1 VERSION

version 0.05

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-session/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
