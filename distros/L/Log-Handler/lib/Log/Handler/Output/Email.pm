=head1 NAME

Log::Handler::Output::Email - Log messages as email (via Net::SMTP).

=head1 SYNOPSIS

    use Log::Handler::Output::Email;

    my $email = Log::Handler::Output::Email->new(
        host     => "mx.bar.example",
        hello    => "EHLO my.domain.example",
        timeout  => 120,
        debug    => 0,
        from     => 'bar@foo.example',
        to       => 'foo@bar.example',
        subject  => "your subject",
        buffer   => 0
    );

    $email->log(message => $message);

=head1 DESCRIPTION

With this output module it's possible to log messages via email and it used
Net::SMTP to do it. The date for the email is generated with C<Email::Date::format_date>.

Net::SMTP is from Graham Barr and it does it's job very well.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Email object.

The following opts are possible:

=over 4

=item B<host>

With this option you has to define the SMTP host to connect to.

    host => "mx.host.com"

    # or

    host => [ "mx.host.example", "mx.host-backup.example" ]

=item B<hello>

Identify yourself with a HELO. The default is set to C<EHLO BELO>.

=item B<timeout>

With this option you can set the maximum time in seconds to wait for a
response from the SMTP server. The default is set to 120 seconds.

=item B<from>

The sender address (MAIL FROM).

=item B<to>

The receipient address (RCPT TO).

Additional options are B<cc> and B<bcc>.

=item B<subject>

The subject of the mail.

The default subject is "Log message from $progname". 

=item B<buffer>

This opts exists only for security. The thing is that it would be very bad
if something wents wrong in your program and hundreds of mails would be send.
For this reason you can set a buffer to take care.

With the buffer you can set the maximum size of the buffer in lines. If you set

    buffer => 10

then 10 messages would be buffered. Set C<buffer> to 0 if you want to disable
the buffer.

The default buffer size is set to 20.

=item B<debug>

With this option it's possible to enable debugging. The information can be
intercepted with $SIG{__WARN__}.

=back

=head2 log()

Call C<log()> if you want to log a message as email.

If you set a buffer size then the message will be pushed into the buffer first.

Example:

    $email->log(message => "this message will be mailed");

If you pass the level then its placed into the subject:

    $email->log(message => "foo", level => "INFO");
    $email->log(message => "bar", level => "ERROR");
    $email->log(message => "baz", level => "DEBUG");

The lowest level is used:

    Subject: ERROR: ...

You can pass the level with C<Log::Handler> by setting

    message_pattern => '%L'

=head2 flush()

Call C<flush()> if you want to flush the buffered lines.

=head2 sendmail()

Call C<sendmail()> if you want to send an email.

The difference to C<log()> is that the message won't be buffered.

=head2 validate()

Validate a configuration.

=head2 reload()

Reload with a new configuration.

=head2 errstr()

This function returns the last error message.

=head1 DESTROY

C<DESTROY> is defined and called C<flush()>.

=head1 PREREQUISITES

    Carp
    Email::Date
    Net::SMTP
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output::Email;

use strict;
use warnings;
use Carp;
use Email::Date;
use Net::SMTP;
use Params::Validate qw();

our $VERSION = "0.08";
our $ERRSTR  = "";
our $TEST    =  0; # is needed to disable flush() for tests

my %LEVEL_BY_STRING = (
    DEBUG     =>  7,
    INFO      =>  6,
    NOTICE    =>  5,
    WARNING   =>  4,
    ERROR     =>  3,
    CRITICAL  =>  2,
    ALERT     =>  1,
    EMERGENCY =>  0,
    FATAL     =>  0,
);

sub new {
    my $class = shift;
    my $opts  = $class->_validate(@_);
    return bless $opts, $class;
}

sub log {
    my $self    = shift;
    my $message = @_ > 1 ? {@_} : shift;
    my $buffer  = $self->{message_buffer};

    if ($self->{buffer} == 0) {
        return $self->sendmail($message);
    }

    if (@$buffer < $self->{buffer}) {
        push @$buffer, $message;
    }

    if (@$buffer == $self->{buffer}) {
        return $self->flush;
    }

    return 1;
}

