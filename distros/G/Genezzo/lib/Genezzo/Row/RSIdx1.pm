#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSIdx1.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

use Carp;
package Genezzo::Row::RSIdx1;

use Genezzo::Util;
use Genezzo::PushHash::PushHash;
use Genezzo::Index::bt2;
use Genezzo::Index::bt3;
# XXX XXX XXX hphrowblk ??
our @ISA = "Genezzo::PushHash::PushHash" ;

sub _init
{
    my $self = shift;
    my %optional = (
                    # normal case - numeric key
                    pkey_type => "n",
                    use_IOT   => 1,

                    # unique key (no duplicates)
                    unique_key => 1
                    );

    my %args = (
                %optional,
                @_);

    my $bt = Genezzo::Index::bt3->new(%args);

    return 0
        unless (defined($bt));

#    whisper "success!";

    $self->{pkey_type} = $args{pkey_type};
    $self->{bt} = $bt;

    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = {} ; # $class->SUPER::TIEHASH(@_);

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


# HPush public method (not part of standard hash)
sub HPush
{
#    whoami;
    my ($self, $value) = @_;
#    greet $value;

    my @foo = @{$value};
    unless (scalar(@foo))
    {
        whisper "null key!";
        return undef;
    }

    my $kk  = shift @foo; # key as first column only
    my $vv  = \@foo;

    unless (defined($kk))
    {
        whisper "null key!";
        return undef;
    }

#    if ($self->EXISTS($kk)) # insert checks for duplicates now
#    {
#        whisper "duplicate key $kk";
#        return undef;
#    }
    
    my $stat = $self->{bt}->insert($kk, $vv);

    return undef
        unless ($stat);

    return ($kk);
}

sub HCount
{
    my $self = shift;
# FETCHSIZE equivalent, i.e. scalar(@array)
#    whoami;
    return ($self->{bt}->HCount());
}

sub STORE
{
#    whoami;
    my ($self, $place, $value) = @_;
#    my @packstr = @{ $value };

    if ($place =~ m/^PUSH$/)
    {
        return undef ;
    }

    my $oldval;
    if ($self->EXISTS($place))
    {
        $oldval = $self->FETCH($place);
#        greet $oldval;
        $self->DELETE($place);
    }

#    my @foo = ($place, $value);
    my $stat = $self->HPush($value); # Note: value array contains key (place)

    unless (defined($stat))
    {
        $self->HPush($oldval) # restore the old value if the new push fails...
            if (defined($oldval));
    }

    return ($stat);
}

sub FETCH    
{ 
#    whoami;
    my ($self, $place) = @_;
    
    my @row = $self->{bt}->search($place);

    pop @row; # remove the rid and array offset
    pop @row;

    my $vv = pop @row; # get the value array
    push @row, @{$vv}; # and flatten it into the a single row

    return (\@row);
}

sub EXISTS   
{
#    whoami;
    my ($self, $place) = @_;

    my @retval = $self->{bt}->search($place);

#    greet @retval;

    return 0
        unless (scalar(@retval) > 1);

    return 1;
}

sub DELETE   
{
    whoami;
    my ($self, $place) = @_;

    return $self->{bt}->delete($place);
}

sub CLEAR    
{
    whoami;
    my $self = shift;

    return $self->{bt}->btCLEAR();
}


sub SQLPrepare
{
#    whoami;
#    my ($self, $filter) = @_;
    my $self = shift;
    my %args = @_;
    $args{pkey_type} = $self->{pkey_type};
    $args{bt} = $self->{bt};

    my $sth = Genezzo::SQL_RSIdx1->new(%args);

#                                    pkey_type => $self->{pkey_type},
#                                    bt        => $self->{bt});
                                    #filter    => $filter);

    return $sth;
}

package Genezzo::SQL_RSIdx1;
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
    $self->{pkey_type} = $args{pkey_type};

    if (defined($args{filter}))
    {
        $self->{SQLFilter} = $args{filter};
        greet $args{filter};
        my $ff = $args{filter};

        my @both_keys = Genezzo::Util::GetIndexKeys($ff);
        
        greet @both_keys;

        if (scalar(@both_keys))
        {
            my @startkey = @{$both_keys[0]};
            my @stopkey  = @{$both_keys[1]};

            # need a start or stop key
            if ((scalar(@startkey) && (defined($startkey[0])))
                || (scalar(@stopkey) && (defined($stopkey[0]))))
            {
#                $self->{start_key} = $startkey[0];

                my %nargs;

                $nargs{start_key} = $startkey[0]
                    if (defined($startkey[0]));
                $nargs{stop_key}  = $stopkey[0]
                    if (defined($stopkey[0]));

                greet %nargs;

                my $searchhandle = 
                    $self->{bt}->SQLPrepare(%nargs);

                return 0
                    unless (defined($searchhandle));

                $self->{IndexSth} = $searchhandle;
            }

        }
    } # end if filter

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

    if (exists($self->{IndexSth}))
    {
        greet "index execute";

        $self->{SQLFetchKey} = 1;
        return $self->{IndexSth}->SQLExecute();
    }

    $self->{SQLFetchKey} = $self->hkeyFIRSTKEY();

    return (1);
}

