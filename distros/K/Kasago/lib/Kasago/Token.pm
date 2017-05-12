package Kasago::Token;
use strict;
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( row col value source file line ));

sub _new_from_node {
  my($class, $node, $value, $location) = @_;
  $location ||= $node->location;
  my $self  = $class->SUPER::new({
    row   => $location->[0],
    col   => $location->[1],
    value => $value,
  });
  return $self;
}

1;

__END__

=head1 NAME

Kasago::Token - A search result for a token

=head1 SYNOPSIS

  # search for a token
  foreach my $token ($kasago->search('orange')){
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }

 # search for tokens
  foreach my $token ($kasago->search_more($search)) {
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }

=head1 DESCRIPTION

L<Kasago::Token> represents a search result for a token.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.











