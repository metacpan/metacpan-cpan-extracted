use strict;
package Email::Filter;
{
  $Email::Filter::VERSION = '1.034';
}
# ABSTRACT: Library for creating easy email filters

use Email::LocalDelivery;
use Email::Simple;
use Class::Trigger;
use IPC::Run qw(run);

use constant DELIVERED => 0;
use constant TEMPFAIL  => 75;
use constant REJECTED  => 100;


sub done_ok {
    my $self = shift;
    $self->{delivered} = 1;
    exit DELIVERED unless $self->{noexit};
}

sub fail_badly {
    my $self = shift;
    $self->{giveup} = 1; # Don't get caught by DESTROY
    exit TEMPFAIL unless $self->{noexit};
    warn "Message ".$self->simple->header("Message-ID").
          "was never handled properly\n";
}

sub fail_gracefully {
    my $self = shift;
    our $FAILING_GRACEFULLY;
    if ($self->{emergency} and ! $FAILING_GRACEFULLY) {
      local $FAILING_GRACEFULLY = 1;
      $self->done_ok if $self->accept($self->{emergency});
    }
    $self->fail_badly;
}

sub DESTROY {
    my $self = shift;
    return if $self->{delivered}   # All OK.
           or $self->{giveup}      # Tried emergency, didn't work.
           or !$self->{emergency}; # Not much we can do.
    $self->fail_gracefully();
}


sub new {
    my $class = shift;
    my %stuff = @_;
    my $data;

    {
      local $/;
      $data = exists $stuff{data} ? $stuff{data} : scalar <STDIN>;
      # shave any leading From_ line
      $data =~ s/^From .*?[\x0a\x0d]//
    }

    my $obj = bless {
        mail       => Email::Simple->new($data),
        emergency  => $stuff{emergency},
        noexit     => ($stuff{noexit} || 0)
    }, $class;
    $obj->call_trigger("new");
    return $obj;
}


sub exit { $_[0]->{noexit} = !$_[1]; }
sub noexit { $_[0]->{noexit} = $_[1]; }


sub simple {
    my ($filter, $mail) = @_;
    if ($mail) { $filter->{mail} = $mail; }
    return $filter->{mail};
}


sub header { my ($mail, $head) = @_; $mail->simple->header($head); }


sub body { $_[0]->simple->body }


{   no strict 'refs';
    for my $head (qw(From To CC Bcc Subject Received)) {
        *{lc $head} = sub { $_[0]->header($head) }
    }
}


sub ignore {
    $_[0]->call_trigger("ignore");
    $_[0]->done_ok;
}


sub accept {
    my ($self, @where) = @_;
    $self->call_trigger("before_accept", \@where);
    # Unparsing and reparsing is so fast we prefer to do that in order
    # to keep to LocalDelivery's clean interface.
    if (Email::LocalDelivery->deliver($self->simple->as_string, @where)) {
        $self->call_trigger("after_accept", \@where);
        $self->done_ok;
    } else {
        $self->fail_gracefully();
    }
}


sub reject {
    my $self = shift;
    $self->call_trigger("reject");
    $self->{delivered} = 1;
    $! = REJECTED; die @_,"\n";
}


