package Mail::Thread;

use 5.00503;
use strict;
use vars qw($VERSION $debug $noprune $nosubject);
sub debug (@) { print @_ if $debug }
use Email::Abstract;

$VERSION = '2.55';

sub new {
    my $self = shift;
    return bless {
        messages => [ @_ ],
        id_table => {},
        rootset  => []
    }, $self;
}

sub _get_hdr {
    my ($class, $msg, $hdr) = @_;
    Email::Abstract->get_header($msg, $hdr) || '';
}

sub _uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub _references {
    my $class = shift;
    my $msg = shift;
    my @references = ($class->_get_hdr($msg, "References") =~ /<([^>]+)>/g);
    my $foo = $class->_get_hdr($msg,"In-Reply-To");
    chomp $foo;
    $foo =~ s/.*?<([^>]+)>.*/$1/;
    push @references, $foo
      if $foo =~ /^\S+\@\S+$/ and (!@references || $references[-1] ne $foo);
    return _uniq(@references);
}

sub _msgid {
    my ($class, $msg) = @_;
    my $id= $msg->isa("Mail::Message") ? $msg->messageId :
            $class->_get_hdr($msg, "Message-ID");
    die "attempt to thread message with no id" unless $id;
    chomp $id;
    $id =~ s/^<([^>]+)>.*/$1/; # We expect this not to have <>s
    return $id;
}

sub rootset { @{$_[0]{rootset}} }

sub _dump {
    for (@_) {
        print "\n$_ (";
        print $_->messageid.") [".$_->subject."] has father ".eval{$_->parent};
        print ", child ".eval{$_->child}." and sibling ".eval{$_->next};
        print "\n";
        for my $tag (qw(parent child next)) {
            die "I am my own $tag!" if (eval "\$_->$tag") eq $_;
        }
    }
}

sub _group_set_bysubject {
    my $self = shift;
    my $root = $self->_container_class->new( 'fakeroot' );
    $root->set_children( $self->rootset );

    my %subject;
    for (my $walk = $root->child; $walk; $walk = $walk->next) {
        my $sub = $walk->topmost->simple_subject or next;
        # Add this container to the hash if:
        # - There is no container in the hash with this subject, or
        # - This one is a dummy container and the old one is not: the dummy
        #   one is more interesting as a root, so put it in the hash instead.
        # - The container in the table has a "Re:" version of this subject,
        #   and this container has a non-"Re:" version of this subject.
        #   The non-re version is the more interesting of the two.

        my $old = $subject{$sub};
        if (!$old ||
            (!$walk->message && !$old->message) ||
            ($old->message && $old->isreply &&
             $walk->message && !$walk->isreply)) {
            $subject{$sub} = $walk;
        }
    }
    return unless %subject;

    # %subject is now populated with one entry for each subject which
    # occurs in the root set.  Now iterate over the root set, and
    # gather together the difference.

    my ($prev, $walk, $rest);
    for ($walk = $root->child, $rest = eval{ $walk->next };
         $walk;
         $prev = $walk, $walk = $rest, $rest = eval { $rest->next }) {
        my $subj = $walk->topmost->simple_subject or next;
        my $old = $subject{$subj};
        next if $old == $walk;

        # Remove the "second" message from the root set
        if (!$prev) { $root->child( $walk->next ) }
        else        { $prev->next( $walk->next ) }
        $walk->next(undef);

        if (!$old->message && !$walk->message) {
            # They're both dummies; merge them.
            $old->add_child( $_ ) for $walk->children;
        }
        elsif (!$old->message || # old is empty, or
               ($walk->message &&
                $walk->isreply && # walk has reply, and old doesn't
                !$old->isreply)) {
            # Make this message be a child of the other.
            $old->add_child( $walk );
        }
        else {
            # Make the old and new messages be children of a dummy
            # container.
            my $new = $self->_container_class->new( $old->messageid );
            $old->messageid( 'subject dummy' );
            $new->message( $old->message );
            $old->message( undef );
            $new->add_child( $_ ) for $old->children;
            $old->add_child( $walk );
            $old->add_child( $new );
        }
        # we've done a merge, so keep the same `prev' next time around.
        $walk = $prev;
    }

    # repopulate the rootset from our fake one
    @{$self->{rootset}} = $root->children;
    $root->remove_child($_) for $self->rootset;
}

