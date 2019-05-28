package Exception::Class::DBI;

use 5.006;
use strict;
use warnings;
use Exception::Class;

our $VERSION = '1.04';

use Exception::Class (
    'Exception::Class::DBI' => {
        description => 'DBI exception',
        fields      => [qw(err errstr state retval handle)]
    },

    'Exception::Class::DBI::Unknown' => {
        isa         => 'Exception::Class::DBI',
        description => 'DBI unknown exception'
    },

    'Exception::Class::DBI::H' => {
        isa         => 'Exception::Class::DBI',
        description => 'DBI handle exception',
    },

    'Exception::Class::DBI::DRH' => {
        isa         => 'Exception::Class::DBI::H',
        description => 'DBI driver handle exception',
    },

    'Exception::Class::DBI::DBH' => {
        isa         => 'Exception::Class::DBI::H',
        description => 'DBI database handle exception',
    },

    'Exception::Class::DBI::STH' => {
        isa         => 'Exception::Class::DBI::H',
        description => 'DBI statment handle exception',
    }
);

my %handlers;
sub handler {
    my $pkg = shift;
    return $handlers{$pkg} if $handlers{$pkg};

    # Support subclasses.
    my %class_for =  map {
        $_ => do {
            my $class = "$pkg\::$_";
            my $base  = __PACKAGE__ . "::$_";
            no strict 'refs';
            # Try to load the subclass and check its inheritance.
            eval "require $class" unless @{"$class\::ISA"};
            my $isa = \@{"$class\::ISA"};
            die "$class is not a subclass of $base"
                if $isa && !$class->isa($base);
            # If subclass exists and inherits, use it. Otherwise use default.
            $isa ? $class : $base;
        }
    } qw(H DRH DBH STH Unknown);

    return $handlers{$pkg} = sub {
        my ($err, $dbh, $retval) = @_;

        # No handle, no choice.
        $pkg->throw(
            error  => $err,
            retval => $retval
        ) unless ref($dbh ||= $DBI::lasth);

        # Assemble arguments for a handle exception.
        my @params = (
            error  => $err,
            errstr => $dbh->errstr,
            err    => $dbh->err,
            state  => $dbh->state,
            retval => $retval,
            handle => $dbh,
        );

        # Throw the proper exception.
        $class_for{STH}->throw(@params) if eval { $dbh->isa('DBI::st') };
        $class_for{DBH}->throw(@params) if eval { $dbh->isa('DBI::db') };
        $class_for{DRH}->throw(@params) if eval { $dbh->isa('DBI::dr') };

        # Unknown exception. This shouldn't happen.
        $class_for{Unknown}->throw(@params);
    };
}

package Exception::Class::DBI::H;
sub warn                { shift->handle->{Warn} }
sub active              { shift->handle->{Active} }
sub kids                { shift->handle->{Kids} }
sub active_kids         { shift->handle->{ActiveKids} }
sub compat_mode         { shift->handle->{CompatMode} }
sub inactive_destroy    { shift->handle->{InactiveDestroy} }
sub trace_level         { shift->handle->{TraceLevel} }
sub fetch_hash_key_name { shift->handle->{FetchHashKeyName} }
sub chop_blanks         { shift->handle->{ChopBlanks} }
sub long_read_len       { shift->handle->{LongReadLen} }
sub long_trunc_ok       { shift->handle->{LongTruncOk} }
sub taint               { shift->handle->{Taint} }

package Exception::Class::DBI::DBH;
sub auto_commit         { shift->handle->{AutoCommit} }
sub db_name             { shift->handle->{Name} }
sub statement           { shift->handle->{Statement} }
sub row_cache_size      { shift->handle->{RowCacheSize} }

