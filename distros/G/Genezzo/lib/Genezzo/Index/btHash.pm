#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Index/RCS/btHash.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Index::btHash;

use Genezzo::Util;
use Genezzo::Index::bt2;
#use Genezzo::PushHash::PushHash;
use Tie::Hash;
use Carp;
use warnings::register;

our @ISA = qw(Tie::Hash) ;
#our @ISA = qw(Genezzo::PushHash::PushHash) ;

sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;
    my %optional = (BT_Index_Class => "Genezzo::Index::bt2",
                    BT_Fetch_Fix   => 0
                    );
    my %args = (%optional,
                @_);

    my $index_class = $args{BT_Index_Class};
    unless (   ($index_class eq "Genezzo::Index::bt2")
            || (eval "require $index_class"))
    {
        carp "no such package - $index_class"
            if warnings::enabled();

        # XXX XXX XXX: need to check if subclass of bt2...

        return undef;
    }

    $self->{bt} = $index_class->new(@_);
    $self->{fetch_fix} = $args{BT_Fetch_Fix};
    if (exists($args{key_type}))
    {
        $self->{key_type}  = $args{key_type};
    }

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


# count estimation
sub FirstCount 
{
    whoami;
    my $self = shift;

    my $key = $self->{bt}->hkeyFIRSTKEY();

    my @outi;
    push @outi, $key;

#    greet @outi;
    return $self->NextCount(@outi); 

} # FirstCount

# count estimation
sub NextCount
{
    whoami;
    my ($self, $prevkey, $esttot, $sum, $sumsq, $chunkcount, $totchunk) = @_;

    return undef
        unless (defined($prevkey));

    # XXX XXX: fake it - just return hcount

    if (defined($esttot))
    {
        $prevkey = undef;
        $sum = $self->HCount();
        $chunkcount = 1;
    }
    else
    {
        $sum = 0;
        $chunkcount = 0;
    }

    $esttot = $sum;
    $sumsq = $sum * $sum;

    $totchunk = 1;

    my @outi = ($prevkey, $esttot, $sum, $sumsq, $chunkcount, $totchunk);
#    greet @outi;

    return @outi;
} # nextcount


# some private and pushhash-style methods
sub _get_bt
{
    my $self = shift;
    return ($self->{bt});
}

sub HPush
{
    return undef;
}

sub HCount
{
    my $self = shift;
    return ($self->{bt}->HCount());
}

# standard hash methods follow
sub STORE
{
    my ($self, $place, $value) = @_;

    my $oldval;
    if ($self->EXISTS($place))
    {
        $oldval = $self->FETCH($place);
        whisper "update $place";
        $self->DELETE($place);
    }
    my $stat = $self->{bt}->insert($place, $value);

    unless ($stat)
    {   # restore the old value if the insert failed...
        $self->{bt}->insert($place, $oldval)
            if (defined($oldval));
        return undef;
    }

    return ($place);
}
 
sub FETCH    
{
    my ($self, $place) = @_;

    my @outi = $self->{bt}->search($place);

    return undef
        unless (scalar(@outi) > 1);

    shift @outi; # key 
    my $outval = shift @outi; 

    return $outval;
}


sub search
{
    my $self = shift;
    return $self->{bt}->search(@_);
}

# iterate fast using the underlying RDBlock hash keys directly
sub hkeyFIRSTKEY
{
    return $_[0]->{bt}->hkeyFIRSTKEY();
}
sub hkeyNEXTKEY
{
    return $_[0]->{bt}->hkeyNEXTKEY($_[1]);
}
sub hkeyLASTKEY
{
    return $_[0]->{bt}->hkeyLASTKEY();
}
sub hkeyPREVKEY
{
    return $_[0]->{bt}->hkeyPREVKEY($_[1]);
}
sub hkeyFETCH
{
    return $_[0]->{bt}->hkeyFETCH($_[1]);
}