sub thread {
    my $self = shift;
    $self->_setup();
    $self->{rootset} = [ grep { !$_->parent } values %{$self->{id_table}} ];

    unless ($noprune) {
        my $fakeroot = $self->_container_class->new( 'fakeroot' );
        $fakeroot->set_children( $self->rootset );
        $self->_prune_empties($fakeroot, 0);
        my @kids = @{$self->{rootset}} = $fakeroot->children;
        $fakeroot->remove_child($_) for $fakeroot->children;
    }

    $self->_group_set_bysubject() unless $nosubject;
    $self->_finish();
}

sub _finish {
    my $self = shift;
    delete $self->{id_table};
    delete $self->{seen};
    delete $self->{seen};
}

sub _get_cont_for_id {
    my $self = shift;
    my $id = shift;
    my $cont;
    debug "Looking for a container for $id\n";
    if ($cont = $self->{id_table}{$id}) {
        debug "  Found an existing container for $id, ", $cont->subject,"\n";
    } else {
        debug "  Creating something new to hold $id\n";
        $cont = $self->_container_class->new($id);
        $self->{id_table}{$id} = $cont;
    }
    return $cont;
}

sub _container_class { "Mail::Thread::Container" }

sub _setup {
    my $self = shift;

    # 1.  For each message
    for my $message (@{$self->{messages}}) {
      $self->_add_message($message);
    }

    debug "\nThe final table:\n";
    if ($Mail::Thread::debug) {
        _dump( values %{$self->{id_table}} );
    }
}

sub _add_message {
    my ($self, $message) = @_;

    debug "\n\nLooking at ".$self->_msgid($message)."\n";
    # A. if id_table...
    my $this_container = $self->_get_cont_for_id($self->_msgid($message));
    $this_container->message($message);
    debug "  [".$this_container->subject."]\n----\n";

    # B. For each element in the message's References field:
    my @refs = $self->_references($message);
    debug " Now looking at its references: @refs\n";

    my $prev;
    for my $ref (@refs) {
        debug "   Looking at reference $ref\n";
        # Find a Container object for the given Message-ID
        my $container = $self->_get_cont_for_id($ref);

        # Link the References field's Containers together in the
        # order implied by the References header
        # * If they are already linked don't change the existing links
        # * Do not add a link if adding that link would introduce
        #   a loop...

        if ($prev &&
            !$container->parent &&  # already linked
            !$container->has_descendent($prev) # would loop
           ) {
            $prev->add_child($container);
        }
        $prev = $container;
    }

    # C. Set the parent of this message to be the last element in
    # References...
    if ($prev &&
        !$this_container->has_descendent($prev) # would loop
       ) {
        $prev->add_child($this_container)
    }

    debug "Done with this message!\n----\n";
    if ($debug) {
        _dump( values %{$self->{id_table}} );
    }

    if (0) {
        # Note that at all times the various 'parent' and 'child'
        # fields must be kept inter-consistent
        for my $c (values %{ $self->{id_table} }) {
            if ($c->parent && !grep { $c == $_ } $c->parent->children) {
                die "$c dysfunctional!\n";
            }
        }
    }
}

sub _prune_empties {
    my $self = shift;
    my $cont = shift;
    my $level = shift;

    do { debug "Stuffed!"; return () } if $self->{seen}{$cont}++;
    debug " "x$level;
    debug "Looking at ".$cont->messageid."\n";

    my ($walk, $prev, $next);
    for ($walk = $cont->child, $next = eval { $walk->next };
         $walk;
         $prev = $walk, $walk = $next, $next = eval { $walk->next } ) {

       my @children = $walk->children;
       debug " "x$level;
       debug "Looking at ".$walk->messageid." ".@children." children\n";

       if (!$walk->message and !@children) {
           debug "No message and no children - killing\n";
           if (!$prev) { $cont->child($walk->next) }
           else        { $prev->next($walk->next)  }
           $walk = $prev;
           next;
       }

       if (!$walk->message and @children and (@children == 1 or $walk->parent)) {
           debug "Promoting the children\n";
           my $kids = $walk->child;
           if (!$prev) { $cont->child($kids) }
           else        { $prev->next($kids)  }

           $_->parent($walk->parent) for @children;
           $children[-1]->next( $walk->next );

           $next = $kids;
           $walk = $prev;
           next;
       }

       if ($walk->child) {
           debug "recursing on down\n";
           $self->_prune_empties($walk, $level + 1);
       }
    }
}

