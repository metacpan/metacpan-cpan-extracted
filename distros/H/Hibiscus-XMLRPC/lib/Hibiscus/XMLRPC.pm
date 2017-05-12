package Hibiscus::XMLRPC;
use strict;
use Moo 2; # or Moo::Lax if you can't have Moo v2
use Filter::signatures; # so the subroutine signatures work on Perls that don't support them
no warnings 'experimental::signatures';
use feature 'signatures';
use URI;
use XMLRPC::PurePerl;

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

Hibiscus::XMLRPC - talk to Hibiscus via XMLRPC

=head1 SYNOPSIS

    my $client = Hibiscus::XMLRPC->new(
        url => 'https://127.0.0.1:8080/xmlrpc/', # the default
        user     => $hbciuser,
        password => $hbcipass,
    );
    my $tr = $client->transactions()->get;
    for my $transaction (@$tr) {
        ...
    }

=cut

has 'ua' => (
    is => 'lazy',
    default => sub { require Future::HTTP; Future::HTTP->new },
);

has 'url' => (
    is => 'ro',
    default => sub { URI->new('https://127.0.0.1:8080/xmlrpc/') },
);

has 'user' => (
    is => 'rw',
);

has 'password' => (
    is => 'rw',
);

sub call($self,$method,@params) {
    my $payload = $self->encode_request($method,@params);

    my $url = $self->url;
    my( $userinfo ) = $url->userinfo || '';
    my( $user, $password ) = split /:/, $userinfo;
    $user ||= $self->user;
    $password ||= $self->password;
    $url->userinfo( "$user:$password" );

    $self->ua->http_post(
        $url,
        $payload,
        headers => {
            'Content-Type' => 'text/xml',
        },
    )->then(sub($body, $headers) {
        Future->done(
            $self->decode_result($body)
        );
    });
}

sub encode_request($self,$method,@params) {
    XMLRPC::PurePerl->encode_call_xmlrpc($method,@params)
}

sub decode_result($self,$body) {
    XMLRPC::PurePerl->decode_xmlrpc($body)
}

sub BUILDARGS($class, %options) {
    # Upgrade strings to URI::URL
    if( $options{ url } and not ref $options{ url }) {
        $options{ url } = URI->new( $options{ url } );
    };
    
    \%options
}

=head2 C<< ->transactions %filter >>

    my $transactions = $jameica->transactions(
        {
         "datum:min" => '2015-01-01', # or '01.01.2015'
         'datum:max' => '2015-12-31', # or '31.12.2015'
        }
    )->get;

Fetches all transactions that match the given filter and returns
them as an arrayref. If no filter is given, all transactions are returned.

The keys for each transaction are:

    {
      'konto_id' => '99',
      'betrag' => '-999,99',
      'gvcode' => '835',
      'zweck' => 'Zins   999,99 Tilg  999,99',
      'datum' => '2016-04-29',
      'customer_ref' => 'NONREF',
      'valuta' => '2016-04-30',
      'id' => '657',
      'umsatz_typ' => 'Kredit',
      'empfaenger_name' => 'IBAN ...',
      'saldo' => '99999.99'
    },

See L<https://www.willuhn.de/wiki/doku.php?id=develop:xmlrpc:umsatz>
for the list of allowed parameters.

=cut

sub transactions($self, %filter) {
    $self->call(
        'hibiscus.xmlrpc.umsatz.list',
        \%filter
    )
}

1;

__END__

=head1 INSTALLATION

=over 4

=item 1

Install Jameica and Hibiscus from
L<http://www.willuhn.de/products/hibiscus/>

=item 2

From within the application, install the
C<hibiscus.xmlrpc> plugin and all its prerequisites.
Restart after every prerequisite.

Yes. CPAN is much more convenient here.

=item 3

Under "File" -> "Preferences" (C<CTRL+E>), configure
C<hibiscus.xmlrpc.umsatz> to be enabled.

=item 4

Restart Jameica once more

=back

=head1 SEE ALSO

L<https://www.willuhn.de/wiki/doku.php?id=develop:xmlrpc>

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/hibiscus-xmlrpc>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hibiscus-XMLRPC>
or via mail to L<hibiscus-xmlrpc-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
