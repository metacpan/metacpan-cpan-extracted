package ExampleClass::Base;
use strict;
use warnings;

=head1 NAME

ExampleClass::Base

=head1 METHODS

=head2 inherited_method

This is a parent method.

=cut

sub inherited_method { }

=head2 subclassed_method

This is a subclassed method - we should not see this text.

=cut

sub subclassed_method { }

=head2 _private_method

As a private method this should be invisible.

=cut

sub _private_method { }

1;

