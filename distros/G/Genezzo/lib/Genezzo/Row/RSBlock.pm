#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSBlock.pm,v 7.3 2007/11/18 08:14:20 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Row::RSBlock;
# NOTE: based upon Genezzo::PHBlock

use Genezzo::Util;
use Genezzo::PushHash::PushHash;
use Genezzo::Block::RDBlock;
use Carp;
use warnings::register;

our @ISA = "Genezzo::PushHash::PushHash" ;

sub TIEHASH
{ #sub new 
#    greet @_;
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %optional = (
                    RDBlock_Class => "Genezzo::Block::RDBlock",
                    dbh_ctx       => {}
                    );

    my %args = (
                %optional,
                @_);
    
    my %rdhash;
    # NOTE: caller should check RDBlock_Class for correctness
    my $tie_rdblock = tie %rdhash, $args{RDBlock_Class}, %args;
    return undef
        unless (defined($tie_rdblock));
    $self->{ref} = \%rdhash;
    $self->{tie_rdblock} = $tie_rdblock;
    
    return bless $self, $class;

} # end new

# private
# sub _thehash 
sub _thehash
{
#    whoami ();
    my $self = shift;

    return $self->{ref};
}

# private
sub _realSTORE{ 
#    whoami (); 
    $_[0]->_thehash()->{$_[1]} = $_[2] }

# HPush public method (not part of standard hash)
sub HPush
{
#    whoami ();
    my ($self, $value) = @_;
    return ($self->{tie_rdblock}->HPush($value));
}

sub HCount
{
#    whoami ();
# FETCHSIZE equivalent, i.e. scalar(@array)
    my $self = shift;
    return ($self->{tie_rdblock}->FETCHSIZE());
}

sub _fetch2 {
#    whoami (); 
    my $self = shift;
    return ($self->{tie_rdblock}->_fetch2(@_));
}
sub _exists2 {
#    whoami (); 
    my $self = shift;
    return ($self->{tie_rdblock}->_exists2(@_));
}

# expose rdblock metadata methods
sub _get_meta_row {
    my $self = shift;
    return ($self->{tie_rdblock}->_get_meta_row(@_));
}

sub _set_meta_row {
    my $self = shift;
    return ($self->{tie_rdblock}->_set_meta_row(@_));
}

sub _delete_meta_row {
    my $self = shift;
    return ($self->{tie_rdblock}->_delete_meta_row(@_));
}

sub _update_meta_zero {
    my $self = shift;
    return ($self->{tie_rdblock}->_update_meta_zero(@_));
}

sub _fetchmeta {
    my $self = shift;
    return ($self->{tie_rdblock}->_fetchmeta(@_));
}

sub BlockInfoString {
    my $self = shift;
    return ($self->{tie_rdblock}->BlockInfoString(@_));
}

sub BlockInfo {
    my $self = shift;
    return ($self->{tie_rdblock}->BlockInfo(@_));
}

# standard hash methods follow
#sub STORE # same as pushhash store
#{
##    whoami ();
#    my ($self, $place, $value) = @_;
#
#    if ($place =~ m/^PUSH$/)
#    {
#        $place = $self->HPush($value);
#        return undef 
#            unless (defined($place));
#        return $value;
#    }
#    else
#    {
#        unless ($self->EXISTS($place))
#        {
#            carp "No such key: $place "
#                if warnings::enabled();
#            return undef;
#        }
#    }
#
#    return $self->_realSTORE ($place, $value);
#}
 
sub FETCH    { 
#    whoami (); 
    my $ref = $_[0]->_thehash ();
    $ref->{$_[1]} }
sub FIRSTKEY {
#    whoami (); 
    my $self = shift;
    return ($self->{tie_rdblock}->FIRSTKEY());
}
sub NEXTKEY  { 
#    whoami (); 
    my ($self, $prevkey) = @_;
    return ($self->{tie_rdblock}->NEXTKEY($prevkey));
}
sub EXISTS   { 
#    whoami (); 
    my $ref = $_[0]->_thehash ();
    exists $ref->{$_[1]} 
}
sub DELETE   { 
#    whoami (); 
    delete $_[0]->_thehash()->{$_[1]} 
}
sub CLEAR    {
#    whoami (); 
    %{$_[0]->_thehash()} = () 
    }

END {

}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Row::RSBlock - Row Source Block

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

Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.

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

