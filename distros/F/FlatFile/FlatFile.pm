#!/usr/bin/perl
#
# Home filesystems are listed in @HOMEDEVS
# Minimal values are listed in @NO_QUOTA
#
# $ID: $
# $Author: mjd $
#

package FlatFile;
use Tie::File;
$VERSION = "0.11";
use strict;
use Carp 'croak';

=head1 NAME

FlatFile - Manipulate flat-file databases

=head1 SYNOPSIS

  # Usage pattern A:  direct use
  use FlatFile;

  my $password = FlatFile->new(FILE => $filename, 
                   FIELDS => [qw(username password uid gid gecos home shell)],
                   MODE => "+<",  # "<" for read-only access
                   RECSEP => "\n", FIELDSEP => ":");

  my ($mjd) = $file->lookup(username => "mjd");
  print "mjd: ", $mjd->uid, "\n";

  # Look up all records for which function returns true
  sub is_chen { $_{gecos} =~ /\bChen$/ }
  my @chens = $file->c_lookup(\&is_chen);
  for (@chens) { $_->set_shell("/bin/false") }

  $mjd->delete;  # delete MJD from file

  $password->flush;  # write out changes to file

  # Usage pattern B:  subclass
  #  PasswordFile.pm:
  package PasswordFile;
  use base FlatFile;
  our @ISA = 'FlatFile';
  our @FIELDS = qw(username password uid gid gecos home shell);
  our $RECSEP = "\n";
  our $FIELDSEP = ":";
  our $MODE = "<";
  our $FILE = "/etc/passwd";

  # Main program uses subclass:
  package main;
  use PasswordFile;
  my $password = PasswordFile->new;

  ... the rest as above ...

=head1 DESCRIPTION

C<FlatFile> is a class for manipulating flat-file (plain text)
databases.  One first opens the database, obtaining a database object.
Queries may be perfomed on the database object, yielding record
objects, which can be queried to retrieve information from the
database.  If the database is writable, the objects can be updated,
and the updates written back to the file.

Subclasses of this module can be created to represent specific files,
such as the Unix password file or the Account Management C<db.list> file.

=cut

my %default_default = 
  (FILE => undef,
   TMPFILE => "",               # overwritten later
   MODE => "<",
   FIELDS => undef,
   RECSEP => "\n",
   FIELDSEP => qr/\s+/,
   FIELDSEPSTR => " ",
   RECBASECLASS => "FlatFile::Rec",
   RECCLASS => "", # Will be overwritten in ->new method
   DEFAULTS => {},
  );

sub _classvars {
  my $class = shift;
  return {} if $class eq __PACKAGE__;
  my %cv;
  for my $k (keys %default_default) {
    my $val = do { no strict 'refs'; $ {"$class\::$k"} };
    $cv{$k} = $val if defined $val;
  }
  \%cv;
}

=head1 Methods

=head2 C<< $db = FlatFile->new(FILE => $filename, FIELDS => [...], ...); >>

The C<new> method opens the database.  At least two arguments are
required: the C<FILE> argument that gives the path at which the data
can be accessed, and the C<FIELDS> argument that names the fields, in
order.

By default, the file will be opened for reading only.  To override
this, supply a C<MODE> argument whose value is a mode string like the
one given as the second argument to the Perl built-in C<open>
function.  For read-write access, you should probably use C<< MODE => "+<" >>.  As of version 0.10, only C<< < >>, C<< +< >>, and C<< +> >> are supported.

The file will be assumed to contain "records" that are divided into
"fields".  By default, records are assumed to be terminated with a
newline character; to override this, use C<< RECSEP => $separator >>.
Fields are assumed to be separated by whitespace; to override, use
C<< FIELDSEP => $pattern >>.  C<$pattern> may be a compiled regex
object or a literal string.  If it is a pattern, you must also supply
an example string with C<<FIELDSEPSTR>> that will be used when writing
out records.  For example, for the Unix password file, whose fields
are separated by colons, use:

        FIELDSEP => ":"

