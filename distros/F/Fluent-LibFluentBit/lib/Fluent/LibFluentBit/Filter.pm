package Fluent::LibFluentBit::Filter;
our $VERSION = '0.02'; # VERSION
use parent 'Fluent::LibFluentBit::Component';

# ABSTRACT: Fluent-Bit filter


sub _build_id {
   my ($self, $name)= @_;
   $self->context->flb_filter($name)
}

sub _set_attr {
   my ($self, $key, $val)= @_;
   $self->context->flb_filter_set($self->id, $key, $val);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Fluent::LibFluentBit::Filter - Fluent-Bit filter

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 my $filter= $libfluentbit->add_filter($plugin_name);
 $filter->configure( %config );

=head1 DESCRIPTION

See L<Fluent::LibFluentBit::Component> for API.

See L<fluent-bit documentation|https://docs.fluentbit.io/manual/pipeline/filters>
for the different types and attributes for filters.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
