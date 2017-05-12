#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/BufCa/RCS/DirtyScalar.pm,v 7.4 2006/10/20 18:52:16 claude Exp claude $
#
# copyright (c) 2003,2004,2005,2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::BufCa::DirtyScalar;

use Genezzo::Util;
use Tie::Scalar;
#use Carp;
#use warnings::register;

our @ISA = qw(Tie::StdScalar) ;

sub TIESCALAR {
    my $class = shift;
    my $instance = shift || undef;
    # XXX: could use an array for efficiency
    # [0] for the ref, [1] for the callback
    my $self = {};
    $self->{ref} = \$instance;

    return bless $self, $class;
}

sub FETCH {
#    whoami;
    return ${$_[0]->{ref}};
}

sub STORE {
#    whoami;
    
    if (defined($_[0]->{storecb}))
    {
# DEPRECATE
#        greet $_[0]->{bce}->GetInfo()
#            if (exists($_[0]->{bce}));

        $_[0]->{storecb}->();
    }
    ${$_[0]->{ref}} = $_[1];
}

sub DESTROY {
#    whoami;
    $_[0]->{ref} = ();
}

# supply a callback/closure to activate for during STORE
sub _StoreCB
{
#    whoami;
    my $self = shift;
    $self->{storecb} = shift if @_ ;
    return $self->{storecb};
}

# DEPRECATE
# set the buffer cache element associated with this tie
sub SetBCE
{
#    whoami;

    my $self     = shift;
    $self->{bce} = shift;

}

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::BufCa::DirtyScalar - Detect modifications to scalar

=head1 SYNOPSIS

=head1 DESCRIPTION

BufCaElt uses DirtyScalar to detect when a data block is modified.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  _StoreCB - a callback function that is activated on every STORE, 
       i.e., whenever the scalar is updated.  BufCaElt uses this function
       to set a "dirty" bit for the buffer.

=item  SetBCE - set a reference back to the BufCaElt that owns this tie.
       Some DirtyScalar hook routines need to query the BufCaElt info hash
       via BufCaElt::GetInfo.

=back

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item Deprecate SetBCE: can shift responsibility and functionality to
      storeCB which will contain a hook, versus directly overloading STORE
      here.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003, 2004, 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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
