=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Iterator - A general-purpose iterator class.

=head1 VERSION

This documentation describes version 0.03 of Iterator.pm, October 10, 2005.

=cut

use strict;
use warnings;
package Iterator;
our $VERSION = '0.03';

# Declare exception classes
use Exception::Class
   (
    'Iterator::X' =>
    {
        description => 'Generic Iterator exception',
    },
    'Iterator::X::Parameter_Error' =>
    {
        isa         => 'Iterator::X',
        description => 'Iterator method parameter error',
    },
    'Iterator::X::OptionError' =>
    {
      isa         => 'Iterator::X',
      fields      => 'name',
      description => 'A bad option was passed to an iterator method or function',
    },
    'Iterator::X::Exhausted' =>
    {
        isa         => 'Iterator::X',
        description => 'Attempt to next_value () on an exhausted iterator',
    },
    'Iterator::X::Am_Now_Exhausted' =>
    {
        isa         => 'Iterator::X',
        description => 'Signals Iterator object that it is now exhausted',
    },
    'Iterator::X::User_Code_Error' =>
    {
        isa         => 'Iterator::X',
        fields      => 'eval_error',
        description => q{An exception was thrown within the user's code},
    },
    'Iterator::X::IO_Error' =>
    {
        isa         => 'Iterator::X',
        fields      => 'os_error',
        description => q{An I/O error occurred},
    },
    'Iterator::X::Internal_Error' =>
    {
        isa         => 'Iterator::X',
        description => 'An Iterator.pm internal error.  Please contact author.',
    },
   );

# Class method to help caller catch exceptions
BEGIN
{
    # Dave Rolsky added this subroutine in v1.22 of Exception::Class.
    # Thanks, Dave!
    # We define it here so we have the functionality in pre-1.22 versions;
    # we make it conditional so as to avoid a warning in post-1.22 versions.
    *Exception::Class::Base::caught = sub
    {
        my $class = shift;
        return Exception::Class->caught($class);
    }
        if $Exception::Class::VERSION lt '1.22';
}

# Croak-like location of error
sub Iterator::X::location
{
    my ($pkg,$file,$line);
    my $caller_level = 0;
    while (1)
    {
        ($pkg,$file,$line) = caller($caller_level++);
        last if $pkg !~ /\A Iterator/x  &&  $pkg !~ /\A Exception::Class/x
    }
    return "at $file line $line";
}

# Die-like location of error
sub Iterator::X::Internal_Error::location
{
    my $self = shift;
    return "at " . $self->file () . " line " . $self->line ()
}

# Override full_message, to report location of error in caller's code.
sub Iterator::X::full_message
{
    my $self = shift;

    my $msg = $self->message;
    return $msg  if substr($msg,-1,1) eq "\n";

    $msg =~ s/[ \t]+\z//;   # remove any trailing spaces (is this necessary?)
    return $msg . q{ } . $self->location () . qq{\n};
}


## Constructor

# Method name:   new
# Synopsis:      $iterator = Iterator->new( $code_ref );
# Description:   Object constructor.
# Created:       07/27/2005 by EJR
# Parameters:    $code_ref - the iterator sequence generation code.
# Returns:       New Iterator.
# Exceptions:    Iterator::X::Parameter_Error (via _initialize)
sub new
{
    my $class = shift;
    my $self  = \do {my $anonymous};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

{ # encapsulation enclosure

    # Attributes:
    my %code_for;          # The sequence code (coderef) for each object.
    my %is_exhausted;      # Boolean: is this object exhausted?
    my %next_value_for;    # One-item lookahead buffer for each object.
    # [if you update this list of attributes, be sure to edit DESTROY]

    # Method name:   _initialize
    # Synopsis:      $iterator->_initialize( $code_ref );
    # Description:   Object initializer.
    # Created:       07/27/2005 by EJR
    # Parameters:    $code_ref - the iterator sequence generation code.
    # Returns:       Nothing.
    # Exceptions:    Iterator::X::Parameter_Error
    #                Iterator::X::User_Code_Error
    # Notes:         For internal module use only.
    #                Caches the first value of the iterator in %next_value_for.
    sub _initialize
    {
        my $self = shift;

        Iterator::X::Parameter_Error->throw(q{Too few parameters to Iterator->new()})
            if @_ < 1;
        Iterator::X::Parameter_Error->throw(q{Too many parameters to Iterator->new()})
            if @_ > 1;
        my $code = shift;
        Iterator::X::Parameter_Error->throw (q{Parameter to Iterator->new() must be code reference})
            if ref $code ne 'CODE';

        $code_for {$self} = $code;

        # Get the next (first) value for this iterator
        eval
        {
            $next_value_for{$self} = $code-> ();
        };

        my $ex;
        if ($ex = Iterator::X::Am_Now_Exhausted->caught ())
        {
            # Starting off exhausted is okay
            $is_exhausted{$self} = 1;
        }
        elsif ($@)
        {
            Iterator::X::User_Code_Error->throw (message => "$@",
                                                 eval_error => $@);
        }

        return;
    }

    # Method name:   DESTROY
    # Synopsis:      (none)
    # Description:   Object destructor.
    # Created:       07/27/2005 by EJR
    # Parameters:    None.
    # Returns:       Nothing.
    # Exceptions:    None.
    # Notes:         Invoked automatically by perl.
    #                Releases the hash entries used by the object.
    #                Module would leak memory otherwise.
    sub DESTROY
    {
        my $self = shift;
        delete $code_for{$self};
        delete $is_exhausted{$self};
        delete $next_value_for{$self};
    }

    # Method name:   value
    # Synopsis:      $next_value = $iterator->value();
    # Description:   Returns each value of the sequence in turn.
    # Created:       07/27/2005 by EJR
    # Parameters:    None.
    # Returns:       Next value, as generated by caller's code ref.
    # Exceptions:    Iterator::X::Exhausted
    # Notes:         Keeps one forward-looking value for the iterator in
    #                   %next_value_for.  This is so we have something to
    #                   return when user's code throws Am_Now_Exhausted.
    sub value
    {
        my $self = shift;

        Iterator::X::Exhausted->throw(q{Iterator is exhausted})
            if $is_exhausted{$self};

        # The value that we'll be returning this time.
        my $this_value = $next_value_for{$self};

        # Compute the value that we'll return next time
        eval
        {
            $next_value_for{$self} = $code_for{$self}->(@_);
        };
        if (my $ex = Iterator::X::Am_Now_Exhausted->caught ())
        {
            # Aha, we're done; we'll have to stop next time.
            $is_exhausted{$self} = 1;
        }
        elsif ($@)
        {
            Iterator::X::User_Code_Error->throw (message => "$@",
                                                 eval_error => $@);
        }

        return $this_value;
    }

    # Method name:   is_exhausted
    # Synopsis:      $boolean = $iterator->is_exhausted();
    # Description:   Flag indicating that the iterator is exhausted.
    # Created:       07/27/2005 by EJR
    # Parameters:    None.
    # Returns:       Current value of %is_exhausted for this object.
    # Exceptions:    None.
    sub is_exhausted
    {
        my $self = shift;

        return $is_exhausted{$self};
    }

    # Method name:   isnt_exhausted
    # Synopsis:      $boolean = $iterator->isnt_exhausted();
    # Description:   Flag indicating that the iterator is NOT exhausted.
    # Created:       07/27/2005 by EJR
    # Parameters:    None.
    # Returns:       Logical NOT of %is_exhausted for this object.
    # Exceptions:    None.
    sub isnt_exhausted
    {
        my $self = shift;

        return ! $is_exhausted{$self};
    }

} # end of encapsulation enclosure


# Function name: is_done
# Synopsis:      Iterator::is_done ();
# Description:   Convenience function. Throws an Am_Now_Exhausted exception.
# Created:       08/02/2005 by EJR, per Will Coleda's suggestion.
# Parameters:    None.
# Returns:       Doesn't return.
# Exceptions:    Iterator::X::Am_Now_Exhausted
sub is_done
{
    Iterator::X::Am_Now_Exhausted->throw()
}


1;
__END__

=head1 SYNOPSIS

 use Iterator;

 # Making your own iterators from scratch:
 $iterator = Iterator->new ( sub { code } );

 # Accessing an iterator's values in turn:
 $next_value = $iterator->value();

 # Is the iterator out of values?
 $boolean = $iterator->is_exhausted();
 $boolean = $iterator->isnt_exhausted();

 # Within {code}, above:
 Iterator::is_done();    # to signal end of sequence.


=head1 DESCRIPTION

This module is meant to be the definitive implementation of iterators,
as popularized by Mark Jason Dominus's lectures and recent book
(I<Higher Order Perl>, Morgan Kauffman, 2005).

An "iterator" is an object, represented as a code block that generates
the "next value" of a sequence, and generally implemented as a
closure.  When you need a value to operate on, you pull it from the
iterator.  If it depends on other iterators, it pulls values from them
when it needs to.  Iterators can be chained together (see
L<Iterator::Util> for functions that help you do just that), queueing
up work to be done but I<not actually doing it> until a value is
needed at the front end of the chain.  At that time, one data value is
pulled through the chain.

Contrast this with ordinary array processing, where you load or
compute all of the input values at once, then loop over them in
memory.  It's analogous to the difference between looping over a file
one line at a time, and reading the entire file into an array of lines
before operating on it.

Iterator.pm provides a class that simplifies creation and use of these
iterator objects.  Other C<Iterator::> modules (see L</"SEE ALSO">)
provide many general-purpose and special-purpose iterator functions.

Some iterators are infinite (that is, they generate infinite
sequences), and some are finite.  When the end of a finite sequence is
reached, the iterator code block should throw an exception of the type
C<Iterator::X::Am_Now_Exhausted>; this is usually done via the
L</is_done> function..  This will signal the Iterator class to mark
the object as exhausted.  The L</is_exhausted> method will then return
true, and the L</isnt_exhausted> method will return false.  Any
further calls to the L</value> method will throw an exception of the
type C<Iterator::X::Exhausted>.  See L</DIAGNOSTICS>.

Note that in many, many cases, you will not need to explicitly create
an iterator; there are plenty of iterator generation and manipulation
functions in the other associated modules.  You can just plug them
together like building blocks.

=head1 METHODS

=over 4

=item new

 $iter = Iterator->new( sub { code } );

Creates a new iterator object.  The code block that you provide will
be invoked by the L</value> method.  The code block should have some
way of maintaining state, so that it knows how to return the next
value of the sequence each time it is called.

If the code is called after it has generated the last value in its
sequence, it should throw an exception:

    Iterator::X::Am_Now_Exhausted->throw ();

This very commonly needs to be done, so there is a convenience
function for it:

    Iterator::is_done ();

=item value

 $next_value = $iter->value ();

Returns the next value in the iterator's sequence.  If C<value> is
called on an exhausted iterator, an C<Iterator::X::Exhausted>
exception is thrown.

Note that these iterators can only return scalar values.  If you need
your iterator to return a list or hash, it will have to return an
arrayref or hashref.

=item is_exhausted

 $bool = $iter->is_exhausted ();

Returns true if the iterator is exhausted.  In this state, any call
to the iterator's L</value> method will throw an exception.

=item isnt_exhausted

 $bool = $iter->isnt_exhausted ();

Returns true if the iterator is not yet exhausted.

=back

=head1 FUNCTION

=over 4

=item is_done

 Iterator::is_done();

You call this function after your iterator code has generated its last
value.  See L</TUTORIAL>.  This is simply a convenience wrapper for

 Iterator::X::Am_Now_Exhausted->throw();

=back

=head1 THINKING IN ITERATORS

Typically, when people approach a problem that involves manipulating a
bunch of data, their first thought is to load it all into memory, into
an array, and work with it in-place.  If you're only dealing with one
element at a time, this approach usually wastes memory needlessly.

For example, one might get a list of files to operate on, and loop
over it:

    my @files = fetch_file_list(....);
    foreach my $file (@files)
        ...
If C<fetch_file_list> were modified to return an iterator instead of
an array, the same code could look like this:

    my $file_iterator = fetch_file_list(...)
    while ($file_iterator->isnt_exhausted)
        ...

The advantage here is that the whole list does not take up memory
while each individual element is being worked on.  For a list of
files, that's probably not a lot of overhead.  For the contents of
a file, on the other hand, it could be huge.

If a function requires a list of items as its input, the overhead
is tripled:

    sub myfunc
    {
        my @things = @_;
        ...

Now in addition to the array in the calling code, Perl must copy that
array to C<@_>, and then copy it again to C<@things>.  If you need to
massage the input from somewhere, it gets even worse:

    my @data = get_things_from_somewhere();
    my @filtered_data = grep {code} @data;
    my @transformed_data = map {code} @filtered_data;
    myfunc (@transformed_data);

If C<myfunc> is rewritten to use an Iterator instead of an array,
things become much simpler:

    my $data = ilist (get_things_from_somewhere());
    $filtered_data = igrep {code} $data;
    $transformed_data = imap {code} $filtered_data;
    myfunc ($transformed_data);

(This example assumes that the C<get_things_from_somewhere> function
cannot be modified to return an Iterator.  If it can, so much the
better!)  Now the original list is still in memory, inside the
C<$data> Iterator, but everwhere else, there is only one data element
in memory at a time.

Another advantage of Iterators is that they're homogeneous.  This is
useful for uncoupling library code from application code.  Suppose you
have a library function that grabs data from a filehandle:

    sub my_lib_func
    {
        my $fh = shift;
        ...

If you need C<my_lib_func> to get its data from a different source,
you must either modify it, or make a new copy of it that gets its
input differently, or you must jump through hoops to make the new
input stream look like a Perl filehandle.

On the other hand, if C<my_lib_func> accepts an iterator, then you
can pass it data from a filehandle:

    my $data = ifile "my_input.txt";
    $result = my_lib_func($data);

Or a database handle:

    my $data = imap {$_->{IMPORTANT_COLUMN}}
               idb_rows($dbh, 'select IMPORTANT_COLUMN from foo');
    $result = my_lib_func($data);

If you later decide you need to transform the data, or process only
every 10th data row, or whatever:

    $result = my_lib_func(imap {magic($_)} $data);
    $result = my_lib_func(inth 10, $data);

The library function doesn't care.  All it needs is an iterator.

Chapter 4 of Dominus's book (See L</"SEE ALSO">) covers this topic in
some detail.

=head2 Word of Warning

When you use an iterator in separate parts of your program, or as an
argument to the various iterator functions, you do I<not> get a copy
of the iterator's stream of values.

In other words, if you grab a value from an iterator, then some other
part of the program grabs a value from the same iterator, you will be
getting different values.

This can be confusing if you're not expecting it.  For example:

    my $it_one = Iterator->new ({something});
    my $it_two = some_iterator_transformation $it_one;
    my $value  = $it_two->value();
    my $whoops = $it_one->value;

Here, C<some_iterator_transformation> takes an iterator as an
argument, and returns an iterator as a result.  When a value is
fetched from C<$it_two>, it internally grabs a value from C<$it_one>
(and presumably transforms it somehow).  If you then grab a value from
C<$it_one>, you'll get its I<second> value (or third, or whatever,
depending on how many values C<$it_two> grabbed), not the first.

=head1 TUTORIAL

Let's create a date iterator.  It'll take a L<DateTime> object as a
starting date, and return successive days -- that is, it'll add 1 day
each iteration.  It would be used as follows:

 use DateTime;

 $iter = (...something...);
 $day1 = $iter->value;           # Initial date
 $day2 = $iter->value;           # One day later
 $day3 = $iter->value;           # Two days later

The easiest way to create such an iterator is by using a I<closure>.
If you're not familiar with the concept, it's fairly simple: In Perl,
the code within an I<anonymous block> has access to all the I<lexical
variables> that were in scope at the time the block was created.
After the program then leaves that lexical scope, those lexical
variables remain accessible by that code block for as long as it
exists.

This makes it very easy to create iterators that maintain their own
state.  Here we'll create a lexical scope by using a pair of braces:

 my $iter;
 {
    my $dt = DateTime->now();
    $iter = Iterator->new( sub
    {
        my $return_value = $dt->clone;
        $dt->add(days => 1);
        return $return_value;
    });
}

Because C<$dt> is lexically scoped to the outermost block, it is not
addressable from any code elsewhere in the program.  But the anonymous
block within the L</new> method's parentheses I<can> see C<$dt>.  So
C<$dt> does not get garbage-collected as long as C<$iter> contains a
reference to it.

The code within the anonymous block is simple.  A copy of the current
C<$dt> is made, one day is added to C<$dt>, and the copy is returned.

You'll probably want to encapsulate the above block in a subroutine,
so that you could call it from anywhere in your program:

 sub date_iterator
 {
     my $dt = DateTime->now();
     return Iterator->new( sub
     {
         my $return_value = $dt->clone;
         $dt->add(days => 1);
         return $return_value;
     });
 }

If you look at the source code in L<Iterator::Util>, you'll see that
just about all of the functions that create iterators look very
similar to the above C<date_iterator> function.

Of course, you'd probably want to be able to pass arguments to
C<date_iterator>, say a starting date, maybe an increment other than
"1 day".  But the basic idea is the same.

The above date iterator is an infinite (well, unbounded) iterator.
Let's look at how to indicate that your iterator has reached the end
of its sequence of values.  Let's write a scaled-down version of
L<irange|Iterator::Util/irange> from the Iterator::Util module -- one
that takes a start value and an end value and always increments by 1.

 sub irange_limited
 {
     my ($start, $end) = @_;

     return Iterator->new (sub
     {
         Iterator::is_done
             if $start > $end;

         return $start++;
     });
 }

The iterator itself is very simple (this sort of thing gets to be easy
once you get the hang of it).  The new element here is the signalling
that the sequence has ended, and the iterator's work is done.
L</is_done> is how your code indicates this to the Iterator object.

You may also want to throw an exception if the user specified bad input
parameters.  There are a couple ways you can do this.

     ...
     die "Too few parameters to irange_limited"  if @_ < 2;
     die "Too many parameters to irange_limited" if @_ > 2;
     my ($start, $end) = @_;
     ...

This is the simplest way; you just use C<die> (or C<croak>).  You may
choose to throw an Iterator parameter error, though; this will make
your function work more like one of Iterator.pm's built in functions:

     ...
     Iterator::X::Parameter_Error->throw(
         "Too few parameters to irange_limited")
         if @_ < 2;
     Iterator::X::Parameter_Error->throw(
         "Too many parameters to irange_limited")
         if @_ > 2;
     my ($start, $end) = @_;
     ...


=head1 EXPORTS

No symbols are exported to the caller's namespace.

=head1 DIAGNOSTICS

Iterator uses L<Exception::Class> objects for throwing exceptions.
If you're not familiar with Exception::Class, don't worry; these
exception objects work just like C<$@> does with C<die> and C<croak>,
but they are easier to work with if you are trapping errors.

All exceptions thrown by Iterator have a base class of Iterator::X.
You can trap errors with an eval block:

 eval { $foo = $iterator->value(); };

and then check for errors as follows:

 if (Iterator::X->caught())  {...

You can look for more specific errors by looking at a more specific
class:

 if (Iterator::X::Exhausted->caught())  {...

Some exceptions may provide further information, which may be useful
for your exception handling:

 if (my $ex = Iterator::X::User_Code_Error->caught())
 {
     my $exception = $ex->eval_error();
     ...

If you choose not to (or cannot) handle a particular type of exception
(for example, there's not much to be done about a parameter error),
you should rethrow the error:

 if (my $ex = Iterator::X->caught())
 {
     if ($ex->isa('Iterator::X::Something_Useful'))
     {
         ...
     }
     else
     {
         $ex->rethrow();
     }
 }

=over 4

=item * Parameter Errors

Class: C<Iterator::X::Parameter_Error>

You called an Iterator method with one or more bad parameters.  Since
this is almost certainly a coding error, there is probably not much
use in handling this sort of exception.

As a string, this exception provides a human-readable message about
what the problem was.

=item * Exhausted Iterators

Class: C<Iterator::X::Exhausted>

You called L</value> on an iterator that is exhausted; that is, there
are no more values in the sequence to return.

As a string, this exception is "Iterator is exhausted."

=item * End of Sequence

Class: C<Iterator::X::Am_Now_Exhausted>

This exception is not thrown directly by any Iterator.pm methods, but
is to be thrown by iterator sequence generation code; that is, the
code that you pass to the L</new> constructor.  Your code won't catch
an C<Am_Now_Exhausted> exception, because the Iterator object will
catch it internally and set its L</is_exhausted> flag.

The simplest way to throw this exception is to use the L</is_done>
function:

 Iterator::is_done() if $something;

=item * User Code Exceptions

Class: C<Iterator::X::User_Code_Error>

This exception is thrown when the sequence generation code throws any
sort of error besides C<Am_Now_Exhausted>.  This could be because your
code explicitly threw an error (that is, C<die>d), or because it
otherwise encountered an exception (any runtime error).

This exception has one method, C<eval_error>, which returns the
original C<$@> that was trapped by the Iterator object.  This may be a
string or an object, depending on how C<die> was invoked.

As a string, this exception evaluates to the stringified C<$@>.

=item * I/O Errors

Class: C<Iterator::X::IO_Error>

This exception is thrown when any sort of I/O error occurs; this
only happens with the filesystem iterators.

This exception has one method, C<os_error>, which returns the original
C<$!> that was trapped by the Iterator object.

As a string, this exception provides some human-readable information
along with C<$!>.

=item * Internal Errors

Class: C<Iterator::X::Internal_Error>

Something happened that I thought couldn't possibly happen.  I would
appreciate it if you could send me an email message detailing the
circumstances of the error.

=back

=head1 REQUIREMENTS

Requires the following additional module:

L<Exception::Class>, v1.21 or later.

=head1 SEE ALSO

=over 4

=item *

I<Higher Order Perl>, Mark Jason Dominus, Morgan Kauffman 2005.

L<http://perl.plover.com/hop/>

=item *

The L<Iterator::Util> module, for general-purpose iterator functions.

=item *

The L<Iterator::IO> module, for filesystem and stream iterators.

=item *

The L<Iterator::DBI> module, for iterating over a DBI record set.

=item *

The L<Iterator::Misc> module, for various oddball iterator functions.

=back

=head1 THANKS

Much thanks to Will Coleda and Paul Lalli (and the RPI lily crowd in
general) for suggestions for the pre-release version.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2005 by Eric J. Roode.  All Rights Reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.1 (Cygwin)

iD8DBQFDSrnpY96i4h5M0egRAg65AJ9nP1ybUFl7GgpW9sZKOAEm3UF8MQCgul3g
zElCa4hIQkHXtcAwYwiEPCY=
=B5j0
-----END PGP SIGNATURE-----

=end gpg
