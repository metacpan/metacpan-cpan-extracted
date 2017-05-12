use 5.006;
use strict;
use warnings;

package Metabase::Index::SQLite;
# ABSTRACT: Metabase index backend using SQLite

our $VERSION = '1.001';

use Moose;

with 'Metabase::Backend::SQLite';
with 'Metabase::Index::SQL';

sub _build_typemap {
  return {
    '//str'   => 'varchar(255)',
    '//num'   => 'integer',
    '//bool'  => 'boolean',
  };
}

sub _quote_field {
  my ($self, $field) = @_;
  return join(".", map { qq{"$_"} } split qr/\./, $field);
}

sub _quote_val {
  my ($self, $value) = @_;
  $value =~ s{'}{''}g;
  return qq{'$value'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Index::SQLite - Metabase index backend using SQLite

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Metabase::Index::SQLite;

  my $index = Metabase::Index:SQLite->new(
    filename => $sqlite_file,
  );

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Index::SQL> role using SQLite.

=head1 USAGE

See L<Metabase::Index>, L<Metabase::Query> and L<Metabase::Librarian>.

=for Pod::Coverage::TrustPod add query delete count
translate_query op_eq op_ne op_gt op_lt op_ge op_le op_between op_like
op_not op_or op_and

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Leon Brocard <acme@astray.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
