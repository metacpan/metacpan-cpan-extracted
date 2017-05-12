#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/RCS/Genezzo.pm,v 1.13 2007/11/20 08:28:28 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo;

require 5.005_62;
use strict;
use warnings;

require Exporter;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use F2 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

BEGIN {
    use Exporter   ();

    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    @ISA         = qw(Exporter);
    %EXPORT_TAGS = ( 'all' => [ qw(
                                   $VERSION 
                                   ) ] 
                     );

    @EXPORT_OK = qw( @{ $EXPORT_TAGS{'all'} } );

    @EXPORT = qw( );
	
}

our $VERSION   = '0.72';

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo - an extensible database with SQL and DBI

=head1 SYNOPSIS

  # partial DBI interface
  use Genezzo::GenDBI; 

  # Users can directly create and manipulate database tables using 
  # gendba.pl, an interactive line-mode tool.

=head1 DESCRIPTION

  The Genezzo modules implement a hierarchy of persistent hashes using
  a fixed amount of memory and disk.  This system is designed to be
  easily configured and extended with custom functions, persistent
  storage representations, and novel data access methods.  In its
  current incarnation it supports a subset of SQL and a partial
  DBI interface.



=head1 GETTING STARTED

  The simplest way to create an instance of a Genezzo database is to use:

    gendba.pl -init

  This command will create a new database and login to the
  command-line.  Typing "help" on the command line will list the 
  available commands.  Additional help for gendba.pl is available via 
  "gendba.pl -help".





=head2 EXPORT

 VERSION

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>, C<gendba.pl -man>,
C<perldoc DBI>, L<http://dbi.perl.org/>

Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.

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
