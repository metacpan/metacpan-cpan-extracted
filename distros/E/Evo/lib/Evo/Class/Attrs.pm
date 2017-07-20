package Evo::Class::Attrs;
use Evo -Export;

our $IMPL
  = eval { require Evo::Class::Attrs::XS; 1 } ? 'Evo::Class::Attrs::XS' : 'Evo::Class::Attrs::PP';

export_proxy $IMPL, '*';
our @ISA = ($IMPL);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::Attrs

=head1 VERSION

version 0.0405

=head1 METHODS

=head2 gen_attr ($self, $name, $type, $value, $check, $ro)

Register attribute and return an 'attribute' code. C<$type> can be on of

=head2 slots

return slots of attributes

=begin :list



=end :list

* relaxed - simple attr
* default - attr with default C<$value>
* default_code - attr with default value - a result of invocation of the C<$value>
* required - a value that is required
* lazy - like default_code, but C<$value> will be called on demand

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
