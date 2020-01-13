package IO::EPP::Test::Server;

=encoding utf8

=head1 NAME

IO::EPP::Test::Server

=head1 SYNOPSIS

    use IO::EPP::Test::Server;

    my $s = new IO::EPP::Test::Server( $obj->{sock} ); # $obj->{sock} eq 'epp.example.com:700'

    # contacts
    my $conts = $s->data->{conts}
    # nameservers
    my $nss = $s->data->{nss};
    # domains
    my $doms = $s->data->{doms};

=head1 DESCRIPTION

For testing IO::EPP::Xxxx,
Provides storage of pseudo registries

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

#use Data::Dumper;

use strict;
use warnings;

no utf8; # !!!

=head1 Data storage format

Server is cache of data:

=over 3

=item *
first level  -- server as url:port

=item *
second level -- object type: contact, ns, domain, poll

=item *
third level  -- object data

=back

Examples of data:

Dump of contact

    'conts' => {
            'TEST-b123' => {
                             'statuses' => {
                                             'ok' => '+',
                                             'linked' => 2
                                           },
                             'int' => {
                                        'addr' => {
                                                    'pc' => '83000',
                                                    'cc' => 'UA',
                                                    'city' => 'Donetsk',
                                                    'street' => [
                                                                  'Vagnera 11-22-33'
                                                                ],
                                                    'sp' => 'Donetskaya'
                                                  },
                                        'name' => 'Test Testov'
                                      },
                             'updater' => 'test',
                             'creater' => 'test',
                             'id' => 'TEST-b123',
                             'authInfo' => 'Q2+qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
                             'email' => [
                                          'test0101@ya.ru'
                                        ],
                             'fax' => [],
                             'cre_date' => '2019-09-23T22:38:56.0Z',
                             'roid' => '0BC370A917642D744F69514FD4838029-TEST',
                             'owner' => 'test',
                             'reason' => 'in use',
                             'voice' => [
                                          '+380.987654321'
                                        ],
                             'upd_date' => '2019-09-23T22:38:56.0Z'
                           },
            },

Dump of nameserver

    'nss' => {
            'ns1.my.com' => {
                              'addr_v4' => [
                                             '11.22.33.44',
                                             '11.22.44.88'
                                           ],
                              'roid' => '873CAEF521E887055DC202BE0AC271F0-TEST',
                              'addr_v6' => [],
                              'avail' => 0,
                              'reason' => 'in use',
                              'creater' => 'test',
                              'statuses' => {
                                              'ok' => '+',
                                              'linked' => 1
                                            },
                              'owner' => 'test',
                              'cre_date' => '2019-09-23T22:46:33.0Z'
                            }
            },

Dump of domain

    'doms' => {
            'nssdom.best' => {
                               'upd_date' => '2019-09-23T22:54:12.0Z',
                               'create' => 'test',
                               'nss' => {
                                          'ns1.reg.com' => '+',
                                          'ns2.reg.com' => '+'
                                        },
                               'hosts' => {},
                               'exp_date' => '2020-09-23T22:54:12.0Z',
                               'cre_date' => '2019-09-23T22:54:12.0Z',
                               'trans_date' => '2019-09-23T22:54:12.0Z',
                               'billing' => [
                                              'TEST-b123'
                                            ],
                               'statuses' => {
                                               'ok' => '+'
                                             },
                               'tech' => [
                                           'TEST-t123'
                                         ],
                               'authInfo' => 'bfhRem884mfmf,FMd:fnnfe',
                               'avail' => 0,
                               'reason' => 'in use',
                               'owner' => 'test',
                               'registrant' => 'TEST-r123',
                               'admin' => [
                                            'TEST-a123'
                                          ],
                               'roid' => 'C3163119E2B3E038F41A60248A2B4214-TEST'
                             },
           },


=head1 DIRECT ACCESS TO DATA

An Example:

    my $srv_url = "$socket_data->{PeerHost}:$socket_data->{PeerPort}";
    # or $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $doms  = $s->data->{doms};

    # Set reg_id as admin_id
    $doms->{'nssdom.best'}{reg_id} = $doms->{admin_id}[0];

    # Add new ns
    push @{$doms->{'nssdom.best'}{nss}}, 'ns9.reg.com';

    $doms->{'new_busy_domain.com'} = { avail => 0, reason => 'in use' };

See IO::EPP::Test::Base also.

=cut

our $data;

sub new {
    my ( undef, $url ) = @_;

    $data = {} unless ref $data;

    unless ( $data->{$url} ) {
        $data->{$url} = { conts => {}, nss => {}, doms => {}, poll => [] };
    }

    my $s = { url => $url };

    return bless $s;
}

sub data {
    return $data->{$_[0]->{url}};
}


sub DESTROY {
    # for debug
    #print Dumper $_[0];
    #print Dumper $data;
}

1;
