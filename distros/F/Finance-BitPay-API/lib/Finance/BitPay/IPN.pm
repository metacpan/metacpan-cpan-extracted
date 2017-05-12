package Finance::BitPay::IPN;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Finance::BitPay::DefaultPackage);

use constant DEBUG => 0;

use CGI;
use JSON;

use constant COMPANY           => 'BitPay';
use constant ATTRIBUTES        => qw(cgi content);
use constant ERROR_NO_CONTENT  => 'No CGI object or content was received';
use constant ERROR_NOT_READY   => 'Not enough information to send a %s request';
use constant ERROR_READY       => 'The request IS%s READY to send';
use constant ERROR_BITPAY      => COMPANY . ' error: "%s"';
use constant ERROR_SERVER_NAME => 'IPN does not seem to be coming from BitPay.com (received: %s)';
use constant BITPAY_URL_REGEX  => qr/^bitpay\.com$/i;
use constant ERROR_NETWORK     => 'Network Request (REST/JSON) error: %s';
use constant ERROR_CONTENT     => 'WARNING: Returning unknown content';

sub is_ready {
    my $self = shift;
    my $ready = 0;
    # here we are checking whether or not to default to '0' (not ready to send) based on this objects settings.
    # the secret is required if the request is private to BitPay.
    if (not $self->request->is_private or defined $self->key) {
       $ready = $self->request->is_ready;
    }
    warn sprintf(ERROR_READY, $ready ? '' : ' NOT') . "\n" if DEBUG;

    return $ready;
}

sub receive {
    my $self = shift;

    # clear any previous response values... because if you wan it, you shoulda put a variable on it.
    $self->request(undef);
    $self->error(undef);

# this cannot be right...
    unless ($self->content) {
        # default to the current ENV variables...
        $self->cgi(CGI->new) unless $self->cgi;
        $self->content($self->cgi->query_string);
    }

    unless ($self->content) {
        $self->error(ERROR_NO_CONTENT);
    }
    else {
        $self->process_content;
    }
# done the part that is not right...

    return $self->is_success;
}

sub process_content {
    my $self = shift;

    # verify the remote source...
    if ($ENV{SERVER_NAME} !~ BITPAY_URL_REGEX) {
        # this is coming from some other server...
        $self->error(sprintf ERROR_SERVER_NAME, $ENV{SERVER_NAME});
    }
    else {
        warn sprintf "Content: %s\n", $self->content if DEBUG;

        my $error_msg;
        my $content;
        eval {
            $content = $self->json->decode($self->content);
            1;
        } or do {
            $self->error(sprintf ERROR_NETWORK, $@);
            warn $self->error . "\n";
            warn sprintf "Content was: %s\n", $self->content;
        };

        unless ($self->error) {
            if (ref $content eq 'HASH' and exists $content->{id}) {
                $self->request($content);
            }
            elsif (ref $content eq 'HASH' and exists $content->{error}) {
                warn sprintf(ERROR_BITPAY, $content->{error}) . "\n";
                $self->error($content->{error});
            }
            else {
                warn ERROR_CONTENT . "\n";
                $self->request($content);
            }
        }
    }
    return $self->is_success;
}

sub json        { shift->{json} ||= JSON->new }
sub is_success  { defined shift->response     }
sub attributes  { ATTRIBUTES                  }

sub server_name { my $self = shift; $self->get_set(@_) || $ENV{SERVER_NAME} }
sub error       { my $self = shift; $self->get_set(@_) }
sub cgi         { my $self = shift; $self->get_set(@_) }
sub request     { my $self = shift; $self->get_set(@_) }
sub response    { my $self = shift; $self->get_set(@_) }

1;

__END__

=head1 NAME

Finance::BitPay::IPN - Perl extension for blah blah blah

=head1 SYNOPSIS

  # This is in a CGI script.
  use Finance::BitPay::IPN;
  use CGI;

  my $ipn = Finance::BitPay::IPN->new;
  my $invoice = $ipn->invoice;

  if ($invoice) {
    printf "Got invoice ID: %s\n", $invoice->{id};
    # ... your code goes here ... #
  }
  else {
    printf "Error: %s\n", $ipn->error;
  }


  ###
  #   OR Write code like me and do this for your CGI script...
  ###

  use base qw(Finance::BitPay::IPN);
  main->new->go;
  sub go {
    my $self = shift;
    if ($self->invoice) {
      printf "Got invoice ID: %s\n", $self->request->{id};
      # ... your code goes here ... #
    else {
      printf "Error: %s\n", $self->error;
    }
  }

=head1 DESCRIPTION

Author says:

 I have no idea if this will work.
 I have never used BitPay for real transactions.
 i guess you just have to give it a whirl.


=head1 SEE ALSO

Finance::BitPay::API

Similar Modules: Coinbase::API, CaVirtex::API, BitStamp::API, BitStamp::Socket

=head1 AUTHOR

Jeff Anderson, E<lt>peawormsworth@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jeff Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
