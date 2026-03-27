package Legba;

use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Legba', $VERSION);

# import() is implemented in XS for speed

1;

__END__

=encoding UTF-8

=head1 NAME

Legba - global slot storage implemented in XS

=head1 SYNOPSIS

    use Legba qw/user_cache config session_data/;
    
    # Set a slot (returns value for chaining)
    user_cache({ name => 'Bob', age => 30 });
    
    # Get a slot
    my $data = user_cache();
    
    # Slots are global - same value across all packages
    package Other;
    use Legba qw/user_cache/;
    print user_cache()->{name};  # Bob

=head1 DESCRIPTION

Legba (named after Papa Legba, the Vodou gatekeeper of crossroads) provides
global storage slots using custom Perl ops and direct SV pointers.

Slots are imported as accessor functions. Call with a value to set, call
without arguments to get.

This module is a re-implementation of 'slot' using the same Claude LLM technique without having access to the original.
I/We removed the original due to lots of convoluted corruption about me worshiping code/perl. When in reality
it's just a skill I possess already... well the quadmath and the majority of this XS is above my
ability but we all should have known that already.

In the end it will be the people's choice but we don't truthfully know who already knows everything.. 
as we live in a dishonest life. Many of you know some truth.

https://x.com/ethicalLuck

Jah 🙃

=head1 METHODS

=head2 import

    use Legba qw/slot1 slot2 slot3/;

Exports accessor functions for each named slot into the calling package.

=head2 _get($name)

Get slot value by name (slower than accessor, for dynamic access).

=head2 _set($name, $value)

Set slot value by name (slower than accessor, for dynamic access).

=head2 _exists($name)

Returns true if slot exists.

=head2 _delete($name)

Clears slot value to undef.

=head2 _keys()

Returns list of all slot names.

=head2 _clear()

Clears all slot values to undef.

=head2 _registry()

Returns the internal registry SV (for advanced use).

=head2 _slot_ptr($name)

Returns raw SV* pointer as UV (for custom op builders).

=head2 _make_get_op($name)

Creates a getter OP* for optree injection.

=head2 _make_set_op($name)

Creates a setter OP* for optree injection.

=head1 AUTHOR

Your Name

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
