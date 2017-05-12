package Decl::Semantics::Table;

use warnings;
use strict;

use base qw(Decl::Node);
use Text::ParseWords;
use Iterator::Simple qw(:all);
use Carp;
use DBI;

=head1 NAME

Decl::Semantics::Table - implements a table in a database.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

When working with databases, it is always true that we make certain assumptions about its structure (what tables it has, what fields they have).
The C<table> tag is how we define what in a table we intend to use, and how we expect it to be formatted.  When developing a system from scratch, the
C<table> tag can even create the table directly, and if we continue to give it authoritative status, it can also modify the existing tables to meet
the specifications of the script.  It does so by generating SQL CREATE and ALTER TABLE statements and running them against its database.

A set of tables can also be told to generate a full SQL schema without talking to the database directly.  This is the default if no database handle
is defined.

The semantics of the C<table> tag, as you'll not be surprised to hear, correspond closely to SQL semantics.  There are just a few differences, and as usual,
you don't have to use them if you don't want to, but I find them useful.  Note that at the moment, these semantics are a subset of full SQL - don't expect to do your
DBA work through the C<table> tag.  The point of this exercise right now is to provide more of a quick sketch tool that generates simple SQL that can be refined as
needed; my own SQL work is pretty superficial, so to do a better job, I'll eventually have to put a lot more work into refining the semantics of database management.

=head2 Basic types

Each column in a table has a type.  I'm arbitrarily calling these types int, float, char, text, bool, and date (the last being a timestamp).
You can, of course, use anything else you want as a type, and the C<table> tag will assume it's SQL and pass it through, for better or worse; this
allows you to use anything specifically defined for your own database.

A field specification in the C<table> tag is backwards from SQL - the type comes first.  I'm really not doing this to mess with your head; tags are better
suited for expression of type, so this matches C::Decl semantics better.  If you really hate it, use the C<sql> subtag - this passes whatever it sees through as SQL
without trying to get cute at all.  It doesn't even try to parse it, actually, except to strip out the first word as the field name.  So this will work fine:

   table mytable
      sql key integer not null
      sql field varchar(200) not null default 'George'
      
This is your best bet when you start to offload checks to the database instead of just hacking something together.

As always with Decl, the idea is to make it easy to slap something together while making it possible to be careful later.  Nowhere is this
attitude more evident than here in my glossing over the vast and troubled territory that is SQL.  Did you know the 'S' is for 'standard'?  Have you ever seen a more
ironic acronym?

One more "basic" type: a C<key> is always an integer that autoincrements.  You can have a character key by saying e.g. C<char myfield (key)>; a character key is simply
declared PRIMARY KEY.

=head2 Structural types

To represent relationships between tables, I'm using C<ref <tablename>> (defines a field named after the table with the same type as the table's key),
C<ref field <tablename>> (in case you want to name it something else; maybe you have two such fields, for example), and "list".  The list actually defines
a subtable, and there are two variants: C<list <tablename>>/C<list field <tablename>> (defines an n-to-n relationship to the other table by means of an
anonymous linking table), and a multilined variant:

   list <field>
      int field1
      int field2
      
This actually creates an new table called <table>_<field> and gives it those two fields, plus the key of the master table.

All of this makes it simpler and quicker to set up a normalized database and build queries against it that can be called from code.

=head2 Data dictionary

The data dictionary is a quick and easy way to define new "types" - a title may be standardized throughout your database as a char (100), for example.  So:

  data-dictionary
     char title (100)
     
Now we can use the title as a field type anywhere:

   table
      title
      
or

   table
      title
      title subtitle
      
If a field is not named, the type name will also be used as the default field name.  (This seems pretty reasonable.)

=head1 FUTURE POSSIBILITIES

=head2 Variant SQL data dictionaries

The tags used in the data dictionary are C<always standard SQL>, whatever that might mean for your own database.  C<If you need to work with multiple databases>
then you can define database-specific data dictionaries like this:

   data-dictionary (msaccess)
      char title (100)
      
and so on.  If you leave one data dictionary unadorned with a database type, then it will serve as the default for any fields that don't have to be defined
differently between the different databases.  I wrestled with this setup, but I think it's the cleanest way to represent these things - plus it gives the added
benefit that if you move from database A to database B, you can simply take your data dictionary and work down the list deciding which datatypes correspond to
what in the new regime, then use the new data dictionary with no other format changes.

How often will this come up, though?  No idea.  I just worry, that's all.

At any rate, you can think of the special definitions for generic datatypes defined by this code as a default data dictionary.  Any of those types may be overridden.
Clear?  Of course it is.

=head2 More refined DBA facilities

Defining indices would be nice, wouldn't it?

=head2 Building a spec based on existing SQL table definitions

This would be useful for introspection as well.

=head1 FUNCTIONS DEFINED

=head2 defines(), tags_defined()

=cut
sub defines { ('table', 'data-dictionary'); }
sub tags_defined { Decl->new_data(<<EOF); }
table (body=vanilla)
data-dictionary (body=vanilla)
EOF

=head2 build_payload, build_table, build_ddict

We connect to the default database - unless we are actually in a database object, or given a specific database by name.

We first write SQL to define the table, and query the database to see what structure it thinks that table has (if it has that table), and of
course, we do the same for any subtables.  If there's a mismatch, we generate SQL to alter the table(s).

If we have authority, we then execute any SQL already generated.  There should probably be some kind of workflow step to allow this authority to
be delegated or deferred, but man, that's a can of worms that can be opened another day.

The C<table> tag thus doesn't actually I<have> a payload per se.

=cut
sub build_payload {
   my $self = shift;
   $self->{dictionary} = $self->find_context('data-dictionary');
   foreach ($self->nodes) {
      $_->build if $_->can('build');
   }

   return $self->build_table(@_) if $self->is('table');
   $self->build_ddict(@_);
}