package Exception::Class::DBI::STH;
sub num_of_fields       { shift->handle->{NUM_OF_FIELDS} }
sub num_of_params       { shift->handle->{NUM_OF_PARAMS} }
sub field_names         { shift->handle->{NAME} }
sub type                { shift->handle->{TYPE} }
sub precision           { shift->handle->{PRECISION} }
sub scale               { shift->handle->{SCALE} }
sub nullable            { shift->handle->{NULLABLE} }
sub cursor_name         { shift->handle->{CursorName} }
sub param_values        { shift->handle->{ParamValues} }
sub statement           { shift->handle->{Statement} }
sub rows_in_cache       { shift->handle->{RowsInCache} }

1;
__END__

=head1 Name

Exception::Class::DBI - DBI Exception objects

=head1 Synopsis

  use DBI;
  use Exception::Class::DBI;

  my $dbh = DBI->connect($dsn, $user, $pass, {
      PrintError  => 0,
      RaiseError  => 0,
      HandleError => Exception::Class::DBI->handler,
  });

  eval { $dbh->do($sql) };

  if (my $ex = $@) {
      print STDERR "DBI Exception:\n";
      print STDERR "  Exception Type: ", ref $ex, "\n";
      print STDERR "  Error:          ", $ex->error, "\n";
      print STDERR "  Err:            ", $ex->err, "\n";
      print STDERR "  Errstr:         ", $ex->errstr, "\n";
      print STDERR "  State:          ", $ex->state, "\n";
      print STDERR "  Return Value:   ", ($ex->retval || 'undef'), "\n";
  }

=head1 Description

This module offers a set of DBI-specific exception classes. They inherit from
Exception::Class, the base class for all exception objects created by the
L<Exception::Class|Exception::Class> module from the CPAN.
Exception::Class::DBI itself offers a single class method, C<handler()>, that
returns a code reference appropriate for passing to the DBI C<HandleError>
attribute.

The exception classes created by Exception::Class::DBI are designed to be
thrown in certain DBI contexts; the code reference returned by C<handler()>
and passed to the DBI C<HandleError> attribute determines the context and
throws the appropriate exception.

Each of the Exception::Class::DBI classes offers a set of object accessor
methods in addition to those provided by Exception::Class. These can be used
to output detailed diagnostic information in the event of an exception.

=head1 Interface

Exception::Class::DBI inherits from Exception::Class, and thus its entire
interface. Refer to the Exception::Class documentation for details.

=head2 Class Method

=over 4

=item C<handler>

  my $dbh = DBI->connect($data_source, $username, $auth, {
      PrintError  => 0,
      RaiseError  => 0,
      HandleError => Exception::Class::DBI->handler
  });

This method returns a code reference appropriate for passing to the DBI
C<HandleError> attribute. When DBI encounters an error, it checks its
C<PrintError>, C<RaiseError>, and C<HandleError> attributes to decide what to
do about it. When C<HandleError> has been set to a code reference, DBI
executes it, passing it the error string that would be printed for
C<PrintError>, the DBI handle object that was executing the method call that
triggered the error, and the return value of that method call (usually
C<undef>). Using these arguments, the code reference provided by C<handler()>
determines what type of exception to throw. Exception::Class::DBI contains the
subclasses detailed below, each relevant to the DBI handle that triggered the
error.

=back

=head1 Classes

Exception::Class::DBI creates a number of exception classes, each one specific
to a particular DBI error context. Most of the object methods described below
correspond to like-named attributes in the DBI itself. Thus the documentation
below summarizes the DBI attribute documentation, so you should refer to
L<DBI|DBI> itself for more in-depth information.

=head2 Exception::Class::DBI

All of the Exception::Class::DBI classes documented below inherit from
Exception::Class::DBI. It offers the several object methods in addition to
those it inherits from I<its> parent, Exception::Class. These methods
correspond to the L<DBI dynamic attributes|DBI/"DBI Dynamic Attributes">, as
well as to the values passed to the C<handler()> exception handler via the DBI
C<HandleError> attribute. Exceptions of this base class are only thrown when
there is no DBI handle object executing, e.g. in the DBI C<connect()>
method. B<Note:> This functionality is not yet implemented in DBI -- see the
discusion that starts here:
L<http://archive.develooper.com/dbi-dev@perl.org/msg01438.html>.

=over 4

