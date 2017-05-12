#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/Examples.pm,v 7.5 2006/05/21 06:41:01 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::Examples;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&isRedGreen);

use Genezzo::Util;

use strict;
use warnings;

use Carp;

# select * from mytable where Genezzo::Havok::Examples::isRedGreen(col1)
# select * from mytable where isRedGreen(col1)

# Example for UserExtend function: test if a string matches 
# the regexp "red or green"
sub isRedGreen
{
    return undef
        unless scalar(@_);

    return ($_[0] =~ m/^(red|green)$/i);
}

# Example for SysHook function
our $Howdy_Hook;
sub Howdy
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            &$err_cb(self => $self, severity => 'info',
                     msg => "Howdy!!");
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
    my %args = @_;

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            &$err_cb(self => $self, severity => 'info',
                     msg => "Ciao!!");
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


# For GSysHook testing: register this function on the
# BCFILE::_init_filewriteblock hook and use the RDBlock methods to
# update a block before it is written to disk.  This function performs
# a search and replace of all strings in all rows in the block which
# match "__MAGIC_BLOCK_NUM__".  A more practical hook might involve
# updating transaction information using _set_meta_row.
sub magic_writeblock
{
    my ($self, $fname, $fnum, $fh, $bnum, $refbuf, $hdrsize, $bce) = @_;

    return 1 
        unless (defined($bce));

    whoami;

    if (1) 
    {
        my $foo = $bce->GetContrib();
        
        return 1
            unless (defined($foo));

        if (exists($foo->{mailbox})
            && exists($foo->{mailbox}->{'Genezzo::Block::RDBlock'}))
        {
            my $rdblock = $foo->{mailbox}->{'Genezzo::Block::RDBlock'};
            
            my $kk = $rdblock->FIRSTKEY();

            # update all the rows in a block and replace the string
            # __MAGIC_BLOCK_NUM__ with the actual block number before
            # writing to disk

            while (defined($kk))
            {
                my $vv = $rdblock->FETCH($kk);
                if (defined($vv))
                {
                    my @row = UnPackRow($vv, 
                                        $Genezzo::Util::UNPACK_TEMPL_ARR); 
                    
                    my $got_one;

                    $got_one = 0;

                    my @foo = @row;
                    for my $ii (0..(scalar(@row)-1))
                    {
                        if ($foo[$ii] =~ m/__MAGIC_BLOCK_NUM__/)
                        {
                            $row[$ii] =~ s/__MAGIC_BLOCK_NUM__/$bnum/g;
                            $got_one = 1;
                        }
                    }
                    if ($got_one)
                    {
                        $rdblock->STORE($kk, PackRow(\@row));
                    }
                }
                
                $kk = $rdblock->NEXTKEY($kk);
            }

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

Genezzo::Havok::Examples - some example havok functions

=head1 SYNOPSIS

=head1 DESCRIPTION

Havok test module 

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  isRedGreen - test if argument is red or green

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