# XXX XXX XXX XXX: create a separate dynamic package to hold the fetch
# state, vs keeping the fetch state in the base pushhash.  Then can
# maintain multiple independent SQLFetches open on same RSIdx1 object.

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

            pop @row; # remove extra search cols
            pop @row;
            

            # XXX XXX XXX: need a currkey for this index fetch case as
            # well - what's up with that?

        }
        else
        {

            @row = $self->hkeyFETCH($self->{SQLFetchKey});
#        greet @row;
            $currkey = $self->{SQLFetchKey};

            # save the value of the key because we pre-advance to the next one
            $self->{SQLFetchKey} = $self->hkeyNEXTKEY($self->{SQLFetchKey});
        }
        my $vv = pop @row; # get the value array
        push @row, @{$vv}; # and flatten it into the a single row
        my $outarr  = \@row;
        my $rid = $outarr->[0]; # NOTE: key is "rid" for index
        # XXX XXX : should convert to base64 

        # Note: always return the rid
        return ($rid, $outarr)
            unless (defined($filter) &&
                    !(&$filter($self, $currkey, $outarr)));
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

Genezzo::Row::RSIdx1.pm - Row Source InDeX tied hash class.  A
hierarchical pushhash (see L<Genezzo::PushHash::hph>) class that stores
a pushhash as a btree via L<Genezzo::Row::RSTable>.


=head1 SYNOPSIS

 use Genezzo::Row::RSIdx1;

 # see Tablespace.pm -- implementation and usage is tightly tied
 # to genezzo engine...

 my %args = (
             # need tablename, bufcache, etc...
             tablename => ...
             tso       => ...
             bufcache  => ...
                    );

  my %td_hash;
  $tie_val = 
    tie %td_hash, 'Genezzo::Row::RSIdx1', %args;

 # pushhash style 
 my @rowarr = ("this is a test", "and this is too");
 my $newkey = $tie_val->HPush(\@rowarr);

 @rowarr = ("update this entry", "and this is too");
 $tied_hash{$newkey} = \@rowarr;

 my $getcount = $tie_val->HCount();

=head1 DESCRIPTION

RSIdx1 is index-only table class that packs complex objects into byte
buffers via B<Genezzo::Block::RDBlock>, maintaining a b-tree index on the
primary key columns.  Unlike a standard index, all of the table data
(keys and value columns) is stored in a single b-tree.

=head1 ARGUMENTS

=over 4

=item tablename
(Required) - the name of the table

=item tso
(Required) - tablespace object from B<Genezzo::Tablespace>

=item bufcache
(Required) - buffer cache object from B<Genezzo::BufCa::BCFile>


=back


=head1 CONCEPTS


=head1 FUNCTIONS


=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item HSuck: 

=item FirstCount/NextCount: do real estimate vs fake

=item should pass leftmost blockno explicitly versus rely on RSTab FIRSTKEY

=item rectify some overlap between btHash and this module

=item could encode multiple column key into single col rid using MIME::Base64
      encode of a packed row.
      should check dependency for perl 5.6 and add to Makefile.PL.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<Genezzo::PushHash::HPHRowBlk>,
L<Genezzo::PushHash::hph>,
L<Genezzo::PushHash::PushHash>,
L<Genezzo::Tablespace>,
L<Genezzo::Row::RSTab>,
L<Genezzo::Block::RDBlock>,
L<Genezzo::BufCa::BCFile>,
L<Genezzo::BufCa::BufCaElt>,
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