sub pipe {
    my ($self, @program) = @_;
    my $arg;
    $arg = (ref $program[-1] eq 'HASH') ? (pop @program) : {};

    my $stdout;

    my $string = $arg->{header_only}
               ? $self->simple->header_obj->as_string
               : $self->simple->as_string;

    $self->call_trigger("pipe", \@program, $arg);
    if (eval {run(\@program, \$string, \$stdout)} ) {
        $self->done_ok;
        return $stdout;
    }
    $self->fail_gracefully() unless $self->{noexit};
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Filter - Library for creating easy email filters

=head1 VERSION

version 1.034

=head1 SYNOPSIS

    use Email::Filter;
    my $mail = Email::Filter->new(emergency => "~/emergency_mbox");
    $mail->pipe("listgate", "p5p")         if $mail->from =~ /perl5-porters/;
    $mail->accept("perl")                  if $mail->from =~ /perl/;
    $mail->reject("We do not accept spam") if $mail->subject =~ /enlarge/;
    $mail->ignore                          if $mail->subject =~ /boring/i;
    ...
    $mail->exit(0);
    $mail->accept("~/Mail/Archive/backup");
    $mail->exit(1);
    $mail->accept()

=head1 DESCRIPTION

This module replaces C<procmail> or C<Mail::Audit>, and allows you to write
programs describing how your mail should be filtered.

=head1 METHODS

=head2 new

    Email::Filter->new();                # Read from STDIN
    Email::Filter->new(data => $string); # Read from string

    Email::Filter->new(emergency => "~simon/urgh");
    # Deliver here in case of error

This takes an email either from standard input, the usual case when
called as a mail filter, or from a string.

You may also provide an "emergency" option, which is a filename to
deliver the mail to if it couldn't, for some reason, be handled
properly.

=over 3

=item Hint

If you put your constructor in a C<BEGIN> block, like so:

    use Email::Filter;
    BEGIN { $item = Email::Filter->new(emergency => "~simon/urgh"); }

right at the top of your mail filter script, you'll even be protected
from losing mail even in the case of syntax errors in your script. How
neat is that?

=back

This method provides the C<new> trigger, called once an object is
instantiated.

=head2 exit

    $mail->exit(1|0);

Sets or clears the 'exit' flag which determines whether or not the
following methods exit after successful completion.

The sense-inverted 'noexit' method is also provided for backwards
compatibility with C<Mail::Audit>, but setting "noexit" to "yes" got a
bit mind-bending after a while.

=head2 simple

    $mail->simple();

Gets and sets the underlying C<Email::Simple> object for this filter;
see L<Email::Simple> for more details.

=head2 header

    $mail->header("X-Something")

Returns the specified mail headers. In scalar context, returns the
first such header; in list context, returns them all.

=head2 body

    $mail->body()

Returns the body text of the email

=head2 from

=head2 to

=head2 cc

=head2 bcc

=head2 subject

=head2 received

    $mail-><header>()

Convenience accessors for C<header($header)>

=head2 ignore

Ignores this mail, exiting unconditionally unless C<exit> has been set
to false.

This method provides the "ignore" trigger.

=head2 accept

    $mail->accept();
    $mail->accept(@where);

Accepts the mail into a given mailbox or mailboxes.
Unix C<~/> and C<~user/> prefices are resolved. If no mailbox is given,
the default is determined according to L<Email::LocalDelivery>:
C<$ENV{MAIL}>, F</var/spool/mail/you>, F</var/mail/you>, or
F<~you/Maildir/>.

This provides the C<before_accept> and C<after_accept> triggers, and
exits unless C<exit> has been set to false.  They are passed a reference to the
C<@where> array.

=head2 reject

    $mail->reject("Go away!");

This rejects the email; if called in a pipe from a mail transport agent, (such
as in a F<~/.forward> file) the mail will be bounced back to the sender as
undeliverable. If a reason is given, this will be included in the bounce.

This calls the C<reject> trigger. C<exit> has no effect here.

=head2 pipe

    $mail->pipe(qw[sendmail foo\@bar.com]);

Pipes the mail to an external program, returning the standard output
from that program if C<exit> has been set to false. The program and each
of its arguments must be supplied in a list. This allows you to do
things like:

    $mail->exit(0);
    $mail->simple(Email::Simple->new($mail->pipe("spamassassin")));
    $mail->exit(1);

in the absence of decent C<Mail::SpamAssassin> support.

If the program returns a non-zero exit code, the behaviour is dependent
on the status of the C<exit> flag. If this flag is set to true (the
default), then C<Email::Filter> tries to recover. (See L</ERROR RECOVERY>)
If not, nothing is returned.

If the last argument to C<pipe> is a reference to a hash, it is taken to
contain parameters to modify how C<pipe> itself behaves.  The only useful
parameter at this time is:

  header_only - only pipe the header, not the body

=head1 TRIGGERS

Users of C<Mail::Audit> will note that this class is much leaner than
the one it replaces. For instance, it has no logging; the concept of
"local options" has gone away, and so on. This is a deliberate design
decision to make the class as simple and maintainable as possible.

To make up for this, however, C<Email::Filter> contains a trigger
mechanism provided by L<Class::Trigger>, to allow you to add your own
functionality. You do this by calling the C<add_trigger> method:

    Email::Filter->add_trigger( after_accept => \&log_accept );

Hopefully this will also help subclassers.

The methods below will list which triggers they provide.

=head1 ERROR RECOVERY

If something bad happens during the C<accept> or C<pipe> method, or
the C<Email::Filter> object gets destroyed without being properly
handled, then a fail-safe error recovery process is called. This first
checks for the existence of the C<emergency> setting, and tries to
deliver to that mailbox. If there is no emergency mailbox or that
delivery failed, then the program will either exit with a temporary
failure error code, queuing the mail for redelivery later, or produce a
warning to standard error, depending on the status of the C<exit>
setting.

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Casey West

=item *

Ricardo SIGNES <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
