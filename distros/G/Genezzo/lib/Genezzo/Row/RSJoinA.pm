#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSJoinA.pm,v 1.8 2006/10/26 07:24:28 claude Exp claude $
#
# copyright (c) 2005,2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Row::RSJoinA;

use Genezzo::Util;
use Genezzo::PushHash::PushHash;
use Carp;
use warnings::register;

our @ISA = "Genezzo::PushHash::PushHash" ;

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            return &$err_cb(%args);
        }
    }

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 1;
        }

    }
    # XXX XXX XXX
    print __PACKAGE__, ": ",  $args{msg};
#    print $args{msg};
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};

sub _init
{
#    whoami;
#    greet @_;
    my $self      =  shift;

    my %required  =  (
                      rs_list => "no rowsource list!",
                      dict    => "no dictionary!",
                      magic_dbh => "no dbh!"
                      );
    
    my %args = (@_);

    return 0
        unless (Validate(\%args, \%required));

    $self->{rs_list} = $args{rs_list};
    $self->{dict}    = $args{dict};
    $self->{dbh}     = $args{magic_dbh};

    if (defined($args{select_list}))
    {
#        greet $args{select_list};
        $self->{select_list} = $args{select_list};
        return 0
            unless (defined($args{alias_list}));
        $self->{alias_list} = $args{alias_list};
    }

    # XXX XXX XXX XXX: why doesn't this work?
    # need to build a composite rid if joining multiple row sources
    $self->{rid_fixup} = (scalar(@{$self->{rs_list}}) > 1);

    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
#    my $self     = $class->SUPER::TIEHASH(@_);
    my $self     = {};

    my %args = (@_);
    return undef
        unless (_init($self,%args));

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
    }

    return bless $self, $class;
} # end new

sub SelectList
{
#    whoami;
    my $self = shift;

#    return undef; # XXX XXX XXX XXX XXX XXX 

    return $self->{select_list}
       if (exists($self->{select_list}));

    return undef;
}

# HPush public method (not part of standard hash)
sub HPush
{
    my $self = shift;
    my $rs = $self->{rs_list};

#    whoami;

    return ($rs->HPush(@_));
}

sub HCount
{
    my $self = shift;
    my $rsl = $self->{rs_list};

    whoami;

    return 0 # terminate if no row sources
        unless (scalar(@{$rsl}));

    # multiply the counts (cartesian product)

    my $grandtotal = 1; # multiplicative identity for first row source

    for my $rs (@{$rsl})
    {
        $grandtotal *= $rs->HCount(@_);

        return 0 # terminate if one row source is empty...
            unless ($grandtotal);
    }
    return $grandtotal;
}

# standard hash methods follow
sub STORE
{
    my $self = shift;
    my $rs = $self->{rs_list};

    whoami;

    return ($rs->STORE(@_));
}
 
sub FETCH 
{
    my ($self, $place) = @_;
    return $self->_localFetch($place, "STANDARD");
}

sub _localFetch
{
    my ($self, $place, $mode) = @_;
    my $rsl = $self->{rs_list};

#    whoami;

    my @placelist;
    if ($self->{rid_fixup})
    {
        # URL-style substitution to handle spaces, weird chars
        $place =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

        @placelist = UnPackRow($place,
                               $Genezzo::Util::UNPACK_TEMPL_ARR); # 
    }
    else
    {
        push @placelist, $place;
    }

    if ($mode eq "STANDARD")
    {
        my @outval;

        if (scalar(@{$rsl} == 1))
        {
            my $keyval = shift @placelist;
            # NOTE: each rowsource must have at least one row for a valid join
            return undef
                unless (defined($keyval));

            return $rsl->[0]->FETCH($keyval);
        }

        for my $rs (@{$rsl})
        {
            my $keyval = shift @placelist;

            # NOTE: each rowsource must have at least one row for a valid join
            return undef
                unless (defined($keyval));
            
            push @outval, @{$rs->FETCH($keyval)};
        }
        return (\@outval);
    }
    elsif ($mode eq "HASH")
    {
        my $outhsh = {};

        my $idx = 0;

        for my $rs (@{$rsl})
        {
            my $keyval = shift @placelist;

            # NOTE: each rowsource must have at least one row for a valid join
            return undef
                unless (defined($keyval));
            my $alias = $self->{alias_list}->[$idx];
            $outhsh->{$alias} = $rs->FETCH($keyval);
            $idx++;
        }
        return $outhsh;
    }
    return undef;
}

sub FIRSTKEY 
{
    my $self = shift;
    my $rsl = $self->{rs_list};

#    whoami;

    my @firstkey;
    for my $rs (@{$rsl})
    {
        my $keyval = $rs->FIRSTKEY(@_);

        # NOTE: each rowsource must have at least one row for a valid join
        return undef
            unless (defined($keyval));

        push @firstkey, $keyval;
    }

    if ($self->{rid_fixup})
    {    
        # create a composite key out of all the firstkeys
        my $packstr = PackRow(\@firstkey);
        # URL-style substitution to handle spaces, weird chars
        $packstr =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;

        return ($packstr);
    }
    # just a single rowsource, return rid
    return $firstkey[0];

}

