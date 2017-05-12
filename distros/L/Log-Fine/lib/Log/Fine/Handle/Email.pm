
=head1 NAME

Log::Fine::Handle::Email - Email log messages to one or more addresses

=head1 SYNOPSIS

Provides messaging to one or more email addresses.

    use Email::Sender::Simple qw(sendmail);
    use Email::Sender::Transport::SMTP qw();
    use Log::Fine;
    use Log::Fine::Handle::Email;
    use Log::Fine::Levels::Syslog;

    # Get a new logger
    my $log = Log::Fine->logger("foo");

    # Create a formatter object for subject line
    my $subjfmt = Log::Fine::Formatter::Template
        ->new( name     => 'template1',
               template => "%%LEVEL%% : The angels have my blue box" );

    # Create a formatted msg template
    my $msgtmpl = <<EOF;
    The program, $0, has encountered the following error condition:

    %%MSG%% at %%TIME%%

    Contact Operations at 1-800-555-5555 immediately!
    EOF

    my $bodyfmt = Log::Fine::Formatter::Template
        ->new( name     => 'template2',
               template => $msgtmpl );

    # Create an Email Handle
    my $handle = Log::Fine::Handle::Email
        ->new( name => 'email0',
               mask => LOGMASK_EMERG | LOGMASK_ALERT | LOGMASK_CRIT,
               subject_formatter => $subjfmt,
               body_formatter    => $bodyfmt,
               header_from       => "alerts@example.com",
               header_to         => [ "critical_alerts@example.com" ],
               envelope          =>
                 { to   => [ "critical_alerts@example.com" ],
                   from => "alerts@example.com",
                   transport =>
                     Email::Sender::Transport::SMTP->new({ host => 'smtp.example.com' }),
                 }
             );

    # Register the handle
    $log->registerHandle($handle);

    # Log something
    $log->log(CRIT, "Beware the weeping angels");

=head1 DESCRIPTION

Log::Fine::Handle::Email provides formatted message delivery to one or
more email addresses.  The intended use is for programs that need to
alert a user in the event of a critical condition.  Conceivably, the
destination address could be a pager or cell phone.

=head2 Implementation Details

Log::Fine::Handle::Email uses the L<Email::Sender> framework for
delivery of emails.  Users who wish to use Log::Fine::Handle::Email
are I<strongly> encouraged to read the following documentation:

=over

=item  * L<Email::Sender::Manual>

=item  * L<Email::Sender::Manual::Quickstart>

=item  * L<Email::Sender::Simple>

=back

Be especially mindful of the following environment variables as they
will take precedence when defining a transport:

=over

=item  * C<EMAIL_SENDER_TRANSPORT>

=item  * C<EMAIL_SENDER_TRANSPORT_host>

=item  * C<EMAIL_SENDER_TRANSPORT_port>

=back

See L<Email::Sender::Manual::Quickstart> for further details.

=head2 Email Address Validation

Log::Fine::Handle::Email will validate each email addresses prior to
use.  Upon initilization, L::F::H::E will search for and use the
following email address validation modules in the following order of
preference:

=over

=item  * L<Mail::RFC822::Address>

=item  * L<Email::Valid>

=back

Should neither Mail::RFC822::Address nor Email::Valid be found, then a
default regex will be used which should work for most instances.  See
L<CAVEATS> for special considerations.

=head2 Constructor Parameters

The following parameters can be passed to
Log::Fine::Handle::Email->new();

=over

=item  * name

[optional] Name of this object (see L<Log::Fine>).  Will be auto-set if
not specified.

=item  * mask

Mask to set the handle to (see L<Log::Fine::Handle>)

=item  * subject_formatter

A Log::Fine::Formatter object.  Will be used to format the Email
Subject Line.

=item  * body_formatter

A Log::Fine::Formatter object.  Will be used to format the body of the
message.

=item  * header_from

String containing text to be placed in "From" header of generated
email.

=item  * header_to

String containing text to be placed in "To" header of generated email.
Optionally, this can be an array ref containing multiple addresses

=item  * envelope

[optional] hash ref containing envelope information for email:

=over 8

=item  + to

array ref containing one or more destination addresses

=item  + from

String containing email sender

=item  + transport

An L<Email::Sender::Transport> object.  See L<Email::Sender::Manual>
for further details.

=back

=back

=cut

use strict;
use warnings;

package Log::Fine::Handle::Email;

