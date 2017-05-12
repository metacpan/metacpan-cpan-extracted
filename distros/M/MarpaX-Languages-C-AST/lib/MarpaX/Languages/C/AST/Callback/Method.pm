use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Callback::Method;
use MarpaX::Languages::C::AST::Callback::Option;
use Class::Struct
    description        => '$',
    extra_description  => '$',
    method             => '@',        # [ CODE ref, CODE ref arguments ]
    method_void        => '$',        # Prevent push to topic data
    method_mode        => '$',        # 'push' or 'replace'
    option             => 'MarpaX::Languages::C::AST::Callback::Option',
    ;

# ABSTRACT: Code reference for the Simple callback generic framework.

use Carp qw/croak/;

our $VERSION = '0.47'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Callback::Method - Code reference for the Simple callback generic framework.

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This module is describing the code reference for the Simple Callback framework. The new method supports these items:

=over

=item description

Any string that describes this event. This string is usually the event itself for convenience with the qw/auto/ condition.

=item extra_description

Any string that describes this event even more. Used only for logging in case the description is set to the event name for convenience with the qw/auto/ condition.

=item method

A reference to an array containing a CODE REFERENCE in the first index, then the CODE ARGUMENTS. Or the single string 'auto'. In case of a CODE reference, The method will be called as $CODE($self, $callback, $eventsp, @CODE_ARGUMENTS) where $self is a reference to the method object, $callback is a reference to the Callback package that triggered the call, $eventsp is a reference to an array containing the events sent to the Callback::exec() method, and @CODE_ARGUMENTS are the given arguments, . In case of the single string 'auto', the description attribute will be used as a source topic, and for every targeted topic associated to the method, the dereferenced array content of the description data will be pushed, replaced, or nothing depending on the method_void and method_mode attributes.

=item method_mode

Default is to push any eventual topic data the output of the method. This flag can have values 'push' (default) or 'replace'. When value is 'replace', topic data is replaced by the method output.

=item method_void

Setting this flag to a true value will disable any use of method output, leaving topic data as is.

=item option

A reference to a MarpaX::Languages::C::AST::Callback::Option object.

=back

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