sub build_table {
   my $self = shift;
   
   $self->{tables} = [];
   $self->{table_data} = {};
   push @{$self->{tables}}, $self->name;
   foreach my $l ($self->nodes()) {
      if ($l->is('query')) {
         # Not handling at the moment
      } else {
         # Anything else is either a list/link or a field.
         my ($fname, $def) = $self->sql_single_field($self->name, $l);
         $self->{key} = $fname if ($def->{key}) and not $self->{key};
      }
      if (not $self->{key}) {
         $self->{key} = $self->default_key($self->name);
      }
   }
   
   my $database = $self->find_context('database');
   my $dbtype = '';
   $dbtype = $database->{database_type} if defined $database;
   my $db = undef;
   $db = $database if defined $database and $database->parameter('tables') eq 'active';
   
   $self->{sql} = join ("\n", map { $self->sql_single_table($_, $dbtype, $db) } @{$self->{tables}});
}
   
   
   
   
=head2 Helper functions sql_single_table() and sql_single_field

These functions just spin out some SQL based on our data structures.

=cut
sub sql_single_table {
   my ($self, $table, $dbtype, $db) = @_;
   
   my $table_info;
   
   if (defined $db) {
      $table_info = $db->table_info($table);
   }
   
   my @fields = map {
      my $fd = $self->{table_data}->{$table}->{fielddata}->{$_};
      "$_ " . $fd->{type} . ($fd->{size} eq '' ? '' : ' (' . $fd->{size} . ")")
   } @{$self->{table_data}->{$table}->{fields}};
   
   my $sql = "create table $table (\n   " .
              join (",\n   ", @fields) .
             "\n);\n";
             
   if (defined $db and not defined $table_info) {
      print "Creating table $table\n";
      $db->dbh->do($sql);
   }
             
   return $sql;
}

sub sql_single_field {
   my ($self, $table, $field) = @_;
   if ($field->is('list')) {
      if ($field->nodes) {
         # Subtable.
         my $tname = $field->name || 'list';
         my $subtable = $table . '_' . $tname;
         push @{$self->{tables}}, $subtable;
         my $key = $self->get_table_key($table);
         my $keydef = $self->get_table_field($table, $key);
         my $def = {
            type => $keydef->{type},
            size => $keydef->{size},
            key  => 0,
         };
         my $parent_key = 'ref_' . $key;
         $self->add_field($subtable, $parent_key, $def);
         $self->{tabledata}->{$subtable}->{parent_key} = $parent_key;
         foreach ($field->nodes) {
            $self->sql_single_field($subtable, $_);
         }
      } else {
         my @names = $field->names;
         my $tname;
         if (@names == 0) {
            # error
            next;
         } elsif (@names == 1) {
            $tname = $names[0];
         } else {
            $tname = $names[1];
         }
         push @{$self->{tables}}, $table . '_link_' . $tname;
      }
   } else {
      my $fname = $field->name || $field->tag;
      my $type = $field->tag;
      my $size = $field->parameter_n(0) || '';
      my $key  = $field->is('key') || $field->parameter('key') || 0;
      if ($size eq 'key') {
         $size = $field->parameter_n(1) || '';
         $key = 1;
      }
      if (defined $self->{dictionary}) {
         my $dict = $self->{dictionary}->dictionary_lookup($type);
         if (defined $dict) {
            $type = $dict->{type};
            $size = $dict->{size} unless $size;
            $key  = $dict->{key}  unless $key;
         }
      }
      my $def = {
         type => $type,
         size => $size,
         key  => $key,
      };
      $self->add_field($table, $fname, $def);
      return ($fname, $def);
   }
}

sub build_ddict {
   my $self = shift;
   $self->{tables} = ['dictionary'];
   $self->{table_data}->{dictionary}->{fields} = [];
   $self->{table_data}->{dictionary}->{fielddata} = {};
   foreach my $l ($self->nodes()) {
      $self->sql_single_field('dictionary', $l);
   }
}

=head2 dictionary_lookup

This is called by a table on its dictionary to see if the dictionary knows about a given field.  If the dictionary doesn't know, and if there
is a higher-level data dictionary, then it gets called, and so on.

=cut

sub dictionary_lookup {
   my ($self, $field) = @_;
   my $possible = $self->{table_data}->{dictionary}->{fielddata}->{$field};
   return $possible if defined $possible;
   if (defined $self->{dictionary}) {
      return $self->{dictionary}->dictionary_lookup($field);
   }
   return;
}

=head2 default_key, add_default_key, get_table_key, get_table_field, add_field

Table access functions.

=cut
   
sub default_key {
   my ($self, $table) = @_;
   $table . '_id';
}
sub add_default_key {
   my ($self, $table) = @_;
   my $key = $self->default_key($table);
   unshift @{$self->{table_data}->{$table}->{fields}}, $key;
   $self->{table_data}->{$table}->{fielddata}->{$key} = {
      type => 'int',
      size => 'size',
      key  => 1
   };
   return $key;
}
sub get_table_key {
   my ($self, $table) = @_;
   foreach (@{$self->{table_data}->{$table}->{fields}}) {
      return $_ if $self->{table_data}->{$table}->{fielddata}->{$_}->{key};
   }
   $self->add_default_key($table);
}
sub get_table_field {
   my ($self, $table, $field) = @_;
   $self->{table_data}->{$table}->{fielddata}->{$field};
}

sub add_field {
   my ($self, $table, $field, $def) = @_;
   push @{$self->{table_data}->{$table}->{fields}}, $field;
   $self->{table_data}->{$table}->{fielddata}->{$field} = $def;
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

1; # End of Decl::Semantics::Table