=item C<error>

  my $error = $ex->error;

Exception::Class::DBI actually inherits this method from Exception::Class. It
contains the error string that DBI prints when its C<PrintError> attribute is
enabled, or C<die>s with when its <RaiseError> attribute is enabled.

=item C<err>

  my $err = $ex->err;

Corresponds to the C<$DBI::err> dynamic attribute. Returns the native database
engine error code from the last driver method called.

=item C<errstr>

  my $errstr = $ex->errstr;

Corresponds to the C<$DBI::errstr> dynamic attribute. Returns the native
database engine error message from the last driver method called.

=item C<state>

  my $state = $ex->state;

Corresponds to the C<$DBI::state> dynamic attribute. Returns an error code in
the standard SQLSTATE five character format.

=item C<retval>

  my $retval = $ex->retval;

The first value being returned by the DBI method that failed (typically
C<undef>).

=item C<handle>

  my $db_handle = $ex->handle;

The DBI handle appropriate to the exception class. For
Exception::Class::DBI::DRH, it will be a driver handle. For
Exception::Class::DBI::DBH it will be a database handle. And for
Exception::Class::DBI::STH it will be a statement handle. If there is no
handle thrown in the exception (because, say, the exception was thrown before
a driver handle could be created), the C<handle> will be C<undef>.

=back

=head2 Exception::Class::DBI::H

This class inherits from L<Exception::Class::DBI|"Exception::Class::DBI">, and
is the base class for all DBI handle exceptions (see below). It will not be
thrown directly. Its methods correspond to the L<DBI attributes common to all
handles|DBI/"ATTRIBUTES COMMON TO ALL HANDLES">.

=over 4

=item C<warn>

  my $warn = $ex->warn;

Boolean value indicating whether DBI warnings have been enabled. Corresponds
to the DBI C<Warn> attribute.

=item C<active>

  my $active = $ex->active;

Boolean value indicating whether the DBI handle that encountered the error is
active. Corresponds to the DBI C<Active> attribute.

=item C<kids>

  my $kids = $ex->kids;

For a driver handle, Kids is the number of currently existing database handles
that were created from that driver handle. For a database handle, Kids is the
number of currently existing statement handles that were created from that
database handle. Corresponds to the DBI C<Kids> attribute.

=item C<active_kids>

  my $active_kids = $ex->active_kids;

Like C<kids>, but only counting those that are C<active> (as
above). Corresponds to the DBI C<ActiveKids> attribute.

=item C<compat_mode>

  my $compat_mode = $ex->compat_mode;

Boolean value indicating whether an emulation layer (such as Oraperl) enables
compatible behavior in the underlying driver (e.g., DBD::Oracle) for this
handle. Corresponds to the DBI C<CompatMode> attribute.

=item C<inactive_destroy>

  my $inactive_destroy = $ex->inactive_destroy;

Boolean value indicating whether the DBI has disabled the database engine
related effect of C<DESTROY>ing a handle. Corresponds to the DBI
C<InactiveDestroy> attribute.

=item C<trace_level>

  my $trace_level = $ex->trace_level;

Returns the DBI trace level set on the handle that encountered the
error. Corresponds to the DBI C<TraceLevel> attribute.

=item C<fetch_hash_key_name>

  my $fetch_hash_key_name = $ex->fetch_hash_key_name;

Returns the attribute name the DBI C<fetchrow_hashref()> method should use to
get the field names for the hash keys. Corresponds to the DBI
C<FetchHashKeyName> attribute.

=item C<chop_blanks>

  my $chop_blanks = $ex->chop_blanks;

Boolean value indicating whether DBI trims trailing space characters from
fixed width character (CHAR) fields. Corresponds to the DBI C<ChopBlanks>
attribute.

=item C<long_read_len>

  my $long_read_len = $ex->long_read_len;

Returns the maximum length of long fields ("blob", "memo", etc.) which the DBI
driver will read from the database automatically when it fetches each row of
data. Corresponds to the DBI C<LongReadLen> attribute.