# iterate by key value -- expensive, because requires a search to get
# the nextkey
sub FIRSTKEY 
{ 
#    whoami;
    my $self = shift;

    my $place = $self->{bt}->hkeyFIRSTKEY();

    return undef
        unless (defined($place));

    my @row = $self->{bt}->hkeyFETCH($place);

    return undef
        unless (scalar(@row) > 1);

    return $row[0]; # key portion of index row
}


sub NEXTKEY  
{
#    whoami;
    my ($self, $prevkey) = @_;

    my @outi = $self->{bt}->search($prevkey);

    my @row = $self->_searchNEXTKEY(@outi);

    return undef
        unless (scalar(@row) > 1);

    return $row[0]; # key portion of index row

}

sub _searchNEXTKEY  # make private - use bt2::SQLFetch instead
{
#    whoami;
    return undef
        unless (scalar(@_) > 4);

    my ($self, $key, $val, $currnode, $offset, $ieq, $k2) = @_;

    my $place = 
        $self->{bt}->offsetNEXTKEY(
                                   $self->{bt}->_joinplace("A",
                                                           $currnode, 
                                                           $offset));

    return undef
        unless (defined($place));

    my @row = $self->{bt}->offsetFETCH($place, 1);

    return undef
        unless (scalar(@row) > 1);

    return @row
        unless (defined($ieq));

    # if we have an equality function, (and a match key), make sure
    # the next row matches
    $k2 = $key
        unless (defined($k2));

    return @row
        if (&$ieq ($k2, $row[0]));

    return undef;
} # end searchnextkey

sub EXISTS   
{
    my ($self, $place) = @_;

    my @retval = $self->{bt}->search($place);

    return 0
        unless (scalar(@retval) > 1);

    return 1;
}

sub DELETE   
{
    my ($self, $place) = @_;

    return $self->{bt}->delete($place);
}

sub CLEAR    
{
    my $self = shift;

    return $self->{bt}->btCLEAR();
}

sub SQLPrepare
{
#    whoami;
    my $self = shift;
    my %args = @_;
    $args{bt} = $self->{bt};
    $args{BT_Fetch_Fix} = $self->{fetch_fix};
    if (exists($self->{key_type}))
    {
        $args{key_type} = $self->{key_type}; 
    }

    my $sth = Genezzo::SQL_btHash->new(%args);

#                                    pkey_type => $self->{pkey_type},
#                                    bt        => $self->{bt});
                                    #filter    => $filter);

    return $sth;
}

package Genezzo::SQL_btHash;
use strict;
use warnings;
use Genezzo::Util;

sub _init
{
    my $self = shift;
    my %args = (@_);

#    whoami;

    return 0
        unless (defined($args{bt}));
    $self->{bt}        = $args{bt};
    if (exists($args{key_type}))
    {
        $self->{key_type}  = $args{key_type};
    }

    $self->{fetch_fix} = $args{BT_Fetch_Fix};

    my %nargs;
    $nargs{BT_Fetch_Fix} =  $args{BT_Fetch_Fix};
    my ($got_startkey, $got_stopkey) = (0,0);

    if (exists($args{start_key}))
    {
        $nargs{start_key} = $args{start_key};
        $got_startkey = 1;
    }
    if (exists($args{stop_key}))
    {
        $nargs{stop_key} = $args{stop_key};
        $got_stopkey = 1;
    }

    if (defined($args{filter}))
    {
        $self->{SQLFilter} = $args{filter};
        greet $args{filter};
        my $ff = $args{filter};

        my @both_keys = Genezzo::Util::GetIndexKeys($ff);
        
        greet @both_keys;

        if (scalar(@both_keys)
            && (exists($self->{key_type}))
            && ($self->{fetch_fix}))
        {
            my @startkey = @{$both_keys[0]};
            my @stopkey  = @{$both_keys[1]};

            # need a start or stop key
            unless ($got_startkey)
            {
                my $bad_key = 0;
                if (scalar(@startkey) == scalar(@{$self->{key_type}}))
                {
                    for my $kkey (@startkey)
                    {
                        unless (defined($kkey))
                        {
                            $bad_key = 1;
                            last;
                        }
                    }
                    $nargs{start_key} = \@startkey
                        unless ($bad_key);
                }
            }
            unless ($got_stopkey)
            {
                my $bad_key = 0;
                if (scalar(@stopkey) == scalar(@{$self->{key_type}}))
                {
                    for my $kkey (@stopkey)
                    {
                        unless (defined($kkey))
                        {
                            $bad_key = 1;
                            last;
                        }
                    }
                    $nargs{stop_key} = \@stopkey
                        unless ($bad_key);
                }
            }

            greet %nargs;

        } # end if got both keys
    } # end if filter

    my $searchhandle = 
        $self->{bt}->SQLPrepare(%nargs);

    return 0
        unless (defined($searchhandle));

    $self->{IndexSth} = $searchhandle;

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
#    whoami;
    my ($self, $filter) = @_;

    return 0
        unless (exists($self->{IndexSth}));

    $self->{SQLFetchKey} = 1;
    return $self->{IndexSth}->SQLExecute();
}

