package Kasago::Hit;
use strict;
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( tokens line source file row ));

1;

__END__

=head1 NAME

Kasago::Hit - A search hit

=head1 SYNOPSIS

  # search for a token, merging lines
  foreach my $hit ($kasago->search_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }  

  # searh for tokens, merging lines
  foreach my $hit ($kasago->search_more_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }

=head1 DESCRIPTION

L<Kasago::Hit> represents a hit from the index, where tokens
on the same line have been merged into the same object.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.











