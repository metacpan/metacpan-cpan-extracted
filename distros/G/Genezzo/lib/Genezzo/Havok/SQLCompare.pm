#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/SQLCompare.pm,v 1.2 2006/11/17 07:52:56 claude Exp claude $
#
# copyright (c) 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::SQLCompare;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&sql_func_compare_function
             );

use Genezzo::Util;

use strict;
use warnings;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    my $pak1  = __PACKAGE__;
    $MAKEDEPS = {
        'NAME'     => $pak1,
        'ABSTRACT' => ' ',
        'AUTHOR'   => 'Jeffrey I Cohen (jcohen@cpan.org)',
        'LICENSE'  => 'gpl',
        'VERSION'  =>  $VERSION,
        }; # end makedeps

    $MAKEDEPS->{'PREREQ_HAVOK'} = {
        'Genezzo::Havok::UserFunctions' => '0.0',
    };

    # DML is an array, not a hash

    my $now = 
    do { my @r = (q$Date: 2006/11/17 07:52:56 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };


    my %tabdefs = ();
    $MAKEDEPS->{'TABLEDEFS'} = \%tabdefs;

    my @sql_funcs = qw(
                        compare_function
                       );

    my @ins1;
    my $ccnt = 1;
    for my $pfunc (@sql_funcs)
    {
        my %attr = (module => $pak1, 
                    function => "sql_func_" . $pfunc,
                    creationdate => $now);

        my @attr_list;
        while ( my ($kk, $vv) = each (%attr))
        {
            push @attr_list, '\'' . $kk . '=' . $vv . '\'';
        }

        my $bigstr = "select add_user_function(" . join(", ", @attr_list) .
            ") from dual";
        push @ins1, $bigstr;
        $ccnt++;
    }


    # if check returns 0 rows then proceed with install
    $MAKEDEPS->{'DML'} = [
                          { check => [
                                      "select * from user_functions where xname = \'$pak1\'"
                                      ],
                            install => \@ins1
                            }
                          ];

#    print Data::Dumper->Dump([$MAKEDEPS]);
}

sub MakeYML
{
    use Genezzo::Havok;

    my $makedp = $MAKEDEPS;

    return Genezzo::Havok::MakeYML($makedp);
}

sub sql_compare_in
{
    my $not   = shift;
    my $first = shift;

    return undef
        unless (defined($first));

    my @args = @_;

    if ($not)
    {
        my $stat = 1;

        for my $a1 (@args)
        {
            # return undef if any value is undef (NULL)
            return undef
                unless (defined($a1));

            # need to wait until have checked all values for undef
            $stat = 0
                if ($a1 eq $first);
        }
        return $stat;

    }
    else
    {
        for my $a1 (@args)
        {
            next
                unless (defined($a1));

            return 1
                if ($a1 eq $first);
        }
    }
    return 0;
}

sub sql_compare_like
{
    my ($not, $first, $pattern, $escape) = @_;

    return undef
        unless (defined($first) && defined($pattern));

    $pattern = '^' . quotemeta($pattern) . '$';

    my $wildcard = '.*';
    my $singlechar = '.';

    if (defined($escape))
    {
        return undef
            unless (length($escape) > 0);

        $escape = quotemeta($escape);

        # zero width negative look behind -- match any occurence of
        # "%" wildcard which does not follow the escape character (and
        # similarly for "_")
        $pattern =~ s/(?<!$escape)\\%/$wildcard/gm;
        $pattern =~ s/(?<!$escape)_/$singlechar/gm;

        # replace the "escaped" match expressions with their literal
        # values
        $pattern =~ s/(($escape)\\%)/\\%/gm;
        $pattern =~ s/(($escape)_)/_/gm;
    }
    else
    {
        $pattern =~ s/\\%/$wildcard/gm;
        $pattern =~ s/_/$singlechar/gm;
    }

    return ($first !~ m/$pattern/)
        if ($not);

    return ($first =~ m/$pattern/);

}

sub sql_func_compare_function
{
    my $not = shift;
    my $fn_name = shift;

    my $stat;

    if ($fn_name =~ /^in$/i)
    {
        $stat = sql_compare_in($not, @_);
    }
    if ($fn_name =~ /^like$/i)
    {
        $stat = sql_compare_like($not, @_);
    }
    return undef
        unless (defined($stat));

    return $stat;
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Havok::SQLCompare - SQL comparison functions

=head1 SYNOPSIS

HavokUse("Genezzo::Havok::SQLCompare")

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 SQL functions

=over 4

=item  IN

  WHERE value IN (list)

Returns TRUE if the value is present in the list, else FALSE.  NOT IN
is slightly different: returns NULL if any list item is NULL, return
FALSE if the value matches any list item, else returns TRUE.


=item  LIKE

  WHERE value LIKE (pattern)

  WHERE value LIKE (pattern, escape_char)

Returns TRUE if the value matches the pattern.  In the pattern, a 
'%' (percent sign) matches zero or more characters, and an 
'_' (underscore) matches exactly one character.  These characters can
be matched as literals if they are preceded by the optional escape
character.


=back


=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS

IN has list support, but no IN subquery support.

LIKE has a "functional" syntax, instead of the standard 
'LIKE pattern [ESCAPE escape_char]'.


=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2006 Jeffrey I Cohen.  All rights reserved.

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
