#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSExpr.pm,v 7.4 2006/10/26 07:24:28 claude Exp claude $
#
# copyright (c) 2005, 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Row::RSExpr;

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
    #greet @_;
    my $self      =  shift;

    my %required  =  (
                      rs => "no rowsource!",
                      dict => "no dictionary!",
                      magic_dbh => "no dbh!"
                      );
    
    my %args = (@_);

    return 0
        unless (Validate(\%args, \%required));

    $self->{rs}   = $args{rs};
    $self->{dict} = $args{dict};
    $self->{dbh}  = $args{magic_dbh};

    if (defined($args{select_list}))
    {
#        greet $args{select_list};
        $self->{select_list} = $args{select_list};
        return 0
            unless (defined($args{alias}));
        $self->{alias} = $args{alias};
    }
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
    my $rs = $self->{rs};

#    whoami;

    return ($rs->HPush(@_));
}

sub HCount
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->HCount(@_));
}

# standard hash methods follow
sub STORE
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->STORE(@_));
}
 
sub FETCH 
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->FETCH(@_));
}
sub FIRSTKEY 
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->FIRSTKEY(@_));
}
sub NEXTKEY  
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->NEXTKEY(@_));
}
sub EXISTS   
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->EXISTS(@_));
}
sub DELETE   
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->DELETE(@_));
}
sub CLEAR    
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

    return ($rs->CLEAR(@_));
}

sub AUTOLOAD 
{
    my $self = shift;
    my $rs = $self->{rs};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    return ($rs->$newfunc(@_));
}

sub SQLPrepare # get a DBI-style statement handle
{
    my $self = shift;
    my %args = @_;
    $args{pushhash}  = $self;
    $args{rs}        = $self->{rs}; 
    $args{dict}      = $self->{dict};
    $args{magic_dbh} = $self->{dbh};

    if (defined($self->{select_list}))
    {
        $args{select_list} = $self->{select_list};
        $args{alias}       = $self->{alias};
    }
    $args{use_select_list} = defined($self->SelectList());

    if ((exists($self->{GZERR}))
        && (defined($self->{GZERR})))
    {
        $args{GZERR} = $self->{GZERR};
    }

    my $sth = Genezzo::Row::SQL_RSExpr->new(%args);

    return $sth;
}

package Genezzo::Row::SQL_RSExpr;
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
        unless (defined($args{rs}));
    my $rs = $args{rs};

    my %nargs = @_;

    $self->{sql_rs}   = $rs->SQLPrepare(%nargs);
    return 0
        unless (defined($self->{sql_rs}));

    if (defined($args{select_list}))
    {
#        greet $args{select_list};
        $self->{select_list} = $args{select_list};
        return 0
            unless (defined($args{alias}));
        $self->{alias} = $args{alias};
    }

    $self->{rownum} = 0;
    $self->{use_select_list} = $args{use_select_list};

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

# XXX XXX: where is SQLExecute? part of the autoload...

sub SQLFetch
{
    my $self = shift;
    my $rs = $self->{sql_rs};
    my $is_undef;

#    whoami;

    my $tc_rownum = $self->{rownum} + 1;
    my $tc_dict   = $self->{dict};
    my $tc_dbh    = $self->{dbh};

#    my ($tc_rid, $vv) = $rs->SQLFetch(@_);
    my ($rid, $vv) = $rs->SQLFetch(@_);
    greet $rid, $vv;

    return undef # check if child has terminated
        unless (defined($rid));

    my @big_arr;

    if (defined($vv))
    {
        if ($self->{use_select_list})
        {
            my $outarr = $vv;
            my $alias = $self->{alias};
            my $get_alias_col = {$alias => $outarr};

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

Genezzo::Row::RSExpr - Row Source Expression Evaluation

=head1 SYNOPSIS

use Genezzo::Row::RSExpr;

# see Genezzo::GenDBI usage

=head1 DESCRIPTION

RSExpr is a hierarchical pushhash (see L<Genezzo::PushHash::hph>) class
which evaluates and B<projects> a set of expressions for each input row.
The input rows are produced by RSTab (see L<Genezzo::Row::RSTab>).

=head1 ARGUMENTS

=over 4

=item row source 
(Required) - an input row source 

=item dict
(Required) - dictionary object from B<Genezzo::Dict>

=item dbh
(Required) - database handle object from B<Genezzo::GenDBI>

=item select list
(Optional) - a list of output expressions that is applied as a
transform on the input row

=back

=head1 FUNCTIONS

RSExpr support all standard hph hierarchical pushhash operations.

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item SQLPrepare/SQLFetch: requires ALIAS argument, which doesn't make sense for rowsources like RSDual (see XEval).  "Alias" is only necessary to disambiguate named columns.

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

