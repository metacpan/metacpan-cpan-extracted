#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSDual.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Row::RSDual;

use Genezzo::Util;
use Genezzo::PushHash::PushHash;
use Genezzo::PushHash::PHArray;
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
#                      rs => "no rowsource!"
                      );
    
    my %args = (@_);

    return 0
        unless (Validate(\%args, \%required));

#    $self->{rs} = $args{rs};

    my %one_row;

    $self->{rs} = tie %one_row, 'Genezzo::PushHash::PHArray';
    $self->{rs}->HPush("a");

    if (defined($args{select_list}))
    {
#        greet $args{select_list};
        $self->{select_list} = $args{select_list};
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

# HPush public method (not part of standard hash)
sub HPush
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

#    return ($rs->HPush(@_));
    return undef;
}

sub HCount
{
    my $self = shift;
    my $rs = $self->{rs};

    whoami;

    return ($rs->HCount(@_));
}

# standard hash methods follow
sub STORE
{
    my $self = shift;
    my $rs = $self->{rs};

    whoami;

#    return ($rs->STORE(@_));
    return undef;
}
 
sub FETCH 
{
    my $self = shift;
    my $rs = $self->{rs};

    whoami;

    return ($rs->FETCH(@_));
}
sub FIRSTKEY 
{
    my $self = shift;
    my $rs = $self->{rs};

    whoami;

    return ($rs->FIRSTKEY(@_));
}
sub NEXTKEY  
{
    my $self = shift;
    my $rs = $self->{rs};

    whoami;

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

#    return ($rs->DELETE(@_));
    return undef;
}
sub CLEAR    
{
    my $self = shift;
    my $rs = $self->{rs};

#    whoami;

#    return ($rs->CLEAR(@_));
    return undef;
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
    $args{pushhash} = $self;
    $args{rs}       = $self->{rs};

    if ((exists($self->{GZERR}))
        && (defined($self->{GZERR})))
    {
        $args{GZERR} = $self->{GZERR};
    }

    my $sth = Genezzo::Row::SQL_RSDual->new(%args);

    return $sth;
}

package Genezzo::Row::SQL_RSDual;
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

    return 0
        unless (defined($args{rs}));
    my $rs = $args{rs};

    if (defined($args{select_list}))
    {
#        greet $args{select_list};
        $self->{select_list} = $args{select_list};
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

# SQL-style execute and fetch functions
sub SQLExecute
{
    my ($self, $filter) = @_;

    $self->{SQLFetchKey} = $self->{pushhash}->FIRSTKEY();

    greet $self;

    return (1);
}


sub SQLFetch
{
    my $self = shift;

    whoami ;

    while (defined($self->{SQLFetchKey}))
    {
        my $currkey = $self->{SQLFetchKey};
        my $outarr  = $self->{pushhash}->FETCH($currkey);

        # save the value of the key because we pre-advance to the next one
        $self->{SQLFetchKey} = $self->{pushhash}->NEXTKEY($currkey);
        greet $currkey, 
        $self->{SQLFetchKey};

        $self->{rownum} += 1;
        # Note: always return the rid
        return ($currkey, $outarr);
    }
    return undef;
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


if (0)
{
    my %foo;
    my $tv = tie %foo, 'Genezzo::Row::RSDual';
    
    my $sth = $tv->SQLPrepare();
#greet $sth;
    greet $sth->SQLExecute();
    my @foo = $sth->SQLFetch();
#greet @foo;
    
    while (scalar(@foo) > 1)
    {
        print join(" ", @foo), "\n";
        @foo = $sth->SQLFetch();
    }
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Row::RSDual - Row Source Dual (single row) table

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

Copyright (c) 2005 Jeffrey I Cohen.  All rights reserved.

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

