package Email::Sender::Transport::Redirect;
{
    $Email::Sender::Transport::Redirect::VERSION = '0.006';
}

=head1 NAME

Email::Sender::Transport::Redirect - Intercept all emails and redirect them to a specific address

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

    $transport_orig = Email::Sender::Transport::Sendmail->new;

    $transport = Email::Sender::Transport::Redirect->new({transport => $transport_orig,
                                                         redirect_address => 'shop@nitesi.com',
                                                         });

=head1 DESCRIPTION

Transport wrapper for Email::Sender which intercepts all emails and redirects
them to a specific address.

This transport changes the C<To> and C<CC> header in the email and
adds a C<X-Intercepted-To> and C<X-Intercepted-CC> header with
the original recipients.

=head1 ATTRIBUTES

=head2 redirect_address

Recipient email address for redirected emails. This value, which can
be either a string or an hashref, is passed to the
L<Email::Sender::Transport::Redirect::Recipients> constructor.

=head2 redirect_headers

Email headers to be changed, defaults to an
array reference containing:

=over 4

=item To

=item CC

=back

=head2 intercept_prefix

Prefix for headers which show the original recipients.

Defaults to C<X-Intercepted->.

=cut

use Moo;
use Types::Standard qw/ArrayRef Str Object/;
use Email::Sender::Transport::Redirect::Recipients;

extends 'Email::Sender::Transport::Wrapper';

has 'redirect_address' => (is => 'ro',
                          required => 1,
                          );

has 'redirect_headers' => (
                           is  => 'ro',
                           isa => ArrayRef,
                           default    => sub { [qw/To Cc/] },
);

has 'intercept_prefix' => (
                           is => 'ro',
                           isa => Str,
                           default => 'X-Intercepted-',
                          );

has recipients => (is => 'lazy',
                        isa => Object);

sub _build_recipients {
    my $self = shift;
    return Email::Sender::Transport::Redirect::Recipients->new($self->redirect_address);
}



=head1 METHOD MODIFIERS

=head2 send_email

Wraps around original method and changes email headers.

=cut

around send_email => sub {
    my ($orig, $self, $email, $env, @rest) = @_;
    my ($email_copy, $env_copy, @values);

    # copy email object to prevent changes in the original object
    $email_copy = ref($email)->new($email->as_string);

    # copy envelope hash reference
    %$env_copy = %$env;

    for my $header (@{$self->redirect_headers}) {
        next unless @values = $email_copy->get_header($header);

        if ($self->intercept_prefix) {
            $email_copy->set_header($self->intercept_prefix . $header,
                                    @values);
        }
        my @replace = map { $self->recipients->replace($_) } @values;
        $email_copy->set_header($header, @replace);
    }
    # if the to was set in the envelope, replace those as well
    if ($env_copy->{to} and @{$env_copy->{to}}) {
        $env_copy->{to} = [ map { $self->recipients->replace($_) } @{$env_copy->{to}} ]
    }
    # no to in the envelope? then set it
    else {
        $env_copy->{to} = [ $self->recipients->to ];
    }
    return $self->$orig($email_copy, $env_copy, @rest);
};

=head1 AUTHOR

Stefan Hornburg (Racke), C<racke@linuxia.de>

=head1 ACKNOWLEDGEMENTS

Thanks to Peter Mottram for the port to Moo (GH #1).

Thanks to Matt Trout for his help regarding the initial write of this
module on #dancer IRC.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2015 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Email::Sender::Transport::Redirect
