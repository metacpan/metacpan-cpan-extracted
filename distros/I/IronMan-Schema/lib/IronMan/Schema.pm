package IronMan::Schema;

use 5.8.0;
use strict;
use warnings;

our $VERSION = '0.03';

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components('Schema::Versioned');
__PACKAGE__->load_namespaces();

=head1 NAME

IronMan::Schema - Schema for the Enlightened Perl Organisations IronMan project
(http://www.enlightenedperl.org/ironman.html).

=head1 DESCRIPTION

This module provides the DBIx::Class::Schema database abstraction for the
Enlightened Perl Organisation IronMan project.  See
http://www.enlightenedperl.org/ironman.html for further details on how you
should be taking part!

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

Jess Robinson (castaway) <castaway@desert-island.me.uk>
Carl Johnstone (fade)
Ian Norton (idn) <i.d.norton@gmail.com>


=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