but for a file whose fields are separated by one or more space
characters, use:

        FIELDSEP => qr/ +/,  FIELDSEPSTR => "  "

The C<FIELDSEPSTR> argument tells the module to use two spaces between
fields when writing out new records.

You may supply a 

	DEFAULTS => { field => default_value, ... }

argument that specifies default values for some or all of the fields.  Fields for which no default value 

When changes are written to the disk, the module first copies the
modified data to a temporary file, then atomically replaces the old
file with the temporary file.  To specify a temporary filename, use
C<< TMPFILE => $filename >>.  Otherwise, it will default to the name
of the main file with C<".tmp"> appended.

Record objects will be allocated in dynamically generated classes
named C<FlatFile::Rec::A>,
C<FlatFile::Rec::B>, and so on, which inherit from common
base class C<FlatFile::Rec>.  To override this choice of
class, supply a class name with C<< RECCLASS => $classname >>.  You
may want your custom class to inherit from
C<FlatFile::Rec>.

=cut

my $classid = "A";
sub new {
  my ($class, %opts) = @_;
  my $self = {recno => 0};

  bless $self => $class;

  # acquire object properties from argument list (%opts)
  # or from class defaults or default defaults, as appropriate.
  # _default will detect missing required values
  # and unknown key names
  for my $source (\%opts, $class->_classvars) {
    $self->_acquire_settings($source, check_keys => 1);
  }

  # TODO: TESTS for this logic
  if (exists $self->{FIELDSEP}) {
    if (ref $self->{FIELDSEP}) {
      defined($self->{FIELDSEPSTR})
        or croak "FIELDSEPSTR required in conjunction with FIELDSEP";
    } else {
      # literal string; compile it to a pattern
      my $str = $self->{FIELDSEP};
      $self->{FIELDSEPSTR} = $str;
      $self->{FIELDSEP} = "\Q$str";
    }
  }

  $self->_acquire_settings(\%default_default, mandatory => 1);

  $self->{RECCLASS} = join "::", $self->{RECBASECLASS}, $classid++
    unless $self->{RECCLASS};

  $self->{TMPFILE} = $self->{FILE} . ".tmp"
    unless exists $opts{TMPFILE};

  $self->_calculate_field_offsets;

  $self->_generate_record_class;


  return $self->_open_file ? $self : ();
}

sub _acquire_settings {
  my ($self, $settings, %opt)  = @_;
  for my $k (keys %$settings) {
    if ($opt{check_keys} && not exists $default_default{$k}) {
      croak "unknown key '$k'";
    }
    if (! exists $self->{$k} && exists $settings->{$k}) {
      if ($opt{mandatory} && not defined $settings->{$k}) {
        croak "Required key '$k' unspecified";        
      }
      $self->{$k} = $settings->{$k};
    }
  }
}

use Fcntl qw(O_RDONLY O_RDWR O_TRUNC);
my %MODE_OK = ('<', O_RDONLY, '+<', O_RDWR,
               '+>', O_RDWR|O_TRUNC);
sub _mode_flags {
  my $self = shift;
  $MODE_OK{$self->{MODE}};
}

sub _writable {
  my $self = shift;
  $self->{MODE} ne "<";  # "<" is the only read-only mode
}

sub _open_file {
  my $self = shift;
  my $file = $self->{FILE};
  my $mode = $self->{MODE};
  my $flags = $self->_mode_flags();
  defined $flags or croak "Invalid mode '$mode'";

  tie my(@file), "Tie::File", $file, mode => $flags,
    recsep => $self->{RECSEP}, autochomp => 1,
      or return;
  $self->{file} = \@file;
  return 1;
}


sub _calculate_field_offsets {
  my $self = shift;
  my @f = @{$self->{FIELDS}};
  my %off;
  for my $i (0 .. $#f) {
    if (exists $off{$f[$i]}) {
      croak "duplicate field name '$f[$i]'";
    } else {
      $off{$f[$i]} = $i;
    }
  }
  $self->{OFF} = \%off;
  return 1;
}