use 5.008_003;          # Email::Sender requires Moose which requires 5.8.3

use base qw( Log::Fine::Handle );

use Carp qw(carp);

#use Data::Dumper;
use Email::Sender::Simple qw(try_to_sendmail);
use Email::Simple;
use Log::Fine;
use Log::Fine::Formatter;
use Sys::Hostname;

BEGIN {

        # Set email address validation routine depending on what
        # module is installed on this system
        my @modules = ('Mail::RFC822::Address', 'Email::Valid', 'Default');

        foreach my $module (@modules) {

                if ($module eq 'Default') {
                        *_isValid = \&_validate_default;
                        carp 'Using default email validation.  ' . 'Consider Mail::RFC822::Address\n';
                        last;
                }

                eval "{ require $module }";

                unless ($@) {
                        my $sub = '_validate_' . lc($module);
                        $sub =~ s/\:\:/_/g;

                        *_isValid = \&{$sub};
                        last;
                }

                # Reset $@ just in case
                undef $@;

        }

}

our $VERSION = $Log::Fine::Handle::VERSION;

# --------------------------------------------------------------------

=head1 METHODS

=head2 msgWrite

Sends given message via Email::Sender module.  Note that
L<Log::Fine/_error> will be called should there be a failure of
delivery.

See L<Log::Fine::Handle/msgWrite>

=cut

sub msgWrite
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = shift;

        my $email =
            Email::Simple->create(
                                  header => [ To      => $self->{header_to},
                                              From    => $self->{header_from},
                                              Subject => $self->{subject_formatter}->format($lvl, "", $skip),
                                  ],
                                  body => $self->{body_formatter}->format($lvl, $msg, $skip),
            );

        # Set X-Mailer
        $email->header_set("X-Mailer", sprintf("%s ver %s", ref $self, $VERSION));

        $self->_error("Unable to deliver email: $_")
            unless (try_to_sendmail($email, $self->{envelope}));

}          # msgWrite()

# --------------------------------------------------------------------

##
# Initializes our object

sub _init
{

        my $self = shift;

        # Perform any necessary upper class initializations
        $self->SUPER::_init();

        # Make sure envelope is defined
        $self->{envelope} ||= {};

        # Validate From address
        if (not defined $self->{header_from}) {
                $self->{header_from} =
                    printf("%s@%s", $self->_userName(), $self->_hostName());
        } elsif (defined $self->{header_from}
                 and not $self->_isValid($self->{header_from})) {
                $self->_fatal("{header_from} must be a valid RFC 822 Email Address");
        }

        # Validate To address
        $self->_fatal(  "{header_to} must be either an array ref containing "
                      . "valid email addresses or a string representing a "
                      . "valid email address")
            unless (defined $self->{header_to});

        # Check for array ref
        if (ref $self->{header_to} eq "ARRAY") {

                if ($self->_isValid($self->{header_to})) {
                        $self->{header_to} = join(",", @{ $self->{header_to} });
                } else {
                        $self->_fatal("{header_to} must contain valid " . "RFC 822 email addresses");
                }

        } elsif (not $self->_isValid($self->{header_to})) {
                $self->_fatal("{header_to} must contain a valid " . "RFC 822 email address");
        }

        # Validate subject formatter
        $self->_fatal("{subject_formatter} must be a valid " . "Log::Fine::Formatter object")
            unless (    defined $self->{subject_formatter}
                    and ref $self->{subject_formatter}
                    and UNIVERSAL::can($self->{subject_formatter}, 'isa')
                    and $self->{subject_formatter}->isa("Log::Fine::Formatter"));

        # Validate body formatter
        $self->_fatal(
                "{body_formatter} must be a valid " . "Log::Fine::Formatter object : " . ref $self->{body_formatter}
                    || "{undef}")
            unless (    defined $self->{body_formatter}
                    and ref $self->{body_formatter}
                    and UNIVERSAL::can($self->{body_formatter}, 'isa')
                    and $self->{body_formatter}->isa("Log::Fine::Formatter"));

        # Grab a ref to envelope
        my $envelope = $self->{envelope};

        # Check Envelope Transport
        if (defined $envelope->{transport}) {
                my $transtype = ref $envelope->{transport};
                $self->_fatal(
                              "{envelope}->{transport} must be a valid " . "Email::Sender::Transport object : $transtype")
                    unless ($transtype =~ /^Email\:\:Sender\:\:Transport/);
        }

        # Check Envelope To
        if (defined $envelope->{to}) {
                $self->_fatal(  "{envelope}->{to} must be an "
                              . "array ref containing one or more valid "
                              . "RFC 822 email addresses")
                    unless (ref $envelope->{to} eq "ARRAY"
                            and $self->_isValid($envelope->{to}));
        }

        # Check envelope from
        if (defined $envelope->{from} and $envelope->{from} =~ /\w/) {
                $self->_fatal("{envelope}->{from} must be a " . "valid RFC 822 Email Address")
                    unless $self->_isValid($envelope->{from});
        } else {
                $envelope->{from} = $self->{header_from};
        }

        # Validate subject formatter
        $self->_fatal("{subject_formatter} must be a valid " . "Log::Fine::Formatter object")
            unless (defined $self->{subject_formatter}
                    and $self->{subject_formatter}->isa("Log::Fine::Formatter"));

        # Validate body formatter
        $self->_fatal(
                "{body_formatter} must be a valid " . "Log::Fine::Formatter object : " . ref $self->{body_formatter}
                    || "{undef}")
            unless (defined $self->{body_formatter}
                    and $self->{body_formatter}->isa("Log::Fine::Formatter"));

        return $self;

}          # _init()

