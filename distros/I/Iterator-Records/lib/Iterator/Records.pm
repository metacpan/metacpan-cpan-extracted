package Iterator::Records;

use 5.006;
use strict;
use warnings;
use Carp;
use Iterator::Simple;
use Data::Dumper;

=head1 NAME

Iterator::Records - a simple iterator for arrayref record sources

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Iterator::Records uses L<Iterator::Simple> to work with iterators whose values are arrayrefs of named fields. These can be called I<record streams>.
A record stream can be seen as the same thing as a DBI retrieval, but without most of the machinery for DBI - and of course, a DBI query is one of the ways you
can build a record stream.

The actual API of Iterator::Records isn't as simple or elegant as L<Iterator::Simple>, simply because there's more to keep track of. But the basic
approach is similar: an Iterator::Records object defines how to iterate something, then you use the iter() method to create an iterator from it.
The result is an Iterator::Simple iterator known to return records, i.e. arrayrefs of fields that match the field list specified.

Note that the Iterator::Records object is an iterator *factory*, and the actual iterator itself is returned by the call to iter().

  use Iterator::Records;
  
  my $spec = Iterator::Records->new (<something iterable>, ['field 1', 'field 2']);
  
  my $iterator = $spec->iter();
  while (my $row = $iterator->()) {
     my ($field1, $field2) = @$row;
  }
  
  $iterator = $spec->iter_hash();
  while (my $row = $iterator->()) {
     print $row->{field 1};
  }
  
  my ($f1, $f2);
  $iterator = $spec->iter_bind(\$f1, \$f2);
  while ($iterator->()) {
     print "$f1 - $f2\n";
  }

