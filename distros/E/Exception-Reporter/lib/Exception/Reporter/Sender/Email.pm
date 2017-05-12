use strict;
use warnings;
package Exception::Reporter::Sender::Email;
# ABSTRACT: a report sender that sends detailed dumps via email
$Exception::Reporter::Sender::Email::VERSION = '0.014';
use parent 'Exception::Reporter::Sender';

#pod =head1 SYNOPSIS
#pod
#pod   my $sender = Exception::Reporter::Sender::Email->new({
#pod     from => 'root',
#pod     to   => 'Beloved SysAdmins <sysadmins@example.com>',
#pod   });
#pod
#pod =head1 OVERVIEW
#pod
#pod This is the only report sender you'll probably ever need.
#pod
#pod It turns the report into a multipart email message and sends it via email.
#pod
#pod Each set of summaries is turned into a MIME message part.  If a dumpable has
#pod become more than one summary, its summaries will be children of a
#pod C<multipart/related> part.  Otherwise, its summary will become a part of the
#pod kind indicated in the summary.
#pod
#pod The C<ident> of the first summary will be used for the subject of the message.
#pod
#pod The GUID of the exception report (the thing returned by the reporter's
#pod C<report_exception> method) is used as the local part of the email message's
#pod Message-ID.
#pod
#pod Every reported message has a In-Reply-To header formed by combining a
#pod slightly-munged version of the C<ident> and the C<reporter>.  This means that
#pod similar exception report emails will thread together in a thread-capable email
#pod reader.
#pod
#pod =cut

use Digest::MD5 ();
use Email::Address ();
use Email::MIME::Creator ();
use Email::MessageID ();
use Email::Sender::Simple ();
use String::Truncate;
use Try::Tiny;

sub new {
  my ($class, $arg) = @_;

  my $from = $arg->{from} || Carp::confess("missing 'from' argument");
  my $to   = $arg->{to}   || Carp::confess("missing 'to' argument"),

  ($from) = Email::Address->parse($from);
  ($to)   = [ map {; Email::Address->parse($_) } (ref $to ? @$to : $to) ];

  # Allow mail from a simple, bare local-part like "root" -- rjbs, 2012-07-03
  $from = Email::Address->new(undef, $arg->{from})
    if ! $from and $arg->{from} =~ /\A[-.0-9a-zA-Z]+\z/;

  Carp::confess("couldn't interpret $arg->{from} as an email address")
    unless $from;

  my $env_from = $arg->{env_from} || $from->address;
  my $env_to   = $arg->{env_to}   || [ map {; $_->address } @$to ];

  $env_to = [ $env_to ] unless ref $env_to;

  return bless {
    from => $from,
    to   => $to,
    env_to   => $env_to,
    env_from => $env_from,
  }, $class;
}

sub from_header {
  my ($self) = @_;
  return $self->{from}->as_string;
}

sub to_header {
  my ($self) = @_;
  return join q{, }, map {; $_->as_string } @{ $self->{to} };
}

sub env_from {
  my ($self) = @_;
  return $self->{env_from};
}

sub env_to {
  my ($self) = @_;
  return @{ $self->{env_to} };
}

#pod =head2 send_report
#pod
#pod  $email_reporter->send_report(\@summaries, \%arg, \%internal_arg);
#pod
#pod This method builds a multipart email message from the given summaries and
#pod sends it.
#pod
#pod C<%arg> is the same set of arguments given to Exception::Reporter's
#pod C<report_exception> method.  Arguments that will have an effect include:
#pod
#pod   extra_rcpts  - an arrayref of extra envelope recipients
#pod   reporter     - the name of the program reporting the exception
#pod   handled      - if true, the reported exception was handled and the user
#pod                  saw a simple error message; sets X-Exception-Handled header
#pod                  and adds a text part at the beginning of the report,
#pod                  calling out the "handled" status"
#pod
#pod C<%internal_arg> contains data produced by the Exception::Reporter using this
#pod object.  It includes the C<guid> of the report and the C<caller> calling the
#pod reporter.
#pod
#pod The mail is sent with the L<C<send_email>> method, which can be replaced in a
#pod subclass.
#pod
#pod The return value of C<send_report> is not defined.
#pod
#pod =cut

sub send_report {
  my ($self, $summaries, $arg, $internal_arg) = @_;

  # ?!? Presumably this can't really happen, but... you know what they say
  # about zero-summary incidents, right?  -- rjbs, 2012-07-03
  Carp::confess("can't report a zero-summary incident!") unless @$summaries;

  my $email = $self->_build_email($summaries, $arg, $internal_arg);

  # Maybe we should try{} to sanity check the extra rcpts first. -- rjbs,
  # 2012-07-05
  $self->send_email(
    $email,
    {
      from    => $self->env_from,
      to      => [ $self->env_to, @{ $arg->{extra_rcpts} || [] }  ],
    }
  );

  return;
}

#pod =method send_email
#pod
#pod   $sender->send_email($email, \%env);
#pod
#pod This method expects an email object (such as can be handled by
#pod L<Email::Sender>) and a a hashref that will have these two keys:
#pod
#pod   from - an envelope sender
#pod   to   - an arrayref of envelope recipients
#pod
#pod It sends the email.  It should not throw an exception on failure.  The default
#pod implementation uses Email::Sender.  If the email injection fails, a warning is
#pod issued.
#pod
#pod =cut

