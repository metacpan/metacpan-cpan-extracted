use strict;
use warnings;
package Email::LocalDelivery 1.201;
# ABSTRACT: Deliver a piece of email - simply

use File::Path::Expand 1.01 qw(expand_filename);
use Email::FolderType 0.7 qw(folder_type);
use Carp;

#pod =head1 SYNOPSIS
#pod
#pod   use Email::LocalDelivery;
#pod   my @delivered_to = Email::LocalDelivery->deliver($mail, @boxes);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module delivers an email to a list of mailboxes.
#pod
#pod B<Achtung!>  You might be better off looking at L<Email::Sender>, and at
#pod L<Email::Sender::Transport::Maildir> and L<Email::Sender::Transport::Mbox>.
#pod They are heavily used and more carefully monitored.
#pod
#pod =method deliver
#pod
#pod This takes an email, as a plain string, and a list of mailboxes to
#pod deliver that mail to. It returns the list of boxes actually written to.
#pod If no boxes are given, it assumes the standard Unix mailbox. (Either
#pod C<$ENV{MAIL}>, F</var/spool/mail/you>, F</var/mail/you>, or
#pod F<~you/Maildir/>)
#pod
#pod =cut

sub deliver {
    my ($class, $mail, @boxes) = @_;

    croak "Mail argument to deliver should just be a plain string"
        if ref $mail;

    if (!@boxes) {
        my $default_maildir = (getpwuid($>))[7] . "/Maildir/";
        my $default_unixbox
          = (grep { -d $_ } qw(/var/spool/mail/ /var/mail/))[0]
          . getpwuid($>);

        @boxes = $ENV{MAIL}
            || (-e $default_unixbox && $default_unixbox)
            || (-d $default_maildir."cur" && $default_maildir);
    }
    my %to_deliver;

    for my $box (@boxes) {
      $box = expand_filename($box);
      push @{$to_deliver{folder_type($box)}}, $box;
    }

    my @rv;
    for my $method (keys %to_deliver) {
        eval "require Email::LocalDelivery::$method";
        croak "Couldn't load a module to handle $method mailboxes" if $@;
        push @rv,
        "Email::LocalDelivery::$method"->deliver($mail,
                                                @{$to_deliver{$method}});
    }
    return @rv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::LocalDelivery - Deliver a piece of email - simply

=head1 VERSION

version 1.201

=head1 SYNOPSIS

  use Email::LocalDelivery;
  my @delivered_to = Email::LocalDelivery->deliver($mail, @boxes);

=head1 DESCRIPTION

This module delivers an email to a list of mailboxes.

B<Achtung!>  You might be better off looking at L<Email::Sender>, and at
L<Email::Sender::Transport::Maildir> and L<Email::Sender::Transport::Mbox>.
They are heavily used and more carefully monitored.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 METHODS

=head2 deliver

This takes an email, as a plain string, and a list of mailboxes to
deliver that mail to. It returns the list of boxes actually written to.
If no boxes are given, it assumes the standard Unix mailbox. (Either
C<$ENV{MAIL}>, F</var/spool/mail/you>, F</var/mail/you>, or
F<~you/Maildir/>)

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Casey West <casey@geeknest.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 CONTRIBUTOR

=for stopwords William Yardley

William Yardley <pep@veggiechinese.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