Note that the iterator itself is just an L<Iterator::Simple> iterator. Now hold on, though, because here's where things get interesting.

  my $recsource = Iterator::Records->new (sub { ... }, ['field 1', 'field 2']);
  my $iterator = $recsource->select ("field 1")->iter;
  while (my $row = $iterator->()) {
     my ($field1) = @$row;
  }
  
  my @fields = $recsource->fields();
  my $fields = $recsource->fields(); # Returns an arrayref in scalar context.
  
  $rs = $recsource->where (sub { ... }, "field 1", "field 2");
  $rs = $recsource->fixup ("field 1", sub { ... } );
  $rs = $recsource->calc  ("field 3", sub { ... } );
  $rs = $rs->select ("field 2", "field 3", "field 1");
  $rs = $rs->select (["field 2", "field 3", "field 1"]);
  
  $rs = $recsource->transform (["where", ["field 1", "=", "x"]],
                               ["fixup", ["field 1, sub { ... }]]);


Since Iterator::Records is essentially a more generalized way of iterating DBI results, there are a few wrappers to make things easy.

  my $dbh = Iterator::Records::db->connect(--DBI syntax--);
  my $dbh = Iterator::Records::db->open('sqlite file');
  my $dbh = Iterator::Records::db->open(); # Defaults to an in-memory SQLite database
  
This is not the direct DBI handle; it's got simplified syntax as follows:

  my $value = $dbh->get ('select value from table where id=?', $id);  # Single value retrieval in one whack.
  $dbh->do ("insert ...");  # Regular insertion, just like in DBI, except simpler.
  my $record = $dbh->insert ("insert ..."); # Calls last_insert_id ('', '', '', ''), which will likely fail except with SQLite.

And then you have the actual iterator machinery.

  my $iter = $dbh->iterator ('select * from table')->iter();
  my $sth = $dbh->prepare (--DBI syntax--);
  my $iter = $sth->iter ($value1, $value2);
  while ($iter->()) {
     my ($field1, $field2) = @$_;
  }
  
We can load an iterator into a table. If you have Data::Tab installed, it will make a Data::Tab with the column names from this iterator.
Otherwise, it will simply return an arrayref of arrayrefs by calling Iterator::Simple's "list" method.

  my $data = $recsource->table;
  
The "report" method returns an Iterator::Simple that applies an sprintf to each value in the record source. If you supply a list of fields to dedupe it will replace them with ""
if their value is the same as the previous row. This is useful for tabulated data where, for instance, the date may be the same from line to line and if so should only be
displayed once.

  my $report = $recsource->report ("%-20s %s", ["field 1"]); # Here, field 2 would not be deduped.
  my $report = join ('\n', $recsource->report (...)->list);

=cut

use Iterator::Records;

=head1 BASIC ITERATION

=head2 new (iterable, arrayref of fields)

To specify an Iterator::Records from scratch, just take whatever iterable thing you have, and specify a list of fields in the resulting records.
If the iterable is anything but a coderef, Iterator::Records->iter will simply pass it straight to Iterator::Simple for iteration. If it's a coderef,
it will be called, and its return value will be passed to Iterator::Simple. This allows record streams to be reused.

As an added bonus of this extra level of indirection, you can call "iter" with parameters that will be passed on to the coderef. This turns the
Iterator::Records object into a parameterizable iterator factory.

=cut

sub new {
   my ($class, $iterable, $fields) = @_;
   my $self = bless ({}, $class);
   croak "Iterator spec not iterable" unless Iterator::Simple::is_iterable($iterable);
   $self->{gen} = $iterable;
   $self->{f} = $fields;
   $self->{id} = '*';
   $self;
}

sub fields { $_[0]->{f}; }
sub id {
   my $self = shift;
   if (scalar @_) {
      $self->{id} = shift;
   }
   $self->{id};
}

=head2 iter, iter_hash, iter_bind

Basic iteration of the record source returns an arrayref for each record. Alternatively, an iterator can be created which returns a hashref for each
record, with the field names keying the return values in each record. This is less efficient, but it's often handy. The third option is to bind a list
of scalar references that will be written automagically on each retrieval. The return value in this case is still the original arrayref record.

=cut

sub iter {
  my $self = shift;
  if (ref $self->{gen} eq 'CODE') {
     return Iterator::Simple::iter($self->{gen}->(@_));
  } else {
     return Iterator::Simple::iter($self->{gen});
  }
}
sub iter_hash {
   my $self = shift;
   my $iter = $self->iter();
   Iterator::Simple::Iterator->new(sub {
       if (my $rec = $iter->()) {
          my $ret = {};
          my $i = 0;
          foreach my $f (@{$self->{f}}) {
             $ret->{$f} = $rec->[$i++];
          }
          return $ret;
       } else {
          return undef;
       }
   });
}
sub iter_bind {
   my $self = shift;
   my $iter = $self->iter();
   my @fields = (@_);
   Iterator::Simple::Iterator->new(sub {
       if (my $rec = $iter->()) {
          my $i = 0;
          foreach my $f (@fields) {
             $$f = $rec->[$i++];
          }
          return $rec;
       } else {
          return undef;
       }
   });
}

=head1 TRANSMOGRIFIERS

Since our record stream sources are very often provided by fairly simple drivers (like the filesystem walker in File::Org), it's not at all unusual to find ourselves
in a position where we want to modify them on the fly, either filtering out some of the records or modifying the records as they go through. There are four different
"transmogrifiers" for record streams: where, select, calc, and fixup. The "where" transmogrifier discards records that don't match a particular pattern; "select"
removes columns; "calc" adds a column that is calculated by an arbitrary coderef provided; and "fixup" applies a coderef to the record to modify individual field
values.

Each transmogrifier takes an iterator I<specification>, not an iterator - and returns a new specification that can be iterated. The source stream will then be iterated
internally.

=head2 where (sub { ... }, 'field 1', 'field 2')

Filtration of records is not really any different from igrep - given a record stream, we provide a coderef that tells us to include or not to include. If fields
are specified, their values for the record to be examined will be passed to the coderef as its parameters; otherwise the entire record is provided as an arrayref
and the coderef can extract values on its own. The list of fields is not affected.

=head2 select ('field 1', 'field 3')

Returns a spec for a new iterator that includes only the fields listed, in the order listed.

=head2 calc ('new field', sub { ... }, 'field 1', 'field 2')

Returns a spec for a new iterator that includes a new field calculated by the coderef provided; as for "where", if fields are listed they will be passed into the
coderef as parameters, but otherwise the entire record will be passed in. The new field will appear at the end of the current field list.

=head2 fixup (sub { ... })

Returns a spec for a new iterator in which each record is first visited by the coderef provided. This is just an imap in more record-based form. The field
list is unchanged.

=head2 dedupe ('field 1', 'field 2')

Keeps track of the last values for field 1 and field 2; if the new value is a duplicate, passes an empty string through instead. Useful for reporting.
The field list is unchanged.

=head2 rename ('field 1', 'new name', [more pairs])

To rename a field (or more than one), use 'rename'. The record is not changed.

=head2 transmogrify (['where', ...], ['calc', ...])

Any sequence of transmogrifiers can be chained together in a single step using the L<transmogrify> method.

=cut

sub _find_offsets {
   my $field_list = shift;
   my $size = scalar @{$field_list}-1;
   my @output;
   foreach my $f (@_) {
      my ($index) = grep { $field_list->[$_] eq $f } (0 .. $size);
      croak "Unknown field '$f' used in transmogrifier" unless defined $index;
      push @output, $index;
   }
   @output;
}

sub where {
   my $self = shift;
   $self->transmogrify (['where', @_]);
}

sub _where {
   my $fields = shift;
   my $tester = shift;
   my @field_offsets = _find_offsets ($fields, @_);
   my $parms = "";
   $parms = '$rec->[' . join ('], $rec->[', @field_offsets) . ']' if scalar @field_offsets;
   
   my $sub = <<"EOF";
      sub {
         my \$rec = shift;
         return \$rec if \$tester->($parms);
         return undef;
      }
EOF
   #print STDERR $sub;
   eval $sub;
}

sub select {
   my $self = shift;
   $self->transmogrify (['select', @_]);
}
sub _select_fields {
   shift;
   \@_;
}
sub _select {
   my $fields = shift;
   my @field_offsets = _find_offsets ($fields, @_);
   my $parms = "";
   $parms = '$rec->[' . join ('], $rec->[', @field_offsets) . ']' if scalar @field_offsets;
   
   my $sub = <<"EOF";
      sub {
         my \$rec = shift;
         return [$parms];
      }
EOF
   #print STDERR $sub;
   eval $sub;
}

sub calc {
   my $self = shift;
   $self->transmogrify (['calc', @_]);
}
sub _calc_fields {
   my @fields = @{$_[0]};
   push @fields, $_[2];
   \@fields;
}
sub _calc {
   my $fields = shift;
   my $calcer = shift;
   shift; # The name of our output variable
   my @field_offsets = _find_offsets ($fields, @_);
   my $parms = "";
   $parms = '$rec->[' . join ('], $rec->[', @field_offsets) . ']' if scalar @field_offsets;
   
   my $sub = <<"EOF";
      sub {
         my \$rec = shift;
         return [@\$rec, \$calcer->($parms)];
      }
EOF
   #print STDERR $sub;
   eval $sub;
}

sub fixup {
   my $self = shift;
   $self->transmogrify (['fixup', @_]);
}
sub _fixup {
   my $fields = shift;
   my $calcer = shift;
   my @field_offsets = _find_offsets ($fields, @_);
   my $output = '$rec->[' . shift(@field_offsets) . ']';
   my $parms = "";
   $parms = '$rec->[' . join ('], $rec->[', @field_offsets) . ']' if scalar @field_offsets;
   
   my $sub = <<"EOF";
      sub {
         my \$rec = shift;
         \$rec = [@\$rec];
         $output = \$calcer->($parms);
         return \$rec;
      }
EOF
   #print STDERR $sub;
   eval $sub;
}

sub dedupe {
   my $self = shift;
   $self->transmogrify (['dedupe', @_]);
}
sub _dedupe {
   my $fields = shift;
   my ($target) = _find_offsets ($fields, $_[0]);

   my $value = '$rec->[' . $target . ']';
   
   my $last_value = ''; # Closures are magic.

   my $sub = <<"EOF";
      sub {
         my \$rec = shift;
         my \$val = $value;
         if (\$val eq \$last_value) {
            \$rec = [@\$rec];
            $value = '';
         } else {
            \$last_value = \$val;
         }
         return \$rec;
      }
EOF
   #print STDERR $sub;
   eval $sub;
}

sub _gethashval_fields {
   my $fields = shift;
   shift; # skip the name of the value bag.
   my @fields = (@$fields, @_);
   \@fields;
}

sub _gethashval {
   my $fields = shift;
   my ($fieldno) = Iterator::Records::_find_offsets ($fields, shift);
   my $vals = "\$rec->[$fieldno]->{"  . join ("}, \$rec->[$fieldno]->{", @_) . '}';
   
   my $sub = <<"EOF";
      sub {
         my \$rec = shift;
         return [@\$rec, $vals ];
      }
EOF
   #print STDERR $sub;
   eval $sub;
}

sub _count {
   my $fields = shift;
   shift; # The name of our output variable
   my $count = shift;
   $count = 0 unless defined $count;
   $count -= 1;
   sub {
      my $rec = shift;
      $count += 1;
      [@$rec, $count];
   }
}

sub _limit {
   my $fields = shift;
   my $limit = shift;
   my $count = 0;
   sub {
      return undef unless $count < $limit;
      $count += 1;
      shift();
   }
}

# The walker framework is *really* minimalistic. It basically looks exactly like _calc, but instead of returning just the parent record (to which, unlike calc, it can add fields),
# it can return a list of records and/or iterators to take the place of the parent record - which can include the parent record, so it's effectively an add-or-replace.
sub _walk_fields {
   my $fields = shift;
   shift; # skip the walker coderef
   my $newfields = shift;
   if (defined $newfields) {
      return [@$newfields, @$fields];
   }
   $fields;
}
sub _walk {
   my $fields = shift;
   my $walker_factory = shift;
   my $newfields = shift; # The (optional) arrayref of fields we're going to add
   my @field_offsets = _find_offsets ($fields, @_);

   # The walker framework is unusual in that, instead of building a closure here, we are actually given a closure *factory* that will make it for us.
   # This factory is given the fields for the input record, the new fields expected for the output record, the list of fields it's supposed to use,
   # and the offsets of those fields in the input record.
   # It returns a closure that takes the input record and returns a list of records and/or new iterators that ->transmogrify will buffer and return as appropriate.
   $walker_factory->($fields, $newfields, \@_, \@field_offsets);
}

sub rename {
   my $self = shift;
   $self->transmogrify (['rename', @_]);
}
sub _rename_fields {
   my $fields = shift;
   my @fields = @$fields;
   while (scalar @_) {
      my $from = shift;
      my $to = shift;
      last unless defined $to;
      @fields = map { $_ eq $from ? $to : $_ } @fields;
   }
   \@fields;
}
sub _no_change {
   sub { $_[0] }; # passes the record through as efficiently as possible
}

our $transmogrifiers = {
  'where'  => [undef, \&_where],
  'select' => [\&_select_fields, \&_select],
  'calc'   => [\&_calc_fields,   \&_calc],
  'fixup'  => [undef, \&_fixup],
  'dedupe' => [undef, \&_dedupe],
  'rename' => [\&_rename_fields, \&_no_change],
  'gethashval' => [\&_gethashval_fields, \&_gethashval],
  'count'  => [\&_calc_fields, \&_count],
  'limit'  => [undef, \&_limit],
  'walk'   => [\&_walk_fields, \&_walk],
};
sub _find_transmogrifier { $_[0]->_find_core_transmogrifier ($_[1]); } # This is where you want to look up specialty transmogrifiers in subclasses.
sub _find_core_transmogrifier {
   croak "Unknown transmogrifier '" . $_[1] . "'" unless exists $transmogrifiers->{$_[1]};
   @{$transmogrifiers->{$_[1]}};
}

sub transmogrify {
   my $self = shift;
   
   my $fieldlist = $self->fields();
   
   # Convert the list of transmogrifier specs into a list of coderefs, and calculate the field list at each step.
   my @tlist = ();
   foreach my $t (@_) {
      my ($transmog, @parms) = @$t;
      my ($fielder, $coder) = $self->_find_transmogrifier ($transmog);
      $coder->($fieldlist, @parms); # Run through one build just to check our input fields for correctness
      push @tlist, [$coder, $fieldlist, [@parms]]; # Then save our builders so we can call them afresh on each iteration.
      $fieldlist = $fielder->($fieldlist, @parms) if defined $fielder;
      #print STDERR "field list is now " . Dumper($fieldlist);
   }

   my $sub = sub {
      my $in = $self->iter(@_); # Parameters are passed through to source iterator.

      my @buffer = ();
      my $buffer_which;
      my $subiterator;
      
      my @reified_tlist = ();
      foreach my $t (@tlist) {
         my ($coder, $fieldlist, $parms) = @$t;
         push @reified_tlist, $coder->($fieldlist, @$parms);
      }
      #my @reified_tlist = map { $_->() } @tlist;
     
      sub {
         SKIP:
         my $rec = undef;
         my $walked = 0; # Is this record one that came from a walker?
         if (defined $subiterator) {
            $rec = $subiterator->();
            if (not defined $rec) {
               $subiterator = undef;
            } else {
               $walked = 1;
            }
         }
         
         if (not defined $rec) {
            if (scalar @buffer) {
               $rec = shift @buffer;
               if (ref $rec ne 'ARRAY') {
                  $subiterator = $rec->iter();
                  goto SKIP;
               }
               $walked = 1;
            } else {
               $rec = $in->();
            }
         }
         return undef unless defined $rec;
         
         my $which_t = 0;
         foreach my $t (@reified_tlist) {
            $which_t += 1;
            next if ($walked and $which_t <= $buffer_which); # Skip the transmogrifiers that ran before the stage of this walk-originated record
            my @things = $t->($rec);
            goto SKIP unless defined $things[0]; # This is the shortcut used for "where" functionality.
            if (ref ($things[0]) eq 'ARRAY') {
               $rec = shift @things;
               if (@things) {
                  push @buffer, @things;
                  $buffer_which = $which_t; # Tacit requirement: only one walker per transmogrifier list, with bad error otherwise
               }
            } else {
               push @buffer, @things;
               $buffer_which = $which_t;
               goto SKIP;
            }
         }
         $rec;
      }
   };
   
   my $class = ref($self);
   $class->new ($sub, $fieldlist); # 2019-02-23 - use class of source, not "Iterator::Records"
}

=head1 LOADING AND REPORTING

These are some handy utilities for dealing with record streams.

=head2 load ([limit]), load_parms(parms...), load_lparms(limit, parms...), load_iter(iterator, [limit])

The I<load> function simply loads the stream into an arrayref of arrayrefs. If I<limit> is specified, at most that many rows will be loaded; otherwise,
the iterator runs as long as it has data.

Note that this is called directly on the definition of the stream, not on the resulting iterator. Consequently, I<load> can't be used to "page" through
an existing record stream - if you want to do that, you should look at L<Data::Tab>, which was written specifically to support the buffered reading of
record streams and manipulation of the resulting buffers.

This form of C<load> can't be used on iterator factories that take parameters. If you have a factory that requires parameters, use C<load_parms>. Finally,
to use both a limit and parameters, use C<load_lparms>.

All of these are just sugar for the core method C<load_iter>, which, given a started iterator and an optional limit, loads it.

=cut

sub load_iter {
   my ($self, $i, $limit) = @_;
   
   my @returns = ();
   my $row;
   while (((not defined $limit) or (defined $limit and $limit > 0)) and $row = $i->()) {
      $limit = $limit - 1 if defined $limit;
      push @returns, [@$row];
   }
   \@returns;
}

sub load {
   my ($self, $limit) = @_;
   $self->load_iter($self->iter(), $limit);
}
sub load_parms {
   my $self = shift;
   $self->load_iter($self->iter(@_));
}
sub load_lparms {
   my $self = shift;
   my $limit = shift;
   $self->load_iter($self->iter(@_), $limit);
}

=head2 report (format, [dedupe list])

The I<report> method is another retrieval method; that is, it returns an iterator when called. However, this iterator is not a record stream; instead,
it is a string iterator. Each record in the defined stream is passed through sprintf with the format provided. For convenience, if a list of columns
is provided, performs a dedupe transmogrification on the incoming records before formatting them.

=cut

sub report {
   my $self = shift;
   my $format = shift;
   if (scalar @_) {
      my $self = $self->dedupe (@_);
   }
   my $iter = $self->iter();
   Iterator::Simple::Iterator->new(sub {
      if (my $rec = $iter->()) {
         return sprintf ($format, @$rec);
      } else {
         return undef;
      }
   });
}

=head2 table ([limit]), table_parms(parms...), table_lparms(limit, parms...), table_iter(iterator, [limit])

The I<table> functions work just like the I<load> functions, but load the iterator into a L<Data::Org::Table>, if that module is installed.

=cut

sub table_iter {
   my $self = shift;
   
   eval "use Data::Org::Table";
   croak 'Data::Org::Table is not installed' if (@!);

   Data::Org::Table->new ($self->load_iter(@_), $self->fields, 0);
}

sub table {
   my ($self, $limit) = @_;
   $self->table_iter($self->iter(), $limit);
}
sub table_parms {
   my $self = shift;
   $self->table_iter($self->iter(@_));
}
sub table_lparms {
   my $self = shift;
   my $limit = shift;
   $self->table_iter($self->iter(@_), $limit);
}

package Iterator::Records::db;
use DBI;
use Iterator::Simple;
use Carp;
use vars qw(@ISA);
@ISA = qw(DBI::db);

=head2 open ([filename])

The C<open> method opens an SQLite database file. Opens an in-memory file if no filename is provided.

=cut

sub open {
    my $class = shift;
    my $file = shift || ':memory:';
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $file);
    bless($dbh, $class);
    $dbh;
}

sub open_dbh {
   my $class = shift;
   my $dbh = shift;
   bless ($dbh, $class);
   $dbh;
}

=head2 connect(...)

The C<connect> method is just the DBI connect method; we get it via inheritance.

=head2 get (query, [parms])

The C<get> method takes some SQL, executes it with the parameters passed in (if any), retrieves the first row, and returns
the value of the first field of that row.

=cut

sub get {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    my $row = $sth->fetchrow_arrayref;
    $row->[0];
}

=head2 select

The C<select> method retrieves an array of arrayrefs for the rows returned from the query.
In scalar mode, returns the arrayref from C<fetchall_arrayref>.

=cut

sub select {
    my $self = shift;
    my $query = shift;
    return unless defined wantarray;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    my $ret = $sth->fetchall_arrayref;
    return wantarray ? @$ret : $ret;
}

=head2 select_one

The C<select_one> method runs a query and returns the first row as an arrayref.

=cut

sub select_one {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    $sth->fetchrow_arrayref;
}


=head2 iterator (query, [parms), itparms (query, fields)

This is the actual reason for putting this into the Iterator::Records namespace - given a query against the database, we return
an iterator factory for iterators over the rows of the query. Like C<select>, the basic C<iterator> call will assemble a query
and execute it. It will then ask DBI for the names of the fields in the query and use that information to build an C<Iterator::Records> object
that, when iterated, will return the query results. If iterated again, it will run a new query.

If you want to have parameterized queries instead, use C<itparms>, then pass parameters to the factory it creates. In this case, since
the query can't be run in advance, you have to provide the field names you expect. (They don't have to match the ones the database will give
you, though, in this case.)

=cut

# Here's the subtle part. We have to execute the query once to get the field names from the DBI driver. So the first time the iterator factory
# is called, it should return an iterator over *that instance*. But the next time, it has to create a new one.
# 2019-04-23 - turns out SQLite is perfectly capable of returning NAMES after the prepare but before execute - not all drivers can, but SQLite can. So this is largely unnecessary.
sub iterator {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    my $names = $sth->{NAME};
    my $first_time = 1;
    my $factory = sub {
       if ($first_time) {
          $first_time = 0;
       } else {
          $sth = $self->prepare($query);
          $sth->execute(@_);
       }
       sub {
          $sth->fetchrow_arrayref;
       }
    };
    Iterator::Records->new ($factory, $names);
}

sub itparms {
   my $self = shift;
   my $query = shift;
   my $fields = shift;
   my $sth = $self->prepare($query);
   $fields = $sth->{NAME} unless defined $fields;
   
   my $factory = sub {
      $sth->execute(@_);
      sub {
         $sth->fetchrow_arrayref;
      }
   };
   Iterator::Records->new ($factory, $fields);
}

=head2 insert

The C<insert> command calls C<last_insert_id> after the insertion, and returns that value. Just a little shorthand. Since retrieval of the ID for the last
row inserted is very database-specific, it may not work for your particular configuration.

=cut

sub insert {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    $self->last_insert_id('', '', '', '');
}

=head2 load_table (table, iterator), load_sql (insert query, iterator)

For bulk loading, we have single-call methods C<load_table> and C<load_sql>. The former will build an appropriate insert query for the table in question using the iterator's field list.
The second takes an arbitrary insert query, then executes it on each record coming from the iterator. This method can take either an L<Iterator::Records> object, or any coderef or activated
iterator that returns arrayrefs; if given the latter it will simply pass them to the execute call.

Each returns the number of rows inserted.

=cut

sub load_table {
   my ($self, $table, $iterator) = @_;
   my $fields = $iterator->fields();
   my @inserts = map { '?' } @$fields;
   my $sql = "insert into $table values (" . join (', ', @inserts) . ')';
   $self->load_sql ($sql, $iterator->iter());  # TODO: an error in our SQL will show this line. Do better.
}

sub load_sql {
   my ($self, $query, $iterator) = @_;
   croak "Source for bulk load not iterable" unless Iterator::Simple::is_iterable($iterator);
   my $iter = Iterator::Simple::iter($iterator);
   my $sth = $self->prepare($query);
   my $count = 0;
   while (my $rec = $iter->()) {
      $count += 1;
      $sth->execute(@$rec);
   }
   $count;
}

=head2 do

The C<do> command works a little differently from the standard API; DBI's version wants a hashref of attributes that I never use
and regularly screw up.

=cut

sub do {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
}

package Iterator::Records::st;
use vars qw(@ISA);
@ISA = qw(DBI::st);

# We don't actually have anything to override in the statement, but it has to be defined or the DBI machinery won't work.


=head1 AUTHOR

Michael Roberts, C<< <michael at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Iterator-Records at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Iterator-Records>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Iterator::Records


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Iterator-Records>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Iterator-Records>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Iterator-Records>

=item * Search CPAN

L<http://search.cpan.org/dist/Iterator-Records/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Iterator::Records
