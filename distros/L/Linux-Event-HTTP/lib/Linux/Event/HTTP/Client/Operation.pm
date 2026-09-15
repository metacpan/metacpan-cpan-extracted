package Linux::Event::HTTP::Client::Operation;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = '0.001';

my %TERMINAL = map { $_ => 1 } qw(complete cancelled error);

sub _new ($class, %option) {
    my $initial_url = delete $option{initial_url};
    my $max_redirects = delete $option{max_redirects};
    my $max_auth_retries = exists($option{max_auth_retries})
        ? delete($option{max_auth_retries})
        : 0;

    die 'Client::Operation initial_url is required'
        if !defined($initial_url) || ref($initial_url);
    die 'Client::Operation max_redirects must be a non-negative integer'
        if !defined($max_redirects) || ref($max_redirects)
        || "$max_redirects" !~ /\A[0-9]+\z/;
    die 'Client::Operation max_auth_retries must be a non-negative integer'
        if !defined($max_auth_retries) || ref($max_auth_retries)
        || "$max_auth_retries" !~ /\A[0-9]+\z/;
    die 'unknown Client::Operation option: ' . join(', ', sort keys %option)
        if %option;

    return bless {
        initial_url       => "$initial_url",
        max_redirects     => 0 + $max_redirects,
        max_auth_retries  => 0 + $max_auth_retries,
        redirect_count    => 0,
        auth_retry_count  => 0,
        urls              => [],
        transactions      => [],
        state             => 'pending',
        error             => undef,
    }, $class;
}

sub initial_url      ($self) { $self->{initial_url} }
sub max_redirects    ($self) { $self->{max_redirects} }
sub max_auth_retries ($self) { $self->{max_auth_retries} }
sub redirect_count   ($self) { $self->{redirect_count} }
sub auth_retry_count ($self) { $self->{auth_retry_count} }
sub state            ($self) { $self->{state} }
sub error            ($self) { $self->{error} }

sub transaction ($self) {
    return $self->{transactions}[-1];
}

sub transactions ($self) {
    return @{$self->{transactions}};
}

sub transaction_count ($self) {
    return scalar @{$self->{transactions}};
}

sub url ($self) {
    return @{$self->{urls}} ? $self->{urls}[-1] : $self->{initial_url};
}

sub urls ($self) {
    return @{$self->{urls}};
}

sub request ($self) {
    my $transaction = $self->transaction or return undef;
    return $transaction->request;
}

sub response ($self) {
    my $transaction = $self->transaction or return undef;
    return $transaction->response;
}

sub request_body ($self, @args) {
    my $transaction = $self->transaction
        or die 'request_body(): Client operation has no active Transaction';
    return $transaction->request_body(@args);
}

sub is_complete  ($self) { $self->{state} eq 'complete' }
sub is_cancelled ($self) { $self->{state} eq 'cancelled' }
sub is_terminal  ($self) { !!$TERMINAL{$self->{state}} }

sub cancel ($self) {
    return $self if $self->is_terminal;

    if (my $transaction = $self->transaction) {
        $transaction->cancel if !$transaction->is_terminal;
    }

    return $self->_mark_cancelled;
}

sub _append_transaction ($self, $transaction, $url, $kind = 'initial') {
    die 'cannot append a Transaction to a terminal Client operation'
        if $self->is_terminal;
    die 'Client operation requires a Linux::Event::HTTP::Transaction'
        if !blessed($transaction)
        || !$transaction->isa('Linux::Event::HTTP::Transaction');
    die 'Client operation hop URL must be a scalar'
        if !defined($url) || ref($url);
    die "unknown Client operation Transaction kind '$kind'"
        if $kind ne 'initial' && $kind ne 'redirect' && $kind ne 'auth';
    die 'initial Client operation Transaction must be first'
        if $kind eq 'initial' && @{$self->{transactions}};

    $self->{redirect_count}++ if $kind eq 'redirect';
    $self->{auth_retry_count}++ if $kind eq 'auth';

    push @{$self->{transactions}}, $transaction;
    push @{$self->{urls}}, "$url";
    $self->{state} = 'active';
    return $transaction;
}

sub _mark_complete ($self) {
    die 'cannot complete a terminal Client operation' if $self->is_terminal;
    my $transaction = $self->transaction
        or die 'cannot complete Client operation without a Transaction';
    die 'cannot complete Client operation before final Transaction completes'
        if !$transaction->is_complete;

    $self->{state} = 'complete';
    return $self;
}

sub _mark_cancelled ($self) {
    return $self if $self->{state} eq 'cancelled';
    die 'cannot cancel a terminal Client operation' if $self->is_terminal;
    $self->{state} = 'cancelled';
    return $self;
}

sub _fail ($self, $error) {
    return $self if $self->{state} eq 'error' && defined $self->{error};
    die 'cannot fail a terminal Client operation' if $self->is_terminal;
    die 'Client operation error must be defined' if !defined $error;

    $self->{error} = $error;
    $self->{state} = 'error';
    return $self;
}

sub CLONE_SKIP { 1 }

1;

__END__

=head1 NAME

Linux::Event::HTTP::Client::Operation - lifecycle of one high-level HTTP client operation

=head1 DESCRIPTION

A Client::Operation is the application-facing handle returned by
L<Linux::Event::HTTP::Client>. It normally contains one
L<Linux::Event::HTTP::Transaction>, and can contain more when redirects are
followed or authentication challenges are retried.

A Transaction still means exactly one Request/Response exchange. Redirect or
authentication retry therefore creates another Transaction rather than replacing
the Request or Response inside an existing Transaction.

For operations that need only one exchange, C<request>, C<response>,
C<request_body>, C<cancel>, and the terminal-state predicates provide the same
convenient high-level access to that Transaction.

=head1 METHODS

=head2 transaction

Returns the current or final Transaction.

=head2 transactions

Returns the Transactions in exchange order.

=head2 transaction_count

Returns the number of Transactions created by this operation, including
redirect and authentication-retry exchanges.

=head2 initial_url

Returns the absolute URL supplied for the first exchange.

=head2 url

Returns the current or final absolute URL.

=head2 urls

Returns the absolute URL associated with each Transaction in exchange order.
Authentication retries therefore repeat the same URL.

=head2 redirect_count

Returns the number of followed redirects. Authentication retries do not
increment this count.

=head2 auth_retry_count

Returns the number of automatic 401/407 authentication retries performed by the
operation.

=head2 max_redirects

Returns the redirect limit selected for this operation.

=head2 max_auth_retries

Returns the authentication retry limit selected for this operation.

=head2 request

Returns the Request for the current or final Transaction.

=head2 response

Returns the Response for the current or final Transaction, or undef before a
Response exists.

=head2 request_body

Delegates to the current Transaction's outgoing Request body producer. This
keeps the ordinary streaming-upload form concise while leaving producer
ownership on Transaction.

=head2 cancel

Cancels the active Transaction, if any, and marks the overall client operation
cancelled.

=head2 state

Returns C<pending>, C<active>, C<complete>, C<cancelled>, or C<error>.

=head2 is_complete, is_cancelled, is_terminal

Report operation lifecycle state.

=head2 error

Returns the terminal operation error, if any.

=cut
