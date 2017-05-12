#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/PushHash/RCS/PHNoUpdate.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::PushHash::PHNoUpdate;

use Genezzo::PushHash::PushHash;
use Carp;
use warnings::register;

our @ISA = "Genezzo::PushHash::PushHash" ;

# only support Push(Insert) and Delete, but no Update of an existing
# value
#
# Example: a pushhash based on /proc, where you can insert (create)
# new processes or delete (kill) processes, but not update the process name.
sub STORE
{
    my ($self, $place, $value) = @_;

    if ($place =~ m/^PUSH$/)
    {
        $place = $self->HPush($value);
        return undef 
            unless (defined($place));
        return $value;
    }
    else
    {
        carp "Cannot update key: $place with value: $value"
            if warnings::enabled();
        return undef;
    }

    return $self->_realSTORE ($place, $value);
}
 


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::PushHash::PHNoUpdate - Push Hash that only supports delete and insert

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 #TODO

=over 4

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
