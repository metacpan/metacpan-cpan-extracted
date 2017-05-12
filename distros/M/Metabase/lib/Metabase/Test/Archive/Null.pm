use 5.006;
use strict;
use warnings;

package Metabase::Test::Archive::Null;
# ABSTRACT: Metabase storage that discards all data
our $VERSION = '1.003'; # VERSION

use Moose;

use Carp ();
use Data::Stream::Bulk::Nil;

with 'Metabase::Archive';

sub initialize { }

# given fact, discard it and return guid
sub store {
    my ($self, $fact_struct) = @_;

    my $guid = $fact_struct->{metadata}{core}{guid};
    unless ( $guid ) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    # do nothing except return
    return $guid;
}

# we discard, so can't ever extract
sub extract {
  die "unimplemented";
}

# does nothing
sub delete {
  my ($self, $guid) = @_;
  return $guid;
}

# we have nothing to return
sub iterator {
  return Data::Stream::Bulk::Nil->new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Test::Archive::Null - Metabase storage that discards all data

=head1 VERSION

version 1.003

=head1 SYNOPSIS

  require Metabase::Test::Archive::Null;
  $archive = Metabase::Test::Archive::Null->new;

=head1 DESCRIPTION

Discards all facts to be stored.  For testing only, obviously.

=for Pod::Coverage store extract delete iterator initialize

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Leon Brocard <acme@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
