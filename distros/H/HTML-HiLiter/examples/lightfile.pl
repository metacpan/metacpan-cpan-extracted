#!/usr/bin/env perl

# A very simple example for highlighting a document from the filesystem.

use strict;
use warnings;
use HTML::HiLiter;

my $usage = "$0 file.html query\n";

# you should do some error checks on $file for security and sanity
my $file = shift or die $usage;

# same with ARGV
if ( !@ARGV ) {
    die $usage;
}
my $query = join( ' ', @ARGV );

my $hiliter = HTML::HiLiter->new(

    #debug => 1, # uncomment for oodles of debugging info
    query => $query,
    tty   => 1,        # assuming you run from a terminal
);

$hiliter->run($file);

exit;

__END__

=pod

=head1 NAME

lightfile.pl -- highlight an HTML file via the filesystem method with HTML::HiLiter

=head1 USAGE

  lightfile.pl <path/to/file.html> <query>

=cut

 ###############################################################################
 #    CrayDoc 4
 #    Copyright (C) 2004 Cray Inc swpubs@cray.com
 #
 #    This program is free software; you can redistribute it and/or modify
 #    it under the terms of the GNU General Public License as published by
 #    the Free Software Foundation; either version 2 of the License, or
 #    (at your option) any later version.
 #
 #    This program is distributed in the hope that it will be useful,
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #    GNU General Public License for more details.
 #
 #    You should have received a copy of the GNU General Public License
 #    along with this program; if not, write to the Free Software
 #    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 ###############################################################################
 
