package FeyX::Active;
use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use FeyX::Active::Schema;
use FeyX::Active::Table;

1;

__END__

=pod

=head1 NAME

FeyX::Active - An extension to Fey for active tables

=head1 SYNOPSIS

  use Fey;
  use FeyX::Active;

  my $schema = FeyX::Active::Schema->new( name => 'MySchema' );

  $schema->dbi_manager->add_source( dsn => 'dbi:SQLite:dbname=foo' );

  my $Person = FeyX::Active::Table->new(name => 'Person');
  $Person->add_column( Fey::Column->new( name => 'first_name', type => 'varchar' ) );
  $Person->add_column( Fey::Column->new( name => 'last_name',  type => 'varchar' ) );

  $schema->add_table( $Person );

  my @people = (
      { first_name  => 'Homer', last_name => 'Simpson' },
      { first_name  => 'Marge', last_name => 'Simpson' },
      { first_name  => 'Bart',  last_name => 'Simpson' },
  );

  foreach my $person (@people) {
      $Person->insert( %$person )->execute;
  }

  my ($first_name, $last_name) = $Person->select
                                        ->where( $Person->column('first_name'), '==', 'Homer' )
                                        ->execute
                                        ->fetchrow;


=head1 DESCRIPTION

This module extends the L<Fey> module to allow L<Fey> table objects
to have an active database handle so that the SQL objects that L<Fey>
creates can actually be executed.

You can think of this module as a bridge between L<Fey> which only
deals with SQL code generation and L<Fey::ORM> which is a full fledged
Object-Relational Mapping tool. Sometimes you don't need to inflate
your data into objects, but only need a simple way to execute SQL, if
that is the case, this may be the module for you.

This module aims to DWIM (Do What I Mean) in most cases and keep itself
as simple as possible. The real power is in the L<Fey> modules that this
extends, so if you don't see something here, go look there.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