=item C<long_trunc_ok>

  my $long_trunc_ok = $ex->long_trunc_ok;

Boolean value indicating whether the DBI will truncate values it retrieves from
long fields that are longer than the value returned by
C<long_read_len()>. Corresponds to the DBI C<LongTruncOk> attribute.

=item C<taint>

  my $taint = $ex->taint;

Boolean value indicating whether data fetched from the database is considered
tainted. Corresponds to the DBI C<Taint> attribute.

=back

=head2 Exception::Class::DBI::DRH

DBI driver handle exceptions objects. This class inherits from
L<Exception::Class::DBI::H|"Exception::Class::DBI::H">, and offers no extra
methods of its own.

=head2 Exception::Class::DBI::DBH

DBI database handle exceptions objects. This class inherits from
L<Exception::Class::DBI::H|"Exception::Class::DBI::H"> Its methods correspond
to the L<DBI database handle attributes|DBI/"Database Handle Attributes">.

=over 4

=item C<auto_commit>

  my $auto_commit = $ex->auto_commit;

Returns true if the database handle C<AutoCommit> attribute is
enabled. meaning that database changes cannot be rolled back. Corresponds to
the DBI database handle C<AutoCommit> attribute.

=item C<db_name>

  my $db_name = $ex->db_name;

Returns the "name" of the database. Corresponds to the DBI database handle
C<Name> attribute.

=item C<statement>

  my $statement = $ex->statement;

Returns the statement string passed to the most recent call to the DBI
C<prepare()> method in this database handle. If it was the C<prepare()> method
that encountered the error and triggered the exception, the statement string
will be the statement passed to C<prepare()>. Corresponds to the DBI database
handle C<Statement> attribute.

=item C<row_cache_size>

  my $row_cache_size = $ex->row_cache_size;

Returns the hint to the database driver indicating the size of the local row
cache that the application would like the driver to use for future C<SELECT>
statements. Corresponds to the DBI database handle C<RowCacheSize> attribute.

=back

=head2 Exception::Class::DBI::STH

DBI statement handle exceptions objects. This class inherits from
L<Exception::Class::DBI::H|"Exception::Class::DBI::H"> Its methods correspond
to the L<DBI statement handle attributes|DBI/"Statement Handle Attributes">.

=over 4

=item C<num_of_fields>

  my $num_of_fields = $ex->num_of_fields;

Returns the number of fields (columns) the prepared statement will
return. Corresponds to the DBI statement handle C<NUM_OF_FIELDS> attribute.

=item C<num_of_params>

  my $num_of_params = $ex->num_of_params;

Returns the number of parameters (placeholders) in the prepared
statement. Corresponds to the DBI statement handle C<NUM_OF_PARAMS> attribute.

=item C<field_names>

  my $field_names = $ex->field_names;

Returns a reference to an array of field names for each column. Corresponds to
the DBI statement handle C<NAME> attribute.

=item C<type>

  my $type = $ex->type;

Returns a reference to an array of integer values for each column. The value
indicates the data type of the corresponding column. Corresponds to the DBI
statement handle C<TYPE> attribute.

=item C<precision>

  my $precision = $ex->precision;

Returns a reference to an array of integer values for each column. For
non-numeric columns, the value generally refers to either the maximum length
or the defined length of the column. For numeric columns, the value refers to
the maximum number of significant digits used by the data type (without
considering a sign character or decimal point). Corresponds to the DBI
statement handle C<PRECISION> attribute.

=item C<scale>

  my $scale = $ex->scale;

Returns a reference to an array of integer values for each column. Corresponds
to the DBI statement handle C<SCALE> attribute.

=item C<nullable>

  my $nullable = $ex->nullable;

Returns a reference to an array indicating the possibility of each column
returning a null. Possible values are 0 (or an empty string) = no, 1 = yes, 2
= unknown. Corresponds to the DBI statement handle C<NULLABLE> attribute.

=item C<cursor_name>

  my $cursor_name = $ex->cursor_name;

