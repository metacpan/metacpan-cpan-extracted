package Finance::Card::Discover;

use strict;
use warnings;

use Carp qw(croak);
use LWP::UserAgent;
use URI;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

sub new {
    my ($class, %params) = @_;

    croak q('username' and 'password' are required)
        unless $params{username} and $params{password};

    my $self = bless \%params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif ($self->{compress}) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    return $self;
}

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

sub response { $_[0]->{response} }

sub accounts {
    my ($self) = @_;

    my $data = $self->_request(
        msgnumber => -1,
        request    => 'getcards',
    );
    return unless $data and $data->{Total};

    require Finance::Card::Discover::Account;
    return map {
        Finance::Card::Discover::Account->new($data, $_, card => $self)
    } (1 .. $data->{Total});
}

sub _request {
    my ($self, @params) = @_;

    my $uri = URI->new('https://deskshop.discovercard.com/');
    $uri->path('/cardmembersvcs/orbiscom/WebServlet');

    # Non-standard url encoding- [.-] need escaping, perhaps others.
    (local $URI::uric = $URI::uric) =~ s/\\[.-]//g;
    $uri->query_form(
        version   => '1.0',
        startTime => 20 + int rand 100,
        user      => $self->{username},
        password  => $self->{password},
        @params,
    );

    my $res = $self->{response} = $self->ua->post($uri);
    return unless $res->is_success;

    # The response content is a url-encoded string.
    my %data = do {
        my $u = URI->new;
        $u->query($res->decoded_content);
        $u->query_form
    };
    return if not %data or 'error' eq $data{action};
    return \%data;
}


1;

__END__

=head1 NAME

Finance::Card::Discover - DiscoverCard account information and SOAN creation

=head1 SYNOPSIS

    use Finance::Card::Discover;

    my $card = Finance::Card::Discover->new(
        username => 'Your Username',
        password => 'Your Password',
    );

    for my $account ($card->accounts) {
        my $number     = $account->number;
        my $expiration = $account->expiration;
        printf "account: %s %s\n", $number, $expiration;

        my $balance = $account->balance;
        my $profile = $account->profile;

        my @transactions = $account->transactions;

        if (my $soan = $account->soan) {
            my $number = $soan->number;
            my $cid    = $soan->cid;
            printf "soan: %s %s\n", $number, $cid;
        }
        else {
            # SOAN request failed, see why.
            croak $account->card->response->dump;
        }

        for my $transaction ($account->soan_transactions) {
            my $date     = $transaction->date;
            my $merchant = $transaction->merchant;
            my $amount   = $transaction->amount;
            printf "transaction: %s %s %s\n", $date, $amount, $merchant;
        }
    }

=head1 DESCRIPTION

The C<Finance::Card::Discover> module provides access to DiscoverCard
account information and enables the creation of Secure Online Access
Numbers.

=head1 METHODS

=head2 new

    $card = Finance::Card::Discover->new(
        username => 'Your Username',
        password => 'Your Password',
    )

Creates a new C<Finance::Card::Discover> object.

=head2 accounts

Requests the accounts associated with the user and returns a list of
L<Finance::Card::Discover::Account> objects upon success.

=head2 response

    $response = $card->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $card->ua()
    $ua = $card->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<Finance::Card::Discover::Account>

L<http://www.discovercard.com/customer-service/security/create-soan.html>

=head1 TODO

=over

=item * Other intersting request types found in the Flash app that are worth
exploring:

=over

=item * activeaccounts

=item * cancelacc

=item * altercpn

=item * changepass

=back

=back

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Finance-Card-Discover>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Card::Discover

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/finance-card-discover>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Card-Discover>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Card-Discover>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Card-Discover>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Card-Discover/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