sub send_email {
  my ($self, $email, $env) = @_;

  try {
    Email::Sender::Simple->send($email, $env);
  } catch {
    Carp::cluck "failed to send exception report: $_";
  };

  return;
}

sub _build_email {
  my ($self, $summaries, $arg, $internal_arg) = @_;

  my @parts;
  GROUP: for my $summary (@$summaries) {
    my @these_parts;
    for my $summary (@{ $summary->[1] }) {
      push @these_parts, Email::MIME->create(
        ($summary->{body_is_bytes} ? 'body' : 'body_str') => $summary->{body},
        attributes => {
          filename     => $summary->{filename},
          content_type => $summary->{mimetype},
          encoding     => 'quoted-printable',

          ($summary->{body_is_bytes}
            ? ($summary->{charset} ? (charset => $summary->{charset}) : ())
            : (charset => $summary->{charset} || 'utf-8')),
        },
      );

      $these_parts[-1]->header_set(Date=>);
      $these_parts[-1]->header_set('MIME-Version'=>);
    }

    if (@these_parts == 1) {
      push @parts, @these_parts;
    } else {
      push @parts, Email::MIME->create(
        attributes => { content_type => 'multipart/related' },
        parts       => \@these_parts,
      );
      $parts[-1]->header_set(Date=>);
      $parts[-1]->header_set('MIME-Version'=>);
    }

    $parts[-1]->name_set($summary->[0]);
  }

  if ($arg->{handled}) {
    unshift @parts, Email::MIME->create(
      body_str   => "DON'T PANIC!\n"
                  . "THIS EXCEPTION WAS CAUGHT AND EXECUTION CONTINUED\n"
                  . "THIS REPORT IS PROVIDED FOR INFORMATIONAL PURPOSES\n",
      attributes => {
        content_type => "text/plain",
        charset      => 'utf-8',
        encoding     => 'quoted-printable',
        name         => 'prelude',
      },
    );
    $parts[-1]->header_set(Date=>);
    $parts[-1]->header_set('MIME-Version'=>);
  }

  my $ident = $summaries->[0][1][0]{ident} && $summaries->[0][1][0]{ident}
           || "(unknown exception)";;

  ($ident) = split /\n/, $ident;
  $ident =~ s/\s+(?:at .+?)? ?line\s\d+\.?$//;

  my $digest_ident = $ident;
  $digest_ident =~ s/\(.+//g;

  my ($package, $filename, $line) = @{ $internal_arg->{caller} };

  my $reporter = $arg->{reporter};

  my $email = Email::MIME->create(
    attributes => { content_type => 'multipart/mixed' },
    parts      => \@parts,
    header_str => [
      From => $self->from_header,
      To   => $self->to_header,
      Subject      => String::Truncate::elide("$reporter: $ident", 65),
      'X-Mailer'   => (ref $self),
      'Message-Id' => Email::MessageID->new(user => $internal_arg->{guid})
                                      ->in_brackets,
      'In-Reply-To'=> Email::MessageID->new(
                        user => Digest::MD5::md5_hex($digest_ident),
                        host => $reporter,
                      )->in_brackets,
      'X-Exception-Reporter-Reporter' => $arg->{reporter},
      'X-Exception-Reporter-Caller'   => "$filename line $line ($package)",

      ($arg->{handled} ? ('X-Exception-Reporter-Handled' => 1) : ()),
    ],
  );

  return $email;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Sender::Email - a report sender that sends detailed dumps via email

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  my $sender = Exception::Reporter::Sender::Email->new({
    from => 'root',
    to   => 'Beloved SysAdmins <sysadmins@example.com>',
  });

=head1 OVERVIEW

This is the only report sender you'll probably ever need.

It turns the report into a multipart email message and sends it via email.

Each set of summaries is turned into a MIME message part.  If a dumpable has
become more than one summary, its summaries will be children of a
C<multipart/related> part.  Otherwise, its summary will become a part of the
kind indicated in the summary.

The C<ident> of the first summary will be used for the subject of the message.

The GUID of the exception report (the thing returned by the reporter's
C<report_exception> method) is used as the local part of the email message's
Message-ID.

Every reported message has a In-Reply-To header formed by combining a
slightly-munged version of the C<ident> and the C<reporter>.  This means that
similar exception report emails will thread together in a thread-capable email
reader.

=head2 send_report

 $email_reporter->send_report(\@summaries, \%arg, \%internal_arg);

This method builds a multipart email message from the given summaries and
sends it.

C<%arg> is the same set of arguments given to Exception::Reporter's
C<report_exception> method.  Arguments that will have an effect include:

  extra_rcpts  - an arrayref of extra envelope recipients
  reporter     - the name of the program reporting the exception
  handled      - if true, the reported exception was handled and the user
                 saw a simple error message; sets X-Exception-Handled header
                 and adds a text part at the beginning of the report,
                 calling out the "handled" status"

C<%internal_arg> contains data produced by the Exception::Reporter using this
object.  It includes the C<guid> of the report and the C<caller> calling the
reporter.

The mail is sent with the L<C<send_email>> method, which can be replaced in a
subclass.

The return value of C<send_report> is not defined.

=head1 METHODS

=head2 send_email

  $sender->send_email($email, \%env);

This method expects an email object (such as can be handled by
L<Email::Sender>) and a a hashref that will have these two keys:

  from - an envelope sender
  to   - an arrayref of envelope recipients

It sends the email.  It should not throw an exception on failure.  The default
implementation uses Email::Sender.  If the email injection fails, a warning is
issued.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