Returns the name of the cursor associated with the statement handle, if
available. Corresponds to the DBI statement handle C<CursorName> attribute.

=item C<param_values>

  my $param_values = $ex->param_values;

Returns a reference to a hash containing the values currently bound to
placeholders. Corresponds to the DBI statement handle C<ParamValues>
attribute.

=item C<statement>

  my $statement = $ex->statement;

Returns the statement string passed to the DBI C<prepare()>
method. Corresponds to the DBI statement handle C<Statement> attribute.

=item C<rows_in_cache>

  my $rows_in_cache = $ex->rows_in_cache;

the number of unfetched rows in the cache if the driver supports a local row
cache for C<SELECT> statements. Corresponds to the DBI statement handle
C<RowsInCache> attribute.

=back

=head2 Exception::Class::DBI::Unknown

Exceptions of this class are thrown when the context for a DBI error cannot be
determined. Inherits from L<Exception::Class::DBI|"Exception::Class::DBI">,
but implements no methods of its own.

=head1 Note

B<Note:> Not I<all> of the attributes offered by the DBI are exploited by
these exception classes. For example, the C<PrintError> and C<RaiseError>
attributes seemed redundant. But if folks think it makes sense to include the
missing attributes for the sake of completeness, let me know. Enough interest
will motivate me to get them in.

=head1 Subclassing

It is possible to subclass Exception::Class::DBI. The trick is to subclass its
subclasses, too. Similar to subclassing DBI itself, this means that the handle
subclasses should exist as subnamespaces of your base subclass.

It's easier to explain with an example. Say that you wanted to add a new
method to all DBI exceptions that outputs a nicely formatted error message.
You might do it like this:

  package MyApp::Ex::DBI;
  use base 'Exception::Class::DBI';

  sub full_message {
      my $self = shift;
      return $self->SUPER::full_message unless $self->can('statement');
      return $self->SUPER::full_message
          . ' [for Statement "'
          . $self->statement . '"]';
  }

You can then use this subclass just like Exception::Class::DBI itself:

  my $dbh = DBI->connect($dsn, $user, $pass, {
      PrintError  => 0,
      RaiseError  => 0,
      HandleError => MyApp::Ex::DBI->handler,
  });

And that's all well and good, except that none of Exception::Class::DBI's own
subclasses inherit from your class, so most exceptions won't be able to use
your spiffy new method.

The solution is to create subclasses of both the Exception::Class::DBI
subclasses and your own base subclass, as long as they each use the same
package name as your subclass, plus "H", "DRH", "DBH", "STH", and "Unknown".
Here's what it looks like:

  package MyApp::Ex::DBI::H;
  use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::H';

  package MyApp::Ex::DBI::DRH;
  use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::DRH';

  package MyApp::Ex::DBI::DBH;
  use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::DBH';

  package MyApp::Ex::DBI::STH;
  use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::STH';

  package MyApp::Ex::DBI::Unknown;
  use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::Unknown';

And then things should work just spiffy! Of course, you probably don't need
the H subclass unless you want to add other methods for the DRH, DBH, and STH
classes to inherit from.

=head1 To Do

=over 4

=item *

I need to figure out a non-database specific way of testing STH exceptions.
DBD::ExampleP works well for DRH and DBH exceptions, but not so well for
STH exceptions.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/plicease/Exception-Class-DBI/>. Feel free to fork
and contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/plicease/Exception-Class-DBI/issues/> or by sending
mail to
L<bug-Exception-Class-DBI@rt.cpan.org|mailto:bug-Exception-Class-DBI@rt.cpan.org>.

=head1 Author

Original Author is David E. Wheeler <david@justatheory.com>

Current maintainer is Graham Ollis <plicease@cpan.org>

=head1 See Also

You should really only be using this module in conjunction with Tim Bunce's
L<DBI|DBI>, so it pays to be familiar with its documentation.

See the documentation for Dave Rolsky's L<Exception::Class|Exception::Class>
module for details on the methods this module's classes inherit from
it. There's lots more information in these exception objects, so use them!

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2019, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
