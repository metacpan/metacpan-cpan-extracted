#------------------------------------------------------------------------
# Override 'flush' in HTML::Mason::Buffer to correctly handle
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

package MasonX::Buffer2;

use HTML::Mason::Buffer;
use base qw(HTML::Mason::Buffer);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

# override HTML::Mason::Buffer::flush method with a 'smart' flush
# that returns a non-undef value if anyting was flushed.

sub flush
{
    #print STDERR "MasxonX::Buffer2 flush start\n";

    my $self = shift;
    return if $self->ignore_flush;

    $self->_make_output;
    my $output = $self->{output};
    return unless defined($$output) and length($$output);
    $self->{parent}->receive( $$output ) if $self->{parent};

    $self->clear;
    
    # Only change here... if buffer was empty we'd have returned already

    #print STDERR "MasxonX::Buffer2 flush returns 1\n";

    return 1;
}

1;
