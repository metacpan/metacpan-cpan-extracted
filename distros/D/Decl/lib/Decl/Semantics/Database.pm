package Decl::Semantics::Database;

use warnings;
use strict;

use base qw(Decl::Node);
use Text::ParseWords;
use Iterator::Simple qw(:all);
use Carp;
use DBI;

=head1 NAME

Decl::Semantics::Database - implements a database handle.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

62% of all Perl code deals with databases.  (I just made that up.)  This is because L<DBI> is a work of beauty.  But seriously, every time
I go to use DBI I have to cut and paste from existing code, because I I<just can't remember all the handles>.  This module is a first stab
at presenting databases the way I see them in my mind.

So.  There are two ways to hit databases, essentially.  The first is the query: given a database out there somewhere, I want to extract
data from it.  The data is going to be delivered in an iterator, and in 90% of cases I'm just going to loop over the rows returned and do
something really simple with it.

I abstract that out like this (and forgive the Windows/Microsoftiness of it; that's just what I'm doing today):

   database (msaccess) "mydatabase.mdb"
      query need_invoicing "SELECT [jobs to invoice].customer as customer, Sum([jobs to invoice].value) AS total_value FROM [jobs to invoice] GROUP BY [jobs to invoice].customer ORDER BY [jobs to invoice].customer"
   
   do {
      ^foreach need_invoicing {
         print "$customer\t$total_value\n";
      }
   }
   
Alternatively, if you don't like the long line there (neither do I), I could have specified the query as:

   database (msaccess) "mydatabase.mdb"
      query need_invoicing
         select "[jobs to invoice].customer as customer, Sum([jobs to invoice].value) AS total_value"
         from   "jobs to invoice"
         group  "customer"
         order  "total_value desc"

This sets up all the handles for me and even builds the loop code, and I don't have the chance to screw it up.  Mission accomplished.

More generally, I can set up a query that can take (optional) parameters, and at some point I can also do discovery of the existing
database upon connection.  And of course I can also set up non-query queries like insert, update, and delete SQL, add tables, and so on,
but I'm really not worried about that right at the moment; I just want to be able to grab data from a database.

The second major case for database interaction is object storage.  The way I see this is equally simple: I add an object, and get a key.
Given the key, I can then retrieve, update, or delete the object at a later date.  Objects are going to end up being nodes (duh), and yes,
you read this correctly that this model will cover NoSQL databases just fine.

=head1 DRIVERS

There is just no way around a driver system for databases.  We're lucky to have DBI and its driver system for most work, but sometimes there
will be a database that we'll want to do a little more with (MS Access being a case in point).

If this is the case, that driver can be a separate module Decl::Semantics::Database::<driver>.  This uses the Perl module
system to provide as much flexibility in system configuration as possible without being too nasty.

Right now, I'm going to special-case some stuff for Access and CSV because I need those and don't want to mess with the directory structure
today.

=head2 SPECIAL SUBTAGS

The only meaningful child right now is "query", which will macro-insert a data tag (i.e. an iterator) as a sibling of the database.  When
the database node is built, it thus creates a data source for each query defined that can be referred to in code downstream of the database.

I can imagine other subtags later, perhaps "table" for database management, and certainly something for the NoSQL-like model, whatever that
turns out to look like.  But those will come when the need arises.

=head1 FUNCTIONS DEFINED

=head2 defines(), tags_defined()

=cut
sub defines { ('database'); }
sub tags_defined { Decl->new_data(<<EOF); }
database (body=vanilla)
EOF

=head2 build_payload

We connect to the database for our payload.  The payload itself will be our dbi handle (the one normally called C<$dbh>).

=cut
sub build_payload {
   my ($self) = @_;
   
   # Figure out what DBI driver to use and how to handle any special-case parameters.  Note that CSV and Access are here.
   my $dbi = '';
   
   my $specials = {RaiseError => 1};
   
   if (lc($self->parameter_n(1)) eq 'csv') {
      $dbi = 'dbi:CSV:';
      $self->{database_type} = 'csv';
      $specials->{f_dir} = $self->label;
      # f_ -> schema (complex), dir, ext, lock, encoding
      # csv_ -> eol, sep_char, quote_char, escape_char, class, null, tables (complex)
   } elsif (lc($self->parameter_n(1)) eq 'msaccess') {
      my $l = $self->label;
      $self->{database_type} = 'msaccess';
      $l =~ s/\\/\\\\/g;
      #$l =~ s/\//\\/g;
      $dbi = 'dbi:ODBC:driver=microsoft access driver (*.mdb);dbq=' . $l;
   } elsif (lc($self->parameter_n(1)) eq 'sqlite') {
      $dbi = 'dbi:SQLite:' . $self->label;
      $self->{database_type} = 'sqlite';
   } else {
      # We just assume vanilla DBI otherwise, nothing special.
      if ($self->parameter_n(1)) {
         $dbi = "DBI:" . $self->parameter_n(1) . ':' . $self->label;
         $self->{database_type} = lc($self->parameter_n(1));
      } else {
         $self->{database_type} = $self->label;
         $self->{database_type} =~ s/:.*$//;
         $dbi = 'DBI:' . $self->label;
      }
   }
   
   $self->{payload} = DBI->connect ($dbi, undef, undef, $specials) or croak $DBI::errstr;
}


=head1 DATABASE-SPECIFIC FUNCTIONS

=head2 dbh

An alias to the payload (the database handle) if you want to use conventional DBI techniques:

   my $dbh = ^('database')->dbh;
   $dbh->tables or whatever
   
=cut

sub dbh { $_[0]->payload }

=head2 dbtype

Returns the type of database.

=cut
sub dbtype { $_[0]->{database_type} }

=head2 table_info

Returns information about the given table.  How the table is specified depends on the database type - if the database driver has
multiple sets of tables, the "main" one will be used.  If you need the actual DBI table_info functionality, get a handle with dbh first.

=cut

sub table_info {
   my ($self, $table) = @_;
   
   my $sth = $self->dbh->table_info(undef, "main", $table, undef);
   my $data = $sth->fetchrow_hashref;
   return $data;
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Semantics::Database