##
# Getter/Setter for hostname

sub _hostName
{

        my $self = shift;

        # Should {_fullHost} be already cached, then return it,
        # otherwise get hostname, cache it, and return
        $self->{_fullHost} = hostname() || "{undef}"
            unless (defined $self->{_fullHost} and $self->{_fullHost} =~ /\w/);

        return $self->{_fullHost};

}          # _hostName()

##
# Getter/Setter for user name

sub _userName
{

        my $self = shift;

        # Should {_userName} be already cached, then return it,
        # otherwise get the user name, cache it, and return
        if (defined $self->{_userName} and $self->{_userName} =~ /\w/) {
                return $self->{_userName};
        } elsif ($self->{use_effective_id}) {
                $self->{_userName} =
                    ($^O eq "MSWin32")
                    ? $ENV{EUID}   || 0
                    : getpwuid($>) || "nobody";
        } else {
                $self->{_userName} = getlogin() || getpwuid($<) || "nobody";
        }

        return $self->{_userName};

}          # _userName()

##
# Default email address checker
#
# Parameters:
#
#  - addy : either a scalar containing a string to check or an array
#           ref containing one or more strings to check
#
# Returns:
#
#  1 on success, undef otherwise

sub _validate_default
{

        my $self = shift;
        my $addy = shift;

        if (ref $addy eq "ARRAY") {
                foreach my $address (@{$addy}) {
                        return undef
                            unless $address =~
/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+\@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
                }
        } else {
                return undef
                    unless ($addy =~
/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+\@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
                    );
        }

        return 1;

}          # _validate_default()

##
# Validate email address via Email::Valid
#
# Parameters:
#
#  - addy : either a scalar containing a string to check or an array
#           ref containing one or more strings to check
#
# Returns:
#
#  1 on success, undef otherwise

sub _validate_email_valid
{

        my $self = shift;
        my $addy = shift;

        my $validator = Email::Valid->new();

        if (ref $addy eq 'ARRAY') {
                foreach my $address (@{$addy}) {
                        return undef unless $validator->address($address);
                }
        } else {
                return undef unless $validator->address($addy);
        }

        return 1;

}          # _validate_email_valid()

##
# Validate email address via Mail::RFC822::Address
#
# Parameters:
#
#  - addy : either a scalar containing a string to check or an array
#           ref containing one or more strings to check
#
# Returns:
#
#  1 on success, undef otherwise

sub _validate_mail_rfc822_address
{

        my $self = shift;
        my $addy = shift;

        if (ref $addy eq "ARRAY") {
                return Mail::RFC822::Address::validlist($addy);
        } else {
                return Mail::RFC822::Address::valid($addy);
        }

}          # _validate_mail_rfc822_address()

=head1 CAVEATS

Note that the L<Email::Valid> module does not use the same checking
algorithms as L<Mail::RFC822::Address>.  Email addresses considered
valid under one module may not be considered valid under the other.
For example, under Mail::RFC822::Address, C<jsmith@localhost> is
considered a valid address while Email::Valid will reject it.
Consider researching each module prior to making a determination as to
which is acceptable for your environment and needs.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<Log::Fine>, L<Log::Fine::Handle>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011-2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle::Email
