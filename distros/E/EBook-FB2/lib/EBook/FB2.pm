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

package EBook::FB2;

our $VERSION = 0.2;

use Moose;
use XML::DOM;
use XML::DOM::XPath;
use Carp;

use EBook::FB2::Description;
use EBook::FB2::Binary;
use EBook::FB2::Body;

has description => ( 
    isa     => 'Object',
    is      => 'rw', 
);

has _bodies => (
    isa     => 'ArrayRef[Object]',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        bodies      => 'elements',
        add_body    => 'push',
    },
);

has _binaries => (
    isa     => 'ArrayRef[Object]',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        binaries    => 'elements',
        add_binary  => 'push',
    },
);

sub load
{
    my ($self, $file) = @_;
    my $parser = XML::DOM::Parser->new();
    my $xp;
    eval {
        $xp = $parser->parsefile($file);
    };

    if ($@) {
        carp("Failed to parse $file");
        return;
    }

    my @nodes = $xp->findnodes('/FictionBook/description'); 
    if (@nodes != 1) {
        my $descriptions = @nodes;
        warn "There should be only one <description> element";
        return;
    }

    my $desc = EBook::FB2::Description->new();
    $desc->load($nodes[0]);
    $self->description($desc);

    # load binaries 
    @nodes = $xp->findnodes('/FictionBook/binary'); 
    foreach my $node (@nodes) {
        my $bin = EBook::FB2::Binary->new();
        $bin->load($node);
        $self->add_binary($bin);
    }


    # Load bodies 
    @nodes = $xp->findnodes('/FictionBook/body'); 
    foreach my $node (@nodes) {
        my $bin = EBook::FB2::Body->new();
        $bin->load($node);
        $self->add_body($bin);
    }

    # XXX: handle stylesheet?
    return 1;
}

1;

__END__
=head1 NAME

EBook::FB2

=head1 VERSION

Version 0.1

=head1 SYNOPSIS


    use EBook::FB2;

    my $fb2 = EBook::FB2->new;
    $fb2->load("/path/to/file.fb2");

=head1 SUBROUTINES/METHODS

=over 4

=item binaries()

Returns array of references to L<EBook::FB2::Binary> objects

=item bodies()

Returns array of references to L<EBook::FB2::Body> objects

=item description()

Returns reference to L<EBook::FB2::Description> object that contains book metadata

=item load($filename)

Load FB2 document from $filename


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
