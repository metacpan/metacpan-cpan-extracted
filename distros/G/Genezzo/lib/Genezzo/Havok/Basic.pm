#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/Basic.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::Basic;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&perlish_substitution);

use Genezzo::Util;

use strict;
use warnings;
use warnings::register;
use Carp;

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

    carp $args{msg}
        if warnings::enabled();
    
};

sub max
{
    my $msg = 'function "max" not implemented';
    my %earg = (#self => $self,
                severity => 'warn',
                msg => $msg);

    &$GZERR(%earg)
        if (defined($GZERR));
                
    return undef;
}

sub perlish_substitution
{
    greet @_;

    my $str1 = shift; #
    my $fnd1 = shift; #
    my $repl = shift; #
    my $mods = shift; #
    my $got_it; #
  # eval ?

#    $str1 =~ s/a/b/;
    
#    return $str1;
    
    if (defined($mods))
    { 
        eval "\$got_it = (\$str1 =~ s/$fnd1/$repl/$mods)"; #
    }
    else
    { 
        eval "\$got_it = (\$str1 =~ s/$fnd1/$repl/)"; #
    }   
    return $str1; #
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Havok::Basic - some basic functions

=head1 SYNOPSIS

=head1 DESCRIPTION

Havok test module 

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  perlish_substitution

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