sub flush {
    my $self   = shift;
    my $string = ();
    my $buffer = $self->{message_buffer};

    if ($TEST || !@$buffer) {
        return 1;
    }

    # Safe the last message because the newest subject is used
    my $message = pop @$buffer;

    while (my $buf = shift @$buffer) {
        if ($buf->{level} && !$message->{level}) {
            $message->{level} = $buf->{level};
        } elsif ($buf->{level} && $message->{level}) {
            my $blevel = $buf->{level};
            my $mlevel = $message->{level};
            if ($LEVEL_BY_STRING{$mlevel} > $LEVEL_BY_STRING{$blevel}) {
                $message->{level} = $buf->{level};
            }
        }

        $string .= $buf->{message};
    }

    if (defined $string) {
        $message->{message} = $string . $message->{message};
    }

    return $self->sendmail($message);
}

sub sendmail {
    my $self    = shift;
    my $message = @_ > 1 ? {@_} : shift;
    my $subject = $message->{subject} || $self->{subject};
    my $date    = Email::Date::format_date();
    my $smtp    = ();
    my $expect  = 10;
    my $success = 0;

    if ($message->{level}) {
        $subject = "$message->{level}: $subject";
    }

    foreach my $host (@{$self->{host}}) {
        $smtp = Net::SMTP->new(
            Host    => $host,
            Hello   => $self->{hello},
            Timeout => $self->{timeout},
            Debug   => $self->{debug},
        );
        last if $smtp;
    }

    if (!$smtp) {
        return $self->_raise_error("smtp error: unable to connect to ".join(", ", @{$self->{host}}));
    }

    if ($smtp->mail($self->{from})) {
        $success++;
    }

    if ($smtp->to($self->{to})) {
        $success++;
    }

    if ($self->{cc}) {
        if ($smtp->cc($self->{cc})) {
            $success++;
        }
        $expect++;
    }

    if ($self->{bcc}) {
        if ($smtp->bcc($self->{bcc})) {
            $success++;
        }
        $expect++;
    }

    if ($smtp->data) {
        $success++;
    }

    if ($smtp->datasend("From: $self->{from}\n")) {
        $success++;
    }

    if ($smtp->datasend("To: $self->{to}\n")) {
        $success++;
    }

    if ($self->{cc}) {
        if ($smtp->datasend("Cc: $self->{cc}\n")) {
            $success++;
        }
        $expect++;
    }

    if ($smtp->datasend("Subject: $subject\n")) {
        $success++;
    }

    if ($smtp->datasend("Date: $date\n")) {
        $success++;
    }

    if ($smtp->datasend($message->{message}."\n")) {
        $success++;
    }

    if ($smtp->dataend) {
        $success++;
    }

    if ($smtp->quit) {
        $success++;
    }

    if ($success != $expect) {
        return $self->_raise_error("smtp error($success): unable to send mail to $self->{to}");
    }

    return 1;
}

sub validate {
    my $self = shift;
    my $opts = ();

    eval { $opts = $self->_validate(@_) };

    if ($@) {
        return $self->_raise_error($@);
    }

    return $opts;
}

sub reload {
    my $self = shift;
    my $opts = $self->validate(@_);

    if (!$opts) {
        return undef;
    }

    $self->flush;

    foreach my $key (keys %$opts) {
        $self->{$key} = $opts->{$key};
    }

    return 1;
}

sub errstr {
    return $ERRSTR;
}

sub DESTROY {
    my $self = shift;
    $self->flush;
}

#
# private stuff
#

sub _validate {
    my $class = shift;

    my $progname = $0;
    $progname =~ s@.*[/\\]@@;

    my %opts = Params::Validate::validate(@_, {
        host => {
            type => Params::Validate::ARRAYREF | Params::Validate::SCALAR,
        },
        hello => {
            type => Params::Validate::SCALAR,
            default => "EHLO BELO",
        },
        timeout => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\z/,
            default => 120,
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
        from => {
            type => Params::Validate::SCALAR,
        },
        to => {
            type => Params::Validate::SCALAR,
        },
        cc => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        bcc => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        subject => {
            type => Params::Validate::SCALAR,
            default => "Log message from $progname",
        },
        buffer => {
            type => Params::Validate::SCALAR,
            default => 20,
        },
    });

    if (!ref($opts{host})) {
        $opts{host} = [ $opts{host} ];
    }

    if ($opts{subject}) {
        $opts{subject} =~ s/\n/ /g;
        $opts{subject} =~ s/(.{78})/$1\n /g;

        if (length($opts{subject}) > 998) {
            warn "Subject to long for email!";
            $opts{subject} = substr($opts{subject}, 0, 998);
        }
    }

    $opts{message_buffer} = [ ];
    return \%opts;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
