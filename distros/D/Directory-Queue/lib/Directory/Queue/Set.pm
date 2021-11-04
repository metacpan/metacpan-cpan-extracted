#+##############################################################################
#                                                                              #
# File: Directory/Queue/Set.pm                                                 #
#                                                                              #
# Description: object oriented interface to a set of Directory::Queue objects  #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Directory::Queue::Set;
use strict;
use warnings;
our $VERSION  = "2.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);

#
# return true if the given thing is a Directory::Queue object
#

sub _isdq ($) {
    my($thing) = @_;

    return(ref($thing) && $thing->isa("Directory::Queue"));
}

#
# object constructor
#

sub new : method {
    my($class, @list) = @_;
    my($self);

    $self = {};
    bless($self, $class);
    $self->add(@list);
    return($self);
}

#
# add one or more queues to the set
#

sub add : method {
    my($self, @list) = @_;
    my($id);

    foreach my $dirq (@list) {
        dief("not a Directory::Queue object: %s", $dirq) unless _isdq($dirq);
        $id = $dirq->id();
        dief("duplicate queue in set: %s", $dirq->path())
            if $self->{dirq}{$id};
        $self->{dirq}{$id} = $dirq->copy();
    }
    # reset our iterator
    delete($self->{elt});
}

#
# remove one or more queues from the set
#

sub remove : method {
    my($self, @list) = @_;
    my($id);

    foreach my $dirq (@list) {
        dief("not a Directory::Queue object: %s", $dirq) unless _isdq($dirq);
        $id = $dirq->id();
        dief("missing queue in set: %s", $dirq->path())
            unless $self->{dirq}{$id};
        delete($self->{dirq}{$id});
    }
    # reset our iterator
    delete($self->{elt});
}

#
# get the next element of the queue set
#

sub next : method { ## no critic 'ProhibitBuiltinHomonyms'
    my($self) = @_;
    my($name, $min_elt, $min_id);

    return() unless $self->{elt};
    foreach my $id (keys(%{ $self->{elt} })) {
        $name = substr($self->{elt}{$id}, -14);
        next if defined($min_elt) and $min_elt le $name;
        $min_elt = $name;
        $min_id = $id;
    }
    unless ($min_id) {
        delete($self->{elt});
        return();
    }
    $min_elt = $self->{elt}{$min_id};
    $self->{elt}{$min_id} = $self->{dirq}{$min_id}->next();
    delete($self->{elt}{$min_id}) unless $self->{elt}{$min_id};
    return($self->{dirq}{$min_id}, $min_elt);
}

#
# get the first element of the queue set
#

sub first : method {
    my($self) = @_;

    return() unless $self->{dirq};
    delete($self->{elt});
    foreach my $id (keys(%{ $self->{dirq} })) {
        $self->{elt}{$id} = $self->{dirq}{$id}->first();
        delete($self->{elt}{$id}) unless $self->{elt}{$id};
    }
    return($self->next());
}

#
# count the elements of the queue set
#

sub count : method {
    my($self) = @_;
    my($count);

    return(0) unless $self->{dirq};
    $count = 0;
    foreach my $id (keys(%{ $self->{dirq} })) {
        $count += $self->{dirq}{$id}->count();
    }
    return($count);
}

1;

__END__

=head1 NAME

Directory::Queue::Set - object oriented interface to a set of Directory::Queue objects

=head1 SYNOPSIS

  use Directory::Queue;
  use Directory::Queue::Set;

  $dq1 = Directory::Queue->new(path => "/tmp/q1");
  $dq2 = Directory::Queue->new(path => "/tmp/q2");
  $dqset = Directory::Queue::Set->new($dq1, $dq2);

  ($dq, $elt) = $dqset->first();
  while ($dq) {
      # you can now process the element $elt of queue $dq...
      ($dq, $elt) = $dqset->next();
  }

=head1 DESCRIPTION

This module can be used to put different queues into a set and browse
them as one queue. The elements from all queues are merged together
and sorted independently from the queue they belong to.

This works both with L<Directory::Queue::Normal> and
L<Directory::Queue::Simple> queues. Queues of different types can even
be mixed.

=head1 METHODS

The following methods are available:

=over

=item new([DIRQ...])

return a new Directory::Queue::Set object containing the given queue objects
(class method)

=item add([DIRQ...])

add the given queue objects to the queue set; resetting the iterator

=item remove([DIRQ...])

remove the given queue objects from the queue set; resetting the iterator

=item first()

return the first (queue, element) couple in the queue set, resetting the
iterator; return an empty list if the queue is empty

=item next()

return the next (queue, element) couple in the queue set; return an empty
list if there is no next element

=item count()

return the total number of elements in all the queues of the set

=back

=head1 SEE ALSO

L<Directory::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2021
