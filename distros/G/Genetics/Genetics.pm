package Genetics;

use 5.006;

$VERSION = '0.03';

1;
__END__

=head1 NAME

Genetics - Perl modules for building genetic analysis applications.

=head1 SYNOPSIS

  C<perl Makefile.PL>
  C<make>
  C<make test>
  C<make install>

=head1 ABSTRACT

The Genetics bundle consists of a collection of OO Perl modules designed to
facilitate the development of Perl scripts and applications in the area of
genetic analysis.  This includes modules encapsulating data related to genetic
analysis (Genetics::Object subclasses) and modules that implement an API for
interacting with these objects (Genetics::API and its derivatives), including
managing their persistence in a relational database (Genetics::API::DB::*).
The classes/objects, API and database are collectively referred to as GenPerl.
The original version of GenPerl was developed in the Research Department of
Genomica Corp. where it was used to produce research protytypes and to manage
and analyze data related to research projects with which Genomica was
involved.

=head1 AUTHOR

Steve Mathias, E<lt>smathias1@qwest.netE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
