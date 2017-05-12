# Copyright (c) 2009, 2010 Oleksandr Tymoshenko <gonzo@bluezbox.com>
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

package EBook::FB2::Binary;

use Moose;
use MIME::Base64;

has [qw/content_type data id/] => ( isa => 'Str', is => 'rw' );

sub load
{
    my ($self, $node) = @_;

    my @nodes = $node->findnodes('@id');
    if (@nodes) {
        $self->id($nodes[0]->getValue());
    }

    @nodes = $node->findnodes('@content-type');
    if (@nodes) {
        $self->content_type($nodes[0]->getValue());
    }

    # XXX: eval this, it might fail with invalid data
    my $decoded = MIME::Base64::decode($node->string_value());
    $self->data($decoded)
}

1;

__END__
=head1 NAME

EBook::FB2::Binary

=head1 SYNOPSIS

    EBook::FB2::Binary - class that represents <binary> element

=head1 SUBROUTINES/METHODS

=over 4

=item id()

Returns id of binary element

=item data()

Returns content of binary element (base64-decoded)

=item content_type()

Returns content-type of binary element

=back

=head1 AUTHOR

Oleksandr Tymoshenko, E<lt>gonzo@bluezbox.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to  E<lt>gonzo@bluezbox.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2009, 2010 Oleksandr Tymoshenko.

L<http://bluezbox.com>

This module is free software; you can redistribute it and/or
modify it under the terms of the BSD license. See the F<LICENSE> file
included with this distribution.
