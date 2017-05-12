#------------------------------------------------------------------------
# Override 'flush_buffer' in HTML::Mason::Request to correctly handle
# redirects in Apache2/mod_perl 2.
#
# Beau E. Cox <beau@beaucox.com>
# March 2004
#
# (C)Copyright 2004 Beau E. Cox.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#------------------------------------------------------------------------

package MasonX::Request2;

use HTML::Mason::Request;
use MasonX::Buffer2;

use base qw(HTML::Mason::Request);

# override HTML::Mason::Buffer class
BEGIN
{
    __PACKAGE__->contained_objects
	(
	 buffer     => { class => 'MasonX::Buffer2',
			 delayed => 1,
			 descr => "This class receives component output and dispatches it appropriately" },
	);
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

# replace HTML::Mason::Request's flush_buffer with a smart version
# of Buffer that informs the caller if anything was actually flushed.

sub flush_buffer
{
    #print STDERR "MasxonX::Request2 flush_buffer start\n";

    my $self = shift;
    # A flag to indicate if something was flushed
    my $something_flushed = undef;
    for ($self->buffer_stack) {
        last if $_->ignore_flush;
        # Need to make flush indicate if it flushed anything
        $something_flushed ||= $_->flush;
    }

    #printf STDERR "MasxonX::Request2 flush_buffer returns - %s\n",
    #( defined $something_flushed ) ? $something_flushed : 'undef';

    return $something_flushed;
}

1;
