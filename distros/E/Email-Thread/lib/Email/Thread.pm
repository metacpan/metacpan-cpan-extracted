use strict;
use warnings;
package Email::Thread 0.713;
# ABSTRACT: Use JWZ's mail threading algorithm with Email::Simple objects

use parent 'Mail::Thread';

sub _get_hdr {
    my ($class, $msg, $hdr) = @_;
    $msg->header($hdr);
}

sub _container_class { "Email::Thread::Container" }

package Email::Thread::Container 0.713;
use parent -norequire, 'Mail::Thread::Container';

sub header { eval { $_[0]->message->header($_[1]) } }

1;

=pod

=encoding UTF-8

=head1 NAME

Email::Thread - Use JWZ's mail threading algorithm with Email::Simple objects

=head1 VERSION

version 0.713

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

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 THANKS

Simon Cozens (SIMON) for encouraging me to release it, and for
Email::Simple and Mail::Thread.

Richard Clamp (RCLAMP) for the header patch.

=head1 SEE ALSO

L<perl>, L<Mail::Thread>, L<Email::Simple>

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Iain Truskett <spoon@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod     use Email::Thread;
#pod     my $threader = Email::Thread->new(@messages);
#pod
#pod     $threader->thread;
#pod
#pod     dump_em($_,0) for $threader->rootset;
#pod
#pod     sub dump_em {
#pod         my ($self, $level) = @_;
#pod         debug (' \\-> ' x $level);
#pod         if ($self->message) {
#pod             print $self->message->header("Subject") , "\n";
#pod         } else {
#pod             print "[ Message $self not available ]\n";
#pod         }
#pod         dump_em($self->child, $level+1) if $self->child;
#pod         dump_em($self->next, $level) if $self->next;
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod Strictly speaking, this doesn't really need L<Email::Simple> objects.
#pod It just needs an object that responds to the same API. At the time of
#pod writing the list of classes with the Email::Simple API comprises just
#pod Email::Simple.
#pod
#pod Due to how it's implemented, its API is an exact clone of
#pod L<Mail::Thread>.  Please see that module's documentation for API
#pod details. Just mentally substitute C<Email::Thread> everywhere you see
#pod C<Mail::Thread> and C<Email::Thread::Container> where you see
#pod C<Mail::Thread::Container>.
#pod
#pod =head1 THANKS
#pod
#pod Simon Cozens (SIMON) for encouraging me to release it, and for
#pod Email::Simple and Mail::Thread.
#pod
#pod Richard Clamp (RCLAMP) for the header patch.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<perl>, L<Mail::Thread>, L<Email::Simple>
#pod
#pod =cut