sub _generate_record_class {
  my ($self) = shift;
  my $classname = $self->{RECCLASS};

  # create 'get' methods
  for my $field (@{$self->{FIELDS}}) {
    my $ff = $field;
    my $code =  sub {
                   return $_[0]{data}{$ff};
                 };
    no strict 'refs';
    *{"$classname\::$field"}     = $code;
    *{"$classname\::get_$field"} = $code;
  }

  # create 'set' methods
  if ($self->_writable) {
    for my $field (@{$self->{FIELDS}}) {
      my $ff = $field;
      my $code = sub {
                     my ($rec, $val) = @_;
                     $rec->{data}{$ff} = $val;
                     $rec->db->_update($rec);
                   };
      no strict 'refs';
      *{"$classname\::set_$field"} = $code;
    }
  }

  no strict 'refs';
  @{"$classname\::ISA"} = ($self->{RECBASECLASS});
  *{"$classname\::FIELD"} = $self->{OFF};    # create %FIELD hash
  *{"$classname\::FIELD"} = $self->{FIELDS}; # create @FIELD hash
  *{"$classname\::DEFAULT"} = $self->{DEFAULTS}; # create %DEFAULT hash
  return 1;
}

=head2 C<< $db->lookup($field, $value) >>

Returns an array of all records in the database for which the field
C<$field> contains the value C<$value>.   For information about record
objects, see L<"Record objects"> below.

Field contents are always compared stringwise.  For numeric or other
comparisons, use C<c_lookup> instead.

The behavior in scalar context is undefined.

=cut

# Locate records for which field $f contains value $v
# return all such
# TODO: iterator interface?
sub lookup {
  my ($self, $f, $v) = @_;

  # If called as a class method, try to instantiate the database
  # for the duration of a single query
  # Note that since we don't give the new call the required FILE and FIELD
  # arguments, this will only work if $self is actually the name of a subclass
  # in which those things are predefined
  $self = $self->new if not ref $self; 

  my @result;
  $self->rewind or croak "Couldn't rewind handle";
  while (my $rec = $self->nextrec) {
    if ($rec->$f eq $v) {
      return $rec unless wantarray();
      push @result, $rec;
    }
  }
  return @result;
}

=head2 C<< $db->c_lookup($predicate) >>

Returns an array of all records in the database for which the
predicate function C<$predicate> returns true.  For information about
record objects, see L<"Record objects"> below.

The predicate function will be called repeatedly, once for each record
in the database.

Each record will be passed to the predicate function as a hash, with
field names as the hash keys and record data as the hash values.  The
global variable C<%_> will also be initialized to contain the current
record hash.  For example, if C<$db> is the Unix password file, then
we can search for people named "Chen" like this:

        sub is_chen {
          my %data = @_;
          $data{gecos} =~ /\bChen$/;
        }

        @chens = $db->c_lookup(\&is_chen);

Or, using the C<%_> variable, like this:

        sub is_chen { $_{gecos} =~ /\bChen$/ }       

        @chens = $db->c_lookup(\&is_chen);

The behavior in scalar context is undefined.

=cut

# return all records for which some callback yields true
sub c_lookup {
  my ($self, $cb) = @_;
  my @result;

  # If called as a class method, try to instantiate the database
  # for the duration of a single query
  # Note that since we don't give the new call the required FILE and FIELD
  # arguments, this will only work if $self is actually the name of a subclass
  # in which those things are predefined
  $self = $self->new if not ref $self; 

  $self->rewind or croak "Couldn't rewind handle";
  while (my $rec = $self->nextrec) {
    local %_ = $rec->as_hash;
    push @result, $rec  if $cb->(%_);
  }
  return @result;
}

sub rewind {
  my $self = shift;
  $self->{recno} = 0;
  return 1;
}

=head2 C<< $db->rec_count >>

Return a count of the number of records in the database.

=cut

sub rec_count {
  my $self = shift;

  return scalar(@{$self->{file}});
}

sub save_position {
  my $self = shift;
  FlatFile::Position->new(\($self->{recno}));
}