sub order {
    my $self = shift;
    my $ordersub = shift;

    # make a fake root
    my $root = $self->_container_class->new( 'fakeroot' );
    $root->add_child( $_ ) for @{ $self->{rootset} };

    # sort it
    $root->order_children( $ordersub );

    # and untangle it
    my @kids = $root->children;
    $self->{rootset} = \@kids;
    $root->remove_child($_) for @kids;
}

package Mail::Thread::Container;
use Carp qw(carp confess croak cluck);

sub new { my $self = shift; bless { id => shift }, $self; }

sub message { $_[0]->{message} = $_[1] if @_ == 2; $_[0]->{message} }
sub child   { $_[0]->{child}   = $_[1] if @_ == 2; $_[0]->{child}   }
sub parent  { $_[0]->{parent}  = $_[1] if @_ == 2; $_[0]->{parent}  }
sub next    { $_[0]->{next}    = $_[1] if @_ == 2; $_[0]->{next}    }
sub messageid { $_[0]->{id}      = $_[1] if @_ == 2; $_[0]->{id}      }
sub subject { $_[0]->header("subject") }
sub header { $_[0]->message and eval { my $s = Email::Abstract->get_header($_[0]->message, $_[1] ) || ''; chomp $s; $s; } }


sub topmost {
    my $self = shift;

    return $self if $self->message;
    my $kid = eval { $self->child->topmost };
    return $kid if $kid;
    my $sib = eval { $self->next->topmost };
    return $sib if $sib;
    return;
}

sub isreply {
    my $self = shift;
    my $subject = $self->subject or return;
    $subject =~ m{^re:\s+}i;
}

sub simple_subject {
    my $self = shift;
    my $subject = $self->subject;
    $subject =~ s/^re:\s+//gi;
    $subject;
}

sub add_child {
    my ($self, $child) = @_;
    croak "Cowardly refusing to become my own parent: $self"
      if $self == $child;

    if (grep { $_ == $child } $self->children) {
        # All is potentially correct with the world
        $child->parent($self);
        return;
    }

    $child->parent->remove_child($child) if $child->parent;

    $child->next($self->child);
    $self->child($child);
    $child->parent($self);
}

sub remove_child {
    my ($self, $child) = @_;
    return unless $self->child;
    if ($self->child == $child) {  # First one's easy.
        $self->child($child->next);
        $child->next(undef);
        $child->parent(undef);
        return;
    }

    my $x = $self->child;
    my $prev = $x;
    while ($x = $x->next) {
        if ($x == $child) {
            $prev->next($x->next); # Unlink x
            $x->next(undef);
            $x->parent(undef);     # Deparent it
            return;
        }
        $prev = $x;
    }
    # oddly, we can get here
    $child->next(undef);
    $child->parent(undef);
}

sub has_descendent {
    my $self = shift;
    my $child = shift;
    die "Assertion failed: $child" unless eval {$child->isa("Mail::Thread::Container")};
    my $there = 0;
    $self->recurse_down(sub { $there = 1 if $_[0] == $child });

    return $there;
}

sub children {
    my $self = shift;
    my @children;
    my $visitor = $self->child;
    while ($visitor) { push @children, $visitor; $visitor = $visitor->next }
    return @children;
}

sub set_children {
    my $self = shift;
    my $walk = $self->child( shift );
    while (@_) { $walk = $walk->next( shift ) }
    $walk->next(undef) if $walk;
}


sub order_children {
    my $self = shift;
    my $ordersub = shift;

    return unless $ordersub;

    my $sub = sub {
        my $cont = shift;
        my @children = $cont->children;
        return if @children < 2;
        $cont->set_children( $ordersub->( @children ) );
    };
    $self->iterate_down( undef, $sub );
    undef $sub;
}

sub recurse_down {
    my %seen;
    my $do_it_all;
    $do_it_all = sub {
        my $self = shift;
        my $callback = shift;
        $seen{$self}++;
        $callback->($self);

        if ($self->next && $seen{$self->next}) { $self->next(undef) }
        $do_it_all->($self->next, $callback)  if $self->next;
        if ($self->child && $seen{$self->child}) { $self->child(undef) }
        $do_it_all->($self->child, $callback) if $self->child;

    };
    $do_it_all->(@_);
    undef $do_it_all;
}