sub NEXTKEY  
{
    my ($self, $prevkey) = @_;
    my $rsl = $self->{rs_list};

#    whoami;

    return (undef)
        unless (defined ($prevkey));

    my @prevkeylist;
    if ($self->{rid_fixup})
    {
        # URL-style substitution to handle spaces, weird chars
        $prevkey =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

        @prevkeylist = UnPackRow($prevkey, 
                                 $Genezzo::Util::UNPACK_TEMPL_ARR); # 
    }
    else
    {
        push @prevkeylist, $prevkey;
    }

    my $idx = scalar(@prevkeylist) - 1;
    
    while ($idx >= 0)
    {
        # starting at the last rowsource in the list, get the nextkey 
        my $nextkey = $rsl->[$idx]->NEXTKEY($prevkeylist[$idx]);
        if (defined($nextkey))
        {
            # got it - update that portion of the composite key
            $prevkeylist[$idx] = $nextkey;

            # advanced trailing key portion - exit the loop and return
            # updated key value
            last;
        }
        else
        {
            # if rowsource at idx=0 is lastkey, then there is no NEXTKEY
            return undef
                unless ($idx > 0);

            # reset this portion of the key to its firstkey, then
            # decrement the index in order to advance the prior
            # segment of the key
            $nextkey = $rsl->[$idx]->FIRSTKEY();

            # NOTE: each rowsource must have at least one row for a valid join
            return undef 
                unless (defined($nextkey));
            $prevkeylist[$idx] = $nextkey;
            # not done yet -- get the nextkey for the prior portion
        }
        $idx--;
    } # end while
    
    return undef
        unless ($idx >= 0);

    if ($self->{rid_fixup})
    {    
        my $packstr = PackRow(\@prevkeylist);
        # URL-style substitution to handle spaces, weird chars
        $packstr =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;

        return ($packstr);
    }
    # just a single rowsource, return rid
    return $prevkeylist[0];

}

sub EXISTS   
{
    my $self = shift;
    my $rs = $self->{rs_list};

#    whoami;

    return ($rs->EXISTS(@_));
}

sub DELETE   
{
    my $self = shift;
    my $rs = $self->{rs_list};

#    whoami;

    return ($rs->DELETE(@_));
}

sub CLEAR    
{
    my $self = shift;
    my $rs = $self->{rs_list};

#    whoami;

    return ($rs->CLEAR(@_));
}

sub AUTOLOAD 
{
    my $self = shift;
    my $rsl = $self->{rs_list};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    if (scalar(@{$rsl}) == 1)
    {
        # handle FIRSTCOUNT, etc, for case of single row source
        return ($rsl->[0]->$newfunc(@_));        
    }
    return ($rsl->$newfunc(@_));
}

sub SQLPrepare # get a DBI-style statement handle
{
    my $self = shift;
    my %args = @_;
    $args{pushhash}  = $self;
    $args{rs_list}   = $self->{rs_list};
    $args{dict}      = $self->{dict};
    $args{magic_dbh} = $self->{dbh};

    if (defined($self->{select_list}))
    {
        $args{select_list} = $self->{select_list};
    }
    $args{use_select_list} = defined($self->SelectList());

    if ((exists($self->{GZERR}))
        && (defined($self->{GZERR})))
    {
        $args{GZERR} = $self->{GZERR};
    }

    my $sth = Genezzo::Row::SQL_RSJoinA->new(%args);

    return $sth;
}

package Genezzo::Row::SQL_RSJoinA;
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
    $self->{dict}     = $args{dict};
    $self->{dbh}      = $args{magic_dbh};

    return 0
        unless (defined($args{rs_list}));

    my $rsl = $args{rs_list};

    $self->{sql_rs}   = [];
    for my $rs (@{$rsl})
    {
        my $prep = $rs->SQLPrepare(@_);

        return 0
            unless (defined($prep));

        push @{$self->{sql_rs}}, $prep;
    }
    if (defined($args{select_list}))
    {
#        greet $args{select_list};
        $self->{select_list} = $args{select_list};
    }

    $self->{rownum} = 0;
    $self->{use_select_list} = $args{use_select_list};

    if (defined($args{filter}))
    {
        $self->{SQLFilter} = $args{filter}; 
    }

    return 1;
}

sub new
{
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
    }

    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

# SQL-style execute and fetch functions
sub SQLExecute
{
    my $self = shift;

    my $sql_rsl = $self->{sql_rs};
    my $newlist = [];
    for my $rs (@{$sql_rsl})
    {
        my $prep = $rs->SQLExecute(@_);

        return 0
            unless (defined($prep));

        push @{$newlist}, $prep;
    }

    $self->{sql_rs} = $newlist;

    $self->{SQLFetchKey} = $self->{pushhash}->FIRSTKEY();

    return (1);
}


