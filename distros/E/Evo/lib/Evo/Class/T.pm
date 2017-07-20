package Evo::Class::T;
use Evo '-Export *; Carp croak; List::Util any';

sub T_ENUM(@list) : Export {
  croak "empty enum list" unless @list;
  sub($v) {
    any { defined $v ? defined $_ ? $_ eq $v : !defined $v : !defined $_ } @list;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::T

=head1 VERSION

version 0.0405

=head1 DESCRIPTION

Types for L<Evo::Class/"check">. Right now there aren't so many of them.

=head1 SYNOPSYS

  {

    package My::Foo;
    use Evo -Class, '-Class::T *';
    has status => check => T_ENUM("ok", "not ok");

  }

  my $obj = My::Foo->new(status => "ok");
  $obj->status("badVal");    # dies

=head1 FUNCTIONS

=head2 T_ENUM

  my $check = T_ENUM("ok", "good");
  my($ok, $err) = $check->("bad");

Enum checker - a value must be one of the list;

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