=head2 C<< my $record = $db->nextrec >>

Get the next record from the database and return a record object
representing it.  Each call to C<nextrec> returns a different record.
Returns an undefined value when there are no more records left.

For information about record objects, see L<"Record objects"> below.

To rewind the database so that C<nextrec> will start at the beginning,
use the C<rewind> method.

The following code will scan all the records in the database:

        $db->rewind;
        while (my $rec = $db->nextrec) {
          ... do something with $rec...
        }

=cut



sub nextrec {
  my $self = shift;
  my $recno = $self->{recno};

  $recno++ while $self->{DELETE}{$recno};

  # Someone may have done an in-memory update of the record
  # we just read.  If so, discard the disk data and
  # return the in-memory version of the record instead.
  return $self->{UPDATE}{$recno}
    if exists $self->{UPDATE}{$recno};

  # if it wasn't updated, the continue processing
  # with the disk data
  my $line = $self->{file}[$recno];
  return unless defined $line;
  my @data = split $self->{FIELDSEP}, $line, -1;
  $self->{recno} = $recno+1;
  return $self->make_rec($recno, @data);
}

sub make_rec {
  my ($self, $recno, @data) = @_;
  return $self->{RECCLASS}->new($self, $recno, @data);
}

=head2 C<< $db->append(@data) >>

Create a new record and add it to the database.  New records may not be
written out until the C<< ->flush >> method is called.  The new
records will be added at the end of the file.

C<@data> is a complete set of data values for the new record, in the
appropriate order.  It is a fatal error to pass too many or too few
values.

=cut


# TODO: fail unless ->_writable
sub append {
  my ($self, @data) = @_;
  my $pos = $self->save_position;
  push @{$self->{file}}, $self->make_rec(0, @data)->as_string or return;
  return 1;
}

sub _update {
  my ($self, $new_rec) = @_;
  my $id = $new_rec->id;
  return if $self->{DELETE}{$id};
  $self->{UPDATE}{$id} = $new_rec->as_string;
}

=head2 C<< $db->delete_rec($record) >>

Delete a record from the database.  C<$record> should be a record
object, returned from a previous call to C<lookup>, C<nextrec>, or
some similar function.  The record will be removed from the disk file
when the C<flush> method is called.

Returns true on success, false on failure.

=cut

sub delete_rec {
  my ($self, $rec) = @_;
  my $id = $rec->id;
  delete $self->{UPDATE}{$id};
  $self->{DELETE}{$id} = 1;
}

=head2 C<< $db->flush >>

Adding new records, deleting and modifying old records is performed
in-memory only until C<flush> is called.  At this point, the program
will copy the original data file, making all requested modifications,
and then atomically replace the original file with the new copy.

Returns true on success, false if the update was not performed.

C<flush> is also called automatically when the program exits.

=cut

# Old behavior was lost:
### copy input file, writing out updated records
### then atomically replace input file with updated copy
# Fix this XXX
sub flush {
  my $self = shift;

  # Quick return if there's nothing to do
  return unless $self->_writable;
  return if keys %{$self->{UPDATE}} == 0
    && keys %{$self->{DELETE}} == 0;

  my $f = tied(@{$self->{file}});
  $f->defer;

  for my $k (keys %{$self->{UPDATE}}) {
    $self->{file}[$k] = $self->{UPDATE}{$k};
  }
  for my $k (sort {$b <=> $a} keys %{$self->{DELETE}}) {
    splice @{$self->{file}}, $k, 1;
  }

  %{$self->{UPDATE}} = %{$self->{DELETE}} = ();
  $f->flush;
  return 1;
}

sub DESTROY {
  my $self = shift;
  $self->flush('DESTROY');
}

sub field_separator_string { $_[0]->{FIELDSEPSTR} }
sub record_separator { $_[0]{RECSEP} }

=head2 C<< $db->has_field($fieldname) >>

Returns true if the database contains a field with the specified name.

=cut

sub has_field {
  my ($self, $field) = @_;
  exists $self->{OFF}{$field};
}

