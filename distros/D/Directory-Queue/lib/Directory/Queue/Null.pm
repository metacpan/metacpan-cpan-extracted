#+##############################################################################
#                                                                              #
# File: Directory/Queue/Null.pm                                                #
#                                                                              #
# Description: object oriented interface to a null directory based queue       #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Directory::Queue::Null;
use strict;
use warnings;
our $VERSION  = "2.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Directory::Queue qw();
use No::Worries::Die qw(dief);

#
# inheritance
#

our(@ISA) = qw(Directory::Queue);

#
# object constructor
#

sub new : method {
    my($class) = @_;
    my($self);

    $self = { path => "NULL", id => "NULL" };
    bless($self, $class);
    return($self);
}

#
# dummy methods (they do almost nothing)
#

sub first : method {
    return("");
}

sub next : method { ## no critic 'ProhibitBuiltinHomonyms'
    return("");
}

sub count : method {
    return(0);
}

sub purge : method {
}

sub add : method {
    return("");
}

sub add_ref : method {
    return("");
}

sub add_path : method {
    my($self, $path) = @_;

    unlink($path) or dief("cannot unlink(%s): %s", $path, $!);
    return("");
}

#
# troublesome methods (they should not be used)
#

sub touch : method {
    dief("unsupported method: touch()");
}

sub lock : method { ## no critic 'ProhibitBuiltinHomonyms'
    dief("unsupported method: lock()");
}

sub unlock : method {
    dief("unsupported method: unlock()");
}

sub remove : method {
    dief("unsupported method: remove()");
}

sub get : method {
    dief("unsupported method: get()");
}

sub get_ref : method {
    dief("unsupported method: get_ref()");
}

sub get_path : method {
    dief("unsupported method: get_path()");
}

1;

__END__

=head1 NAME

Directory::Queue::Null - object oriented interface to a null directory based queue

=head1 SYNOPSIS

  use Directory::Queue::Null;
  $dirq = Directory::Queue::Null->new();
  foreach $count (1 .. 100) {
      $name = $dirq->add(... some data ...);
  }

=head1 DESCRIPTION

The goal of this module is to offer a "null" queue system using the same API
as the other directory queue implementations. The queue will behave like a
black hole: added data will disappear immediately so the queue will therefore
always appear empty.

This can be used for testing purposes or to discard data like one would do on
Unix by redirecting output to C</dev/null>.

Please refer to L<Directory::Queue> for general information about directory
queues.

=head1 CONSTRUCTOR

The new() method can be used to create a Directory::Queue::Null object that
will later be used to interact with the queue. No attributes are supported.

=head1 METHODS

The following methods are available:

=over

=item new()

return a new Directory::Queue::Null object (class method)

=item copy()

return a copy of the object

=item path()

return the queue toplevel path, that is C<NULL>

=item id()

return a unique identifier for the queue, that is C<NULL>

=item count()

return the number of elements in the queue, so always 0

=item first()

return the first element in the queue, so always an empty string

=item next()

return the next element in the queue, so always an empty string

=item add(DATA)

add the given data (it can be anything) to the queue, this does nothing

=item add_ref(REF)

add the given data reference to the queue, this does nothing

=item add_path(PATH)

add the given file (identified by its path) to the queue, this will therefore
B<remove> the file

=item purge()

purge the queue, this does nothing

=back

The following methods are available to provide the same API as the other
directory queue modules but they will always return an error as they cannot be
legitimately called since the queue is always empty:

=over

=item lock(ELEMENT)

=item unlock(ELEMENT)

=item touch(ELEMENT)

=item remove(ELEMENT)

=item get(ELEMENT)

=item get_ref(ELEMENT)

=item get_path(ELEMENT)

=back

=head1 DIRECTORY STRUCTURE

This module does not store any file.

=head1 SEE ALSO

L<Directory::Queue>,
L<Directory::Queue::Normal>,
L<Directory::Queue::Simple>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2021
