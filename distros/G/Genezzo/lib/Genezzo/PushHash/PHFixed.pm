#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/PushHash/RCS/PHFixed.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::PushHash::PHFixed;

#use Genezzo::Util;
use Genezzo::PushHash::PushHash;
use Carp;
use warnings::register;

our @ISA = qw(Genezzo::PushHash::PushHash) ;

sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;

    my %args = (
                @_);

    $self->{ __PACKAGE__ . ":ROWCOUNT"} = 0;

    return 1;
}

sub TIEHASH
{ #sub new 
    #greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = Genezzo::PushHash::PushHash->TIEHASH(@_);

    my %args = (@_);

    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

our $MAXCOUNT = -1;

sub HPush
{
    if ($MAXCOUNT > 1)
    {
        unless ($_[0]->{ __PACKAGE__ . ":ROWCOUNT"} < $MAXCOUNT)
        {
            carp "Count $MAXCOUNT exceeded"
                if warnings::enabled();
            return (undef);
        }
    }
    
    $_[0]->{ __PACKAGE__ . ":ROWCOUNT"} += 1;
    
    return $_[0]->SUPER::HPush($_[1]);
}

sub DELETE   
{ 
    my $retval = $_[0]->SUPER::DELETE($_[1]);

    $_[0]->{ __PACKAGE__ . ":ROWCOUNT"} -= 1
        if (defined($retval));

    return ($retval);
}

sub CLEAR    
{ 
    my $retval = $_[0]->SUPER::CLEAR();
    $_[0]->{ __PACKAGE__ . ":ROWCOUNT"} = 0
        if (defined($retval));

    return ($retval);

}

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::PushHash::PHFixed - fixed-size push hash

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


