use 5.006;
use strict;
use warnings;

package Metabase::Archive::SQLite;
# ABSTRACT: Metabase storage using SQLite

our $VERSION = '1.001';

use Moose;

with 'Metabase::Backend::SQLite';
with 'Metabase::Archive::SQL';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Archive::SQLite - Metabase storage using SQLite

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Metabase::Archive::SQLite;

  my $archive = Metabase::Archive::SQLite->new(
    filename => $sqlite_file,
  ); 

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Archive::SQL> role using SQLite.

=head1 USAGE

See L<Metabase::Archive> and L<Metabase::Librarian>.

=for Pod::Coverage::TrustPod store extract delete iterator initialize

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