=head1 Record objects

Certain methods return "record objects", each of which represents a
single record.  The data can be accessed and the database can be
modified by operating on these record objects.

Each object supports a series of accessor methods that are named after
the fields in the database.  If the database contains a field "color",
for example, record objects resulting from queries on that database
will support a C<get_color> method to retrieve the color value from a
record, and a synonymous <color> method that does the exact same
thing. If the database was opened for writing, the record objects will
also support a C<set_color> method to modify the color in a record.
The effects of the C<set_*> methods will be propagated to the file
when the database is flushed.

Other methods follow.

=cut

package FlatFile::Rec;
use Carp 'croak';

sub default {
  my $self = shift;
  my $class = ref($self) || $self;
  my $field = shift;
  no strict 'refs';
  my $d = \%{"$class\::DEFAULT"};
  return wantarray ? (exists $d->{$field}, $d->{$field}) : $d->{$field};
}

=head2 C<< $record->fields >>

Returns a list of the fields in the object, in order.

=cut

sub fields {
  my $self = shift;
  my $class = ref($self) || $self;
  no strict 'refs';
  return @{"$class\::FIELD"};
}

sub new {
  my ($class, $db, $id, @data) = @_;
  my $self = {};
  my %data;

  my @f = $class->fields;
  @data{@f} = @data;

  # set default values in data hash
  for my $f (@f) {
    if (not defined $data{$f}) {
      my ($has_default, $default_value) = $class->default($f);
      if ($has_default) {
        $data{$f} = $default_value;
      } else {
        my $msg = "required field '$f' missing from record";
        $msg .= " $id" if $id;
        croak $msg;
      }
    }
  }

  $self->{data} = \%data;
  $self->{db} = $db;
  $self->{id} = $id;
  bless $self => $class;
}

=head2 C<< $record->db >>

Returns the database object from which the record was originally selected.
This example shows how one might modify a record and then write the
change to disk, even if the original database object was unavailable:

        $employee->set_salary(1.06 * $employee->salary);
        $employee->db->flush;

=cut

sub db {
  $_[0]{db};
}

sub id {
  $_[0]{id};
}

=head2 C<< %hash = $record->as_hash >>

Returns a hash containing all the data in the record.  The keys in the
hash are the field names, and the corresponding values are the record
data.

=cut

sub as_hash {
  my $self = shift;
  return %{$self->{data}};
}

=head2 C<< @data = $record->as_array >>

Return the record data values only.

=cut

sub as_array {
  my $self = shift;
  my @f = $self->fields;
  return @{$self->{data}}{@f};
}

=head2 C<< $line = $record->as_string >>

Return the record data in the same form that it appeared in the
original file.  For example, if the record were selected from the Unix
password file, this might return the string 
C<"root:x:0:0:Porpoise Super-User:/:/sbin/sh">.

=cut

sub as_string {
  my $self = shift;
  my $fsep = $self->db->field_separator_string;
  my $rsep = $self->db->record_separator;
  my @data = $self->as_array;
  return join($fsep, @data) . $rsep;
}

=head2 C<< $line = $record->delete >>

Delete this record from its associated database.  It will be removed
from the disk file the next time the database object is flushed.

=cut

# delete this record from its database
sub delete {
  my $self = shift;
  $self->db->delete_rec($self);
}

package FlatFile::Position;

sub new {
  my ($class, $record_number_ref) = @_;
  my $recno = $$record_number_ref;
  my $self = sub {
    $$record_number_ref = $recno;
  };
  bless $self => $class;
}

sub DESTROY {
  my $self = shift;
  $self->();
}

=head1 BUGS

Various design defects; see TODO file

This module is ALPHA-LEVEL software.  Everything about it, including
the interface, might change in future versions.

=head1 AUTHOR

Mark Jason Dominus (mjd@plover.com)

  $Id: FlatFile.pm,v 1.4 2006/07/09 06:53:37 mjd Exp $
  $Revision: 1.4 $

=cut

1;

