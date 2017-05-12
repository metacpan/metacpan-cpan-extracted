package Email::Store::Thread;
use strict;
use warnings;
our $VERSION = "1.2";

# Watch the pea. It's under the first shell
use base qw(Email::Store::DBI); # For the DATA stuff
sub on_store_order { 10 }
sub on_store {
    my ($self, $mail) = @_;
    my $threader = Email::Store::Thread::Threader->new($mail);
    $threader->thread;
    my $container = $mail->container;

    # If I'm in the root set, then everyone under me has to know the new
    # root.
    if (grep { $container == $_ } $threader->rootset) {
        $container->recurse_down(sub { shift->root($container) });
    } else {
       # Otherwise, work upwards until I find a root.
       $container->find_root_upwards;
    }
    Email::Store::Thread::Container->flush;
}

package Email::Store::Thread::Threader;
# Keep watching the pea
use base 'Mail::Thread';
sub _get_hdr { my ($class, $msg, $hdr) = @_; $msg->simple->header($hdr); }
sub _container_class { "Email::Store::Thread::Container" }

package Email::Store::Thread::Container;
use Email::Store::Mail;
# Is it under this one?
use base qw(Mail::Thread::Container Email::Store::DBI);
__PACKAGE__->table("container");
__PACKAGE__->columns(All => qw[id messageid message parent child next root]);
__PACKAGE__->has_a(message => "Email::Store::Mail");
__PACKAGE__->has_a(parent  => "Email::Store::Thread::Container");
__PACKAGE__->has_a(child   => "Email::Store::Thread::Container");
__PACKAGE__->has_a(next    => "Email::Store::Thread::Container");
__PACKAGE__->has_a(root    => "Email::Store::Thread::Container");

sub find_root_upwards {
    my $self = shift;
    if (my $par = $self->parent) {
        $par->find_root_upwards unless $par->root;
        $self->root($par->root);
    } else {
        $self->root($self);
    }
}


my %container_cache = ();
sub new {
    my ($class, $id) = @_;
    my $container = $container_cache{$id}
        ||= $class->find_or_create({ messageid => $id });
    return $container;
}

sub flush {
    (delete $container_cache{$_})->update for keys %container_cache;
}

# Thread::Container wants regular accessors
{
    no strict 'refs';
    no warnings 'redefine';
    for my $method (qw/parent child next/) {
        *$method = sub {
            my $self     = shift;
            # ensure we're in the container cache too
            $container_cache{ $self->messageid } = $self;
            my $methname = "_${method}_accessor";
            $self->$methname(@_) if @_;
            $self->$methname();
        };
    }
}

sub subject { $_[0]->message->message ? shift->message->simple->header("Subject") : "" }

package Email::Store::Mail;
sub container {
    Email::Store::Thread::Container->new(shift->message_id)
}


package Email::Store::Thread;
# Are you sure?

1;

=head1 NAME

Email::Store::Thread - Store threading information for a mail

=head1 ABSTRACT

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    my $container = $mail->container;
    if ($container->parent) {
        print "Parent of this message is ".$container->parent->message;
        print "Root of this method is ".$container->root->message;
    }

=head2 DESCRIPTION

This adds to a mail the concept of a B<thread container>. A thread
container is a node in a tree which represents the thread of an email
conversation. It plugs into the indexing process and works out where in
the tree the mail belongs; you can then ask a mail for its C<container>,
a container for its C<message>, and for its C<parent>, C<child> and
C<sibling> containers, which are used to navigate the thread tree.
There's also a C<root> container which represents the top message
in the tree.

This is distributed separately from the main C<Email::Store>
distribution as it tends to slow down indexing somewhat.

=head1 SEE ALSO

L<Email::Store>, L<Mail::Thread>

=head1 AUTHOR

=head1 AUTHOR

The original author is Simon Cozens, E<lt>simon@cpan.orgE<gt>
Currently maintained by Simon Wistow E<lt>simon@thegestalt.orgE<gt>

=head1 SUPPORT

This module is part of the Perl Email Project - http://pep.kwiki.org/

There is a mailing list at pep@perl.org (subscribe at pep-subscribe@perl.org)
and an archive available at http://nntp.perl.org/group/pep.php

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
CREATE TABLE container (
    id         integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
    messageid  varchar(255) NOT NULL,
    message    varchar(255),
    parent     integer,
    child      integer,
    next       integer,
    root       integer
);