sub iterate_down {
    my $self = shift;
    my ($before, $after) = @_;

    my %seen;
    my $walk = $self;
    my $depth = 0;
    my @visited;
    while ($walk) {
        push @visited, [ $walk, $depth ];
        $before->($walk, $depth) if $before;

        # spot/break loops
        $seen{$walk}++;
        if ($walk->child && $seen{$walk->child}) { $walk->child(undef) }
        if ($walk->next  && $seen{$walk->next})  { $walk->next(undef)  }

        my $next;
        # go down, or across
        if ($walk->child) { $next = $walk->child; ++$depth }
        else              { $next = $walk->next }

        # no next?  look up
        if (!$next) {
            my $up = $walk;
            while ($up && !$next) {
                $up = $up->parent;  --$depth;
                $next = $up->next if $up;
            }
        }
        $walk = $next;
    }
    return unless $after;
    while (@visited) { $after->(@{ pop @visited }) }
}

1;
__END__

=head1 NAME

Mail::Thread - Perl implementation of JWZ's mail threading algorithm

=head1 SYNOPSIS

    use Mail::Thread;
    my $threader = new Mail::Thread (@messages);

    $threader->thread;

    dump_em($_,0) for $threader->rootset;

    sub dump_em {
        my ($self, $level) = @_;
        print ' \\-> ' x $level;
        if ($self->message) {
            print $self->message->head->get("Subject") , "\n";
        } else {
            print "[ Message $self not available ]\n";
        }
        dump_em($self->child, $level+1) if $self->child;
        dump_em($self->next, $level) if $self->next;
    }

=head1 DESCRIPTION

This module implements something relatively close to Jamie Zawinski's mail
threading algorithm, as described by http://www.jwz.org/doc/threading.html.
Any deviations from the algorithm are accidental.

It's happy to be handed any mail object supported by C<Email::Abstract>.
If you need to do anything else, you'll have to subclass and override
C<_get_hdr>.

=head1 METHODS

=head2 new(@messages)

Creates a new threader; requires a bunch of messages to thread.

=head2 thread

Goes away and threads the messages together.

=head2 rootset

Returns a list of C<Mail::Thread::Container>s which are not the parents
of any other message.

=head2 order($ordering_sub)

calls C<order_children> over each member of the root set, from one level higher

=head1 C<Mail::Thread::Container> methods

C<Mail::Thread::Container>s are the nodes of the thread tree. You can't just
have the ordinary messages, because we might not have the message in question.
For instance, a mailbox could contain two replies to a question that we
haven't received yet. So all "logical" messages are stuffed in containers,
whether we happen to have that container or not.

To do anything useful with the thread tree, you're going to have to recurse
around the list of C<Mail::Thread::Containers>. You do this with the following
methods:

=head2 parent

=head2 child

=head2 next

Returns the container which is the parent, child or immediate sibling
of this one, if one exists.

=head2 message

Returns the message held in this container, if we have one.

=head2 messageid

Returns the message ID for this container. This will be around whether we
have the message or not, since some other message will have referred to it
by message ID.

=head2 header( $name )

returns the named header of the contained message

=head2 subject

returns the subject line of the contained message

=head2 isreply

examines the results of ->subject and returns true if it looks like a reply

=head2 simple_subject

the simplified version of ->subject (with reply markers removed)

=head2 has_descendent($child)

Returns true if this container has the given container as a child somewhere
beneath it.

=head2 add_child($child)

Add the C<$child> as a child of oneself.

=head2 remove_child($child)

Remove the C<$child> as a child from oneself.

=head2 children

Returns a list of the B<immediate> children of this container.

=head2 set_children(@children)

set the children of a node.  does not update the ->parents of the @children

=head2 order_children($ordering_sub)

Recursively reorders children according to the results of $ordering_sub

$ordering_sub is called with the containers children, and is expected to
return them in their new order.

 # order by subject line
 $container->order_children( sub {
    sort { $a->topmost->message->subject cmp $b->topmost->message->subject } @_
  } );

$ordering_sub may be omitted, in which case no ordering takes place

=head2 topmost

Walks the tree depth-first and returns the first message container found with a message attached

=head2 recurse_down($callback)

Calls the given callback on this node and B<all> of its children.

=head1 DEBUGGING

You can set $Mail::Thread::debug=1 to watch what's going on.

=head1 MAINTAINER

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Mail-Thread@rt.cpan.org

=head1 ORIGINAL AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kasei
Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
