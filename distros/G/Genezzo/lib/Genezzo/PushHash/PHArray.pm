#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/PushHash/RCS/PHArray.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::PushHash::PHArray;

use Genezzo::Util;
#use Genezzo::PushHash::PushHash;
use Carp;
use warnings::register;

our @ISA = "Genezzo::PushHash::PushHash" ;

sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;

    my @needarr = (); # supply an array reference if needed...

    # NOTE: should always generate a new array if PHArray is loaded as
    # factory method

    my %args = (arrayref => \@needarr,
                @_);

    $self->{ref} = $args{arrayref};

    my $refthing = ref($self->{ref});
    croak "supplied $refthing , requires ARRAY" 
        unless ($refthing eq "ARRAY");

    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

# private
# sub _thehash 
# NOTE: now an array, but implementation is the same

# private
my $_Next_ID = sub
{
    my $ref = $_[0]->_thehash ();
    return scalar(@{$ref});
};
# HPush public method (not part of standard hash)
sub HPush
{
    my $place = &$_Next_ID($_[0]);
    return undef 
        unless (defined($place));
    return undef 
        unless ($_[0]->_realSTORE( $place, $_[1]));
    return ($place);
}


# private
sub _realSTORE{ $_[0]->_thehash()->[$_[1]] = $_[2] }

# use parent HPush, STORE
sub HCount
{
# FETCHSIZE equivalent, i.e. scalar(@array)
    my $ref = $_[0]->_thehash ();
    return (scalar (@{$ref})); 
}
 
sub FETCH    { my $ref = $_[0]->_thehash ();
               $ref->[$_[1]] }
sub NEXTKEY  { 
#    $_[0]->{ __PACKAGE__ . "CURR_ID"} += 1;
    my $kk = $_[1] + 1;

    return undef
        unless ($_[0]->EXISTS($kk));

    return ($kk);
}

sub FIRSTKEY { 
#    $_[0]->{ __PACKAGE__ . "CURR_ID"} = -1;
    return $_[0]->NEXTKEY(-1);
}
sub EXISTS   {
    # must be numeric for exists in array
    return 0
        if ($_[1] !~ /\d+/);
    my $ref = $_[0]->_thehash ();
    exists ($ref->[$_[1]]);
    }

sub DELETE   { 

    # XXX: only allow deletion from end -- otherwise, beginning or
    # intermediate array locations are set to undef, which breaks
    # firstkey/nextkey

    my $place = &$_Next_ID($_[0]);
    return undef 
        unless (defined($place));
    if ($_[1] != ($place - 1))
    {
        carp "Cannot delete key: $_[1] - not last key"
            if warnings::enabled();
        return undef;
    }
    delete $_[0]->_thehash()->[$_[1]] ;
}
sub CLEAR    { @{$_[0]->_thehash()} = () }


END {

}


1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::PushHash::PHArray - Push Hash Array implementation

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