# XXX XXX XXX XXX: create a separate dynamic package to hold the fetch
# state, vs keeping the fetch state in the base pushhash.  Then can
# maintain multiple independent SQLFetches open on same btHash object.

# combine NEXTKEY and FETCH in a single operation
sub SQLFetch
{
#    whoami;
    my ($self, $key) = @_;
    my $fullfilter = $self->{SQLFilter};
    my $filter = (defined($fullfilter)) ? $fullfilter->{filter} : undef;

    # use explicit key if necessary
#    $self->{SQLFetchKey} = $key
#        if (defined($key));

    while (defined($self->{SQLFetchKey}))
    {
        my @row;     
        my $currkey;

        if (exists($self->{IndexSth}))
        {
#            greet "index fetch";

            @row = $self->{IndexSth}->SQLFetch();

#            greet @row;

            unless (scalar(@row) > 1)
            {
                $self->{SQLFetchKey} = undef;
                return undef;
            }

#            $currkey = shift @row;
        }
        else
        {
            greet "oops!";
        }

 
        # NOTE: just return non-fixed rows...
       return @row
            unless ($self->{fetch_fix});

        my $vv = pop @row; # get the value array
        push @row, @{$vv}; # and flatten it into the a single row
        my $rid = shift @row;
        my $outarr  = \@row;
#        my $rid = $outarr->[0];

        # Note: always return the rid
        return ($rid, $outarr)
            unless (defined($filter) &&
                    !(&$filter($self, $rid, $outarr)));
    }

    return undef;
}


sub AUTOLOAD 
{
    my $self = shift;
    my $bt = $self->{bt};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    return ($bt->$newfunc(@_));
}



END {

}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Index::btHash - btree Hash tied hash class.  Makes a persistent
btree based upon B<Genezzo::Block::RDBlock> look like a conventional
hash.

=head1 SYNOPSIS

 use Genezzo::Index::btHash;

 my %tied_hash = ();

 my $tie_val = 
     tie %tied_hash, 'Genezzo::Index::btHash';


=head1 DESCRIPTION

btHash is a wrapper for B<Genezzo::Index::bt2>, a btree class based upon
B<Genezzo::Block::RDBlock>.  The tied hash is functionally complete, but
not particularly efficient in some cases due to the "impedance
mismatch" between the hash, btree and underlying RDBlock
implementation.  

=head1 FUNCTIONS


=head2 EXPORT

=head1 TODO

=over 4

=item  figure out whether should be a pushhash, hash, or rowsource

=item  SQLPrepare/Execute/Fetch:  clean up.  Shouldn't need to manage a
       distinction between using btHash as a row source and the old bt2
       api.  bt2 is wrong - should only have one Fetch style.  Should be
       able to use the index start/stop key vs filtering.

=item  NEXTKEY: broken in "dump tsidx" for case where create 2 tables, 
       insert some rows, then drop the first table (and don't COMMIT)
       and call dump tsidx.  Loops in NEXTKEY - never terminates for
       allfileused index.

=item  Add ReadOnly mode so can view indexes, but not insert/update/delete.

=back


=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

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
