package FeyX::Active::Schema;
use Moose;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use Fey::Table;
use Fey::DBIManager;

extends 'Fey::Schema';

has 'dbi_manager' => (
    is      => 'rw',
    isa     => 'Fey::DBIManager',
    lazy    => 1,
    default => sub { Fey::DBIManager->new() },
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

FeyX::Active::Schema - An active Fey Schema

=head1 SYNOPSIS

  use FeyX::Active::Schema;

  my $schema = FeyX::Active::Schema->new( name => 'MySchema' );

  $schema->dbi_manager->add_source( dsn => 'dbi:SQLite:dbname=foo' );

  # ...

=head1 DESCRIPTION

This is just a subclass of L<Fey::Schema> which also happens to
have a L<Fey::DBIManager> instance handy. Nothing much else going
on here actually.

=head1 ATTRIBUTES

=over 4

=item B<dbi_manager>

This will lazily create a L<Fey::DBIManager> instance to be
used by this schema.

As of 0.02, this attribute is read/write so that it better
works with L<Fey::Loader>, like so:

  my $dbi_manager = Fey::DBIManager->new();

  $dbi_manager->add_source(...);

  my $loader = Fey::Loader->new(
      dbh          => $dbi_manager->default_source->dbh,
      schema_class => 'FeyX::Active::Schema',
      table_class  => 'FeyX::Active::Table',
  );

  my $schema = $loader->make_schema;

  $schema->dbi_manager($dbi_manager);

=back

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
