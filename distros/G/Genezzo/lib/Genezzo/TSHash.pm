#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/TSHash.pm,v 7.2 2005/11/26 02:11:32 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

use Carp;
package Genezzo::TSHash;

use Genezzo::PushHash::PushHash;
our @ISA = "Genezzo::PushHash::PushHash" ;

sub _init
{
    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = $class->SUPER::TIEHASH(@_);

    my %args = (@_);
    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

# NOTE: copy in the values -- just pointing at references has weird
# effects, since an outside routine can modify the contents of
# referenced array while it is stored in the pushhash.  The copy makes
# the TSHash behavior equivalent to the RSTab packrow/unpackrow.

# HPush public method (not part of standard hash)
sub HPush
{
    my ($self, $value) = @_;
    my @packstr = @{ $value };

    return ($self->SUPER::HPush(\@packstr));
}

sub STORE
{
    my ($self, $place, $value) = @_;
    my @packstr = @{ $value };

    # need to avoid calling own hpush, which would doublepack the row
    if ($place =~ m/^PUSH$/)
    {
        $place = $self->SUPER::HPush(\@packstr);
        return undef 
            unless (defined($place));
        return $value;
    }

    return ($self->SUPER::STORE($place, \@packstr));
}

sub FETCH    
{ 
    my ($self, $place) = @_;
    
    my $value = ($self->SUPER::FETCH($place));

    return (undef)
        unless (defined($value));

    my @outarr = @{ $value };
    
    return (\@outarr);

}

sub SQLPrepare
{
    my $self = shift;
    my %args = @_;
    $args{pushhash} = $self;

    my $sth = Genezzo::SQL_TSHash->new(%args);

    return $sth;
}

package Genezzo::SQL_TSHash;
use strict;
use warnings;
use Genezzo::Util;

sub _init
{
    my $self = shift;
    my %args = (@_);

    return 0
        unless (defined($args{pushhash}));
    $self->{pushhash} = $args{pushhash};

    if (defined($args{filter}))
    {
        $self->{SQLFilter} = $args{filter}; 
    }

    return 1;
}

sub new
{
 #   whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);
    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new


# SQL-style execute and fetch functions
sub SQLExecute
{
    my ($self, $filter) = @_;

#    $self->{SQLFilter} = $filter; # check this
#    $self->{SQLFetchKey} = $self->_joinrid("0", "0");

    my $ref = $self->_thehash ();

    # Note: reset the hash to the beginning (see Genezzo::PushHash,
    # various Tie classes) so the "each" call in NEXTKEY starts at the
    # beginning.  NEXTKEY ignores the SQLFetchKey value in this case.

    my $a = scalar keys %{$ref}; 

    # XXX: define filters and fetchcols
    return (1);
}

# XXX XXX XXX XXX:  create a separate dynamic package to
# hold the fetch state, vs keeping the fetch state in the base
# pushhash.  Then can maintain multiple independent SQLFetches open
# on same TSHash object.


# combine NEXTKEY and FETCH in a single operation
sub SQLFetch
{
    my ($self, $key) = @_;
    my $fullfilter = $self->{SQLFilter};
    my $filter = (defined($fullfilter)) ? $fullfilter->{filter} : undef;

    # use explicit key if necessary
#    $self->{SQLFetchKey} = $key
#        if (defined($key));

    my $ref = $self->_thehash ();

    while (my ($currkey, $outarr) = each %{$ref})
    {
        # XXX XXX XXX: need to add get_col_alias?
        # Note: always return the rid
        return ($currkey, $outarr)
            unless (defined($filter) &&
                    !(&$filter($self, $currkey, $outarr)));
    }

    return undef;
}

sub AUTOLOAD 
{
    my $self = shift;
    my $ph = $self->{pushhash};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    return ($ph->$newfunc(@_));
}



END {

}

1;


__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::TSHash - Table Space Hash

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item SQLFetch: need to handle get_col_alias for filter?

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

