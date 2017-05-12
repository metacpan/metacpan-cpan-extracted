package Java::JCR::Exception;

use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

Java::JCR::Exception - Wrapper for repository exceptions

=head1 SYNOPSIS

  eval {
      my $node = $root->add_node('foo', 'nt:unstructured');
  };

  if ($@) {
      print STDERR "Failed to add node foo: $@\n";
  }

=head1 DESCRIPTION

This class is used to make the exceptions thrown from the Java code work more nicely in Perl. Primarily, this involves performing nicer stringification than is provided by L<Inline::Java>. 

=cut

use overload 
    '""' => sub {
        my $self = shift;
        return $self->{obj}->toString;
    },
    'eq' => sub {
        my $self = shift;
        my $obj = shift;

        return "$self->{obj}" eq "$obj";
    };

sub new {
    my $class = shift;
    my $exception = shift;

    return bless {
        obj => $exception,
    }, $class;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
