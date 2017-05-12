use strict;
use warnings;
package Email::Thread;
{
  $Email::Thread::VERSION = '0.712';
}
# ABSTRACT: Use JWZ's mail threading algorithm with Email::Simple objects

use parent 'Mail::Thread';

sub _get_hdr {
    my ($class, $msg, $hdr) = @_;
    $msg->header($hdr);
}

sub _container_class { "Email::Thread::Container" }

package Email::Thread::Container;
{
  $Email::Thread::Container::VERSION = '0.712';
}
use parent -norequire, 'Mail::Thread::Container';

sub header { eval { $_[0]->message->header($_[1]) } }

1;

__END__

=pod

=head1 NAME

Email::Thread - Use JWZ's mail threading algorithm with Email::Simple objects

=head1 VERSION

version 0.712

=head1 SYNOPSIS

    use Email::Thread;
    my $threader = Email::Thread->new(@messages);

    $threader->thread;

    dump_em($_,0) for $threader->rootset;

    sub dump_em {
        my ($self, $level) = @_;
        debug (' \\-> ' x $level);
        if ($self->message) {
            print $self->message->header("Subject") , "\n";
        } else {
            print "[ Message $self not available ]\n";
        }
        dump_em($self->child, $level+1) if $self->child;
        dump_em($self->next, $level) if $self->next;
    }

=head1 DESCRIPTION

Strictly speaking, this doesn't really need L<Email::Simple> objects.
It just needs an object that responds to the same API. At the time of
writing the list of classes with the Email::Simple API comprises just
Email::Simple.

Due to how it's implemented, its API is an exact clone of
L<Mail::Thread>.  Please see that module's documentation for API
details. Just mentally substitute C<Email::Thread> everywhere you see
C<Mail::Thread> and C<Email::Thread::Container> where you see
C<Mail::Thread::Container>.

=head1 THANKS

Simon Cozens (SIMON) for encouraging me to release it, and for
Email::Simple and Mail::Thread.

Richard Clamp (RCLAMP) for the header patch.

=head1 SEE ALSO

L<perl>, L<Mail::Thread>, L<Email::Simple>

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Iain Truskett <spoon@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
