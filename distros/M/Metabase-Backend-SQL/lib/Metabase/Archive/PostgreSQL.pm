use 5.006;
use strict;
use warnings;

package Metabase::Archive::PostgreSQL;
# ABSTRACT: Metabase archive backend using PostgreSQL

our $VERSION = '1.001';

use Moose;

with 'Metabase::Backend::PostgreSQL';
with 'Metabase::Archive::SQL';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Archive::PostgreSQL - Metabase archive backend using PostgreSQL

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Metabase::Archive::PostgreSQL;

  my $archive = Metabase::Archive::PostgreSQL->new(
    db_name => "cpantesters",
    db_user => "johndoe",
    db_pass => "PaSsWoRd",
  );

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Archive::SQL> role using
PostgreSQL.

=head1 USAGE

See L<Metabase::Backend::PostgreSQL>, L<Metabase::Archive> and
L<Metabase::Librarian>.

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
