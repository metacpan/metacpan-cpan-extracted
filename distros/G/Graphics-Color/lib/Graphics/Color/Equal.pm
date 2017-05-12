package Graphics::Color::Equal;
$Graphics::Color::Equal::VERSION = '0.31';
use Moose::Role;

# ABSTRACT: Moose equality role

requires 'equal_to';


sub not_equal_to {
    my ($self, $other) = @_;
    not $self->equal_to($other);
}

no Moose;
1;

__END__

=pod

=head1 NAME

Graphics::Color::Equal - Moose equality role

=head1 VERSION

version 0.31

=head1 SYNOPSIS

  package Graphics::Color::Foo;
  use Moose;

  with 'Graphics::Color::Equal';

  sub equal_to {
      my ($self, $other) = @_;
      
      # compare and return!
  }

=head1 DESCRIPTION

Graphics::Color::Equal is a Moose role for equality.

=head1 METHODS

=head2 equal_to

Implement this.

=head2 not_equal_to

Provided you implement C<equal_to>, this will be implemented for you!

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
