#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/OO_Examples.pm,v 1.2 2005/08/25 09:15:27 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::OO_Examples;
require Exporter;

use Genezzo::Util;

use strict;
use warnings;

use Carp;

sub new 
{
    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    $self->{dict} = shift @_;
    $self->{count} = 0;

    greet $self->{dict}->{prefs};
    
    return bless $self, $class;

}

sub SysHookInit
{
    goto &new

}


our $Howdy_Hook;
sub Howdy
{
    my $self = shift;
    my $cc = $self->{count};
    $cc++;
    $self->{count} = $cc;
    my $dict = $self->{dict};
    my %args = @_;

    if (exists($args{self}))
    {
        my $self2 = $args{self};
        if (defined($self2) && exists($self2->{GZERR}))
        {
            my $d2 = Data::Dumper->Dump([$dict->{prefs}]);

            $d2 .= "\ncount = $cc\n";

            my $err_cb = $self2->{GZERR};
            &$err_cb(self => $self2, severity => 'info',
                     msg => "Howdy!! $d2");
        }
    }

   # call the callback
    {
        if (defined($Howdy_Hook))
        {
            my $foo = $Howdy_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;
}

our $Ciao_Hook;
sub Ciao
{
    my $self = shift;
    my $cc = $self->{count};
    $cc++;
    $self->{count} = $cc;
    my $dict = $self->{dict};
    my %args = @_;

    if (exists($args{self}))
    {
        my $self2 = $args{self};
        if (defined($self2) && exists($self2->{GZERR}))
        {
            my $d2 = Data::Dumper->Dump([$dict->{prefs}]);

            $d2 .= "\ncount = $cc\n";

            my $err_cb = $self2->{GZERR};
            &$err_cb(self => $self2, severity => 'info',
                     msg => "Ciao!! $d2");
        }
    }

    # call the callback
    {
        if (defined($Ciao_Hook))
        {
            my $foo = $Ciao_Hook;

            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Havok::OO_Examples - some example havok functions

=head1 SYNOPSIS


REM ct sys_hook xid=n pkg=c hook=c replace=c xtype=c xname=c args=c owner=c creationdate=c version=c
REM i havok 3 Genezzo::Havok::SysHook SYSTEM 2005-07-23T22:30:00 0 7.01

REM HAVOK_OO_EXAMPLE
i sys_hook 1 Genezzo::Dict dicthook1 Howdy_Hook oo_require Genezzo::Havok::OO_Examples Howdy SYSTEM 2005-07-23T22:30:00 0
i sys_hook 2 Genezzo::Dict dicthook1 Ciao_Hook  oo_require Genezzo::Havok::OO_Examples Ciao SYSTEM 2005-07-23T22:30:00 0

commit
shutdown
startup


=head1 DESCRIPTION

Havok test module 

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  Howdy, Ciao

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


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
