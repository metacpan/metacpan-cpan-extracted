#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/RDBArray.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Block::RDBArray;
use Genezzo::Util;
use Genezzo::Block::RDBlkA;

use Tie::Array;
our @ISA = "Tie::Array" ;

#use Genezzo::Util;
use Carp;
use warnings::register;


sub _init
{
#    whoami;
#    greet @_;
    my $self = shift;
    my %optional = (RDBlock_Class => "Genezzo::Block::RDBlkA");
    my %args = (%optional,
                @_);

    my $blockclass = $args{RDBlock_Class};
    unless (   ($blockclass eq "Genezzo::Block::RDBlkA")
            || (eval "require $blockclass"))
    {
        carp "no such package - $blockclass"
            if warnings::enabled();

        return undef;
    }

    # Row Directory Block tie hash as optional argument, else create
    # one with arg list

    my %h1;
    $self->{h1} = \%h1;

    my $rdh = exists($args{RDBlockHash}) ?
        $args{RDBlockHash} :
        (tie %h1, $args{RDBlock_Class}, @_);

    return undef
        unless (defined($rdh));

    return undef
        unless ($rdh->isa("Genezzo::Block::RDBlkA"));

    $self->{rdh} = $rdh;
    return 1;
}

sub TIEARRAY
{ #sub new
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = {};
    
    my %args = (@_);

    return undef
        # XXX: can't call self on unblessed reference here
        unless (_init($self, %args));

    return bless $self, $class;

} # end new


sub DESTROY { }
sub EXTEND  { }          
sub UNSHIFT 
{
    my $self = shift; 
    my $rdh  = $self->{rdh};
    # XXX : special funniness for array vs scalar context
    return ($rdh->HSplice(0,0,@_))[0];
}                 
sub SHIFT   
{ 
    my $self = shift; 
    my $rdh  = $self->{rdh};
    # XXX : special funniness for array vs scalar context
    return ($rdh->HSplice(0,1))[0];
}                 
sub CLEAR   
{ 
    my $self = shift; 
    my $rdh  = $self->{rdh};
    return $rdh->CLEAR();
}

sub PUSH 
{  
    my $self = shift; 
    my $rdh  = $self->{rdh};
    return $rdh->PUSH(@_);
}

sub POP 
{
    my $self = shift; 
    my $rdh  = $self->{rdh};
    # XXX : special funniness for array vs scalar context
    return ($rdh->HSplice(-1))[0]; 
}          

sub SPLICE
{
    my $self = shift; 
    my $rdh  = $self->{rdh};
    return $rdh->HSplice(@_);
} 

sub EXISTS 
{
    my ($self, $place) = @_;
    my $rdh  = $self->{rdh};

    # must be numeric for exists in array
    return 0
        if ($place !~ /\d+/);

    return 0
        unless (defined($rdh->_offset2hkey($place)));

    return 1;
}

sub DELETE 
{
    my ($self, $place) = @_;
    my $rdh  = $self->{rdh};

#    return (undef) unless ($self->EXISTS($place));
    my $hkey = $rdh->_offset2hkey($place);
    
    return $rdh->DELETE($hkey);

}

sub FETCH
{
    my ($self, $place) = @_;
    my $rdh  = $self->{rdh};

#    return (undef) unless ($self->EXISTS($place));
    my $hkey = $rdh->_offset2hkey($place);
    
    return $rdh->FETCH($hkey);

}
sub FETCHSIZE
{
    my $self = shift; 
    my $rdh  = $self->{rdh};
    return $rdh->FETCHSIZE();

}
sub STORE
{
    my ($self, $place, $value) = @_;
    my $rdh  = $self->{rdh};

#    return (undef) unless ($self->EXISTS($place));
    my $hkey = $rdh->_offset2hkey($place);
    unless (defined($hkey))
    {
        # need to extend the array
        if ($place >= $self->FETCHSIZE())
        {
            return undef
                unless ($self->STORESIZE($place + 1));
        }
    }
    $hkey = $rdh->_offset2hkey($place);
    return undef
        unless (defined($hkey));
    return $rdh->STORE($hkey, $value);

}

sub STORESIZE
{
    my ($self, $scnt) = @_; 
    my $rdh  = $self->{rdh};
    
    my $hcount  = $rdh->FETCHSIZE();

    # XXX XXX XXX : need to check return vals for PUSH and SPLICE

    # XXX XXX : could be more efficient with HSplice
    while ($scnt > $hcount)
    {
#        $self->PUSH(undef);
        my $push_stat = $rdh->HPush(undef);
        return 0
            unless (defined($push_stat));
        $scnt--;
    }
    # if $scnt == $hcount should be ok here...
    if ($scnt < $hcount)
    {
        my $estat;
        # pop => $rdh->HSplice(-1); 
        $rdh->HeSplice(\$estat, $scnt - $hcount); 
        return 0
            if (defined($estat));
    }
    return 1;
}

END {

}


1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::RDBArray - Row Directory Block Array interface

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