sub SQLFetch
{
    my $self = shift;
    my $rsl = $self->{sql_rs};
    my $is_undef;

    my $fullfilter = $self->{SQLFilter};
    my $filter = (defined($fullfilter)) ? $fullfilter->{filter} : undef;

#    whoami;

    my $tc_rownum = $self->{rownum} + 1;
    my $tc_dict   = $self->{dict};
    my $tc_dbh    = $self->{dbh};
#    my ($tc_rid, $vv) = $rs->SQLFetch(@_);

    my ($rid, $vv);

  L_w1:
    while (defined($self->{SQLFetchKey}))
    {
        my $currkey = $self->{SQLFetchKey};
        my $outarr  = $self->{pushhash}->_localFetch($currkey, "HASH");
        my $get_alias_col = $outarr;

        # save the value of the key because we pre-advance to the next one
        $self->{SQLFetchKey} = $self->{pushhash}->NEXTKEY($currkey);
        
        $rid = $currkey;
        $vv = $outarr;

        greet $rid, $vv;
        
        return undef # check if child has terminated
            unless (defined($rid));

        if (!(defined($vv) && defined($filter)))
        {
            last L_w1;
        }
        else
        {
            # filter is defined
            my $val;

            # be very paranoid - filter might be invalid perl
            eval {$val = &$filter($self, $currkey, $outarr, 
                                  $get_alias_col, $tc_rownum) };
            if ($@)
            {
                whisper "filter blew up: $@";
                greet   $fullfilter;

                my $msg = "bad filter: $@\n" ;
#            $msg .= Dumper($fullfilter)
#               if (defined($fullfilter));
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));

                return undef;
            }
            last L_w1
                unless (!$val);
            # clear out rid and values in case next fetch hits EOF
            $rid = undef;
            $vv  = undef;
        }
    } # end while

    my @big_arr;

    if (defined($vv))
    {
        if ($self->{use_select_list})
        {
            my $outarr = $vv;
            my $get_alias_col = $outarr;

            for my $valex (@{$self->{select_list}})
            {
                unless (defined($valex->{value_expression}))
                {
                    my $msg = "no value expression!";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));
                    return undef;
                }
                if (defined($valex->{value_expression}->{vx}))
                {
                    $is_undef = 0;
                }
                else
                {
                    $is_undef = 1;

                    # NOTE: undefined value expression only legal for
                    # TFN literal
                    unless (exists($valex->{value_expression}->{tfn_literal}))
                    {
                        my $msg = "no value expression vx!";
                        my %earg = (self => $self, msg => $msg,
                                    severity => 'warn');
                        
                        &$GZERR(%earg)
                            if (defined($GZERR));
                        return undef;
                    }
                }
                
                my $vx_val;
                my $v_str;
                $v_str = 
                    '$vx_val = ' . $valex->{value_expression}->{vx} . ';' 
                    unless ($is_undef); 

#                whoami $v_str;

                {
                    my $msg = "";
                    my $status;

                    if ($is_undef)
                    {
                        # just set the vx_val to return an undef
                        $vx_val = undef;
                        $status = 1;
                    }
                    else
                    {
                        $status = eval "$v_str";
                    }

                    unless (defined($status))
                    {
                        # $@ must be non-null if eval failed
                        $msg .= $@ 
                            if $@;
                    }

                    # NOTE: status of undef is ok if no warning message
                    if (defined($status) || !(length($msg)))
                    {
                        push @big_arr, $vx_val;
                    }
                    else
                    {
#        warn $@ if $@;
                        $msg .= "\nbad value expression:\n";
                        $msg .= $valex->{value_expression}->{vx} . "\n";

                        my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
                        
                        &$GZERR(%earg)
                            if (defined($GZERR));
                        
                        greet $outarr;

                        return undef;
                    }
                }
            } # end for all valex

        }
        else
        {
            push @big_arr, @{$vv};
        }
        $self->{rownum} += 1;
    }

#    return ($tc_rid, \@big_arr);
    return ($rid, \@big_arr);

}

sub AUTOLOAD 
{
    my $self = shift;
    my $rs = $self->{sql_rs};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    return ($rs->$newfunc(@_));
}


END {

}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Row::RSJoinA - Row Source Join [A]

=head1 SYNOPSIS

use Genezzo::Row::RSJoinA;

# see Genezzo::GenDBI usage

=head1 DESCRIPTION

RSJoinA is a hierarchical pushhash (see L<Genezzo::PushHash::hph>) class
which performs a cartesian product of multiple rowsources.

=head1 ARGUMENTS

=over 4

=item row source list
(Required) - list of row sources to join

=item dict
(Required) - dictionary object from B<Genezzo::Dict>

=item dbh
(Required) - database handle object from B<Genezzo::GenDBI>

=back

=head1 FUNCTIONS

RSJoinA supports all standard READ-ONLY hph hierarchical pushhash
operations, like FETCH, FIRSTKEY, NEXTKEY, HCOUNT

=head2 EXPORT

=head1 LIMITATIONS

HPUSH, STORE, EXISTS, DELETE, CLEAR are probably broken...

=head1 TODO

=over 4

=item build nested-loop, sort-merge, hash join

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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

