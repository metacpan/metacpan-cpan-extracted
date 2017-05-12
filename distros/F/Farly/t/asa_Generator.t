use strict;
use warnings;
use Test::More tests => 1;

use Farly;
use Farly::ASA::Generator;

my $generator = Farly::ASA::Generator->new();

my $ast = bless( {
                 'ID' => bless( {
                                  '__VALUE__' => bless( do{\(my $o = 'acl-outside')}, 'Farly::Value::String' ),
                                  'LINE' => bless( {
                                                     '__VALUE__' => bless( do{\(my $o = '1')}, 'Farly::Value::Integer' ),
                                                     'TYPE' => bless( {
                                                                        '__VALUE__' => bless( do{\(my $o = 'extended')}, 'Farly::Value::String' ),
                                                                        'ACTION' => bless( {
                                                                                             '__VALUE__' => bless( do{\(my $o = 'permit')}, 'Farly::Value::String' ),
                                                                                             'PROTOCOL' => bless( {
                                                                                                                    '__VALUE__' => bless( do{\(my $o = '6')}, 'Farly::Transport::Protocol' ),
                                                                                                                    'SRC_IP' => bless( {
                                                                                                                                         '__VALUE__' => bless( {
                                                                                                                                                                 'NETWORK' => Farly::IPv4::Address->new("0.0.0.0"),
                                                                                                                                                                 'MASK' => Farly::IPv4::Address->new("0.0.0.0")
                                                                                                                                                               }, 'Farly::IPv4::Network' ),
                                                                                                                                         'SRC_PORT' => bless( {
                                                                                                                                                                '__VALUE__' => bless( {
                                                                                                                                                                                        'LOW' => bless( do{\(my $o = '1024')}, 'Farly::Transport::Port' ),
                                                                                                                                                                                        'HIGH' => bless( do{\(my $o = '65535')}, 'Farly::Transport::Port' )
                                                                                                                                                                                      }, 'Farly::Transport::PortRange' ),
                                                                                                                                                                'DST_IP' => bless( {
                                                                                                                                                                                     'DST_PORT' => bless( {
                                                                                                                                                                                                            '__VALUE__' => bless( {
                                                                                                                                                                                                                                    'LOW' => bless( do{\(my $o = '1')}, 'Farly::Transport::Port' ),
                                                                                                                                                                                                                                    'HIGH' => bless( do{\(my $o = '1024')}, 'Farly::Transport::Port' )
                                                                                                                                                                                                                                  }, 'Farly::Transport::PortRange' )
                                                                                                                                                                                                          }, 'DST_PORT' ),
                                                                                                                                                                                     '__VALUE__' => bless( {
                                                                                                                                                                                                             'ID' => bless( do{\(my $o = 'citrix')}, 'Farly::Value::String' ),
                                                                                                                                                                                                             'ENTRY' => bless( do{\(my $o = 'GROUP')}, 'Farly::Value::String' )
                                                                                                                                                                                                           }, 'Farly::Object::Ref' )
                                                                                                                                                                                   }, 'DST_IP' )
                                                                                                                                                              }, 'SRC_PORT' )
                                                                                                                                       }, 'SRC_IP' )
                                                                                                                  }, 'PROTOCOL' )
                                                                                           }, 'ACTION' )
                                                                      }, 'TYPE' )
                                                   }, 'LINE' )
                                }, 'ID' )
               }, 'RULE' );

$generator->visit($ast);

#print $generator->container->[0]->dump;

my $dst = Farly::Object::Ref->new();
$dst->set('ENTRY' => Farly::Value::String->new('GROUP') );
$dst->set('ID' => Farly::Value::String->new('citrix') );

my $expected = Farly::Object->new();

$expected->set('ACTION',  Farly::Value::String->new('permit'));
$expected->set('DST_IP',  $dst ); 
$expected->set('DST_PORT',  Farly::Transport::PortRange->new('1 1024'));
$expected->set('ENTRY',  Farly::Value::String->new('RULE'));
$expected->set('ID',  Farly::Value::String->new('acl-outside'));
$expected->set('LINE',  Farly::Value::Integer->new(1) );
$expected->set('PROTOCOL',  Farly::Transport::Protocol->new('6'));
$expected->set('SRC_IP',  Farly::IPv4::Network->new('0.0.0.0 0.0.0.0'));
$expected->set('SRC_PORT',  Farly::Transport::PortRange->new('1024 65535'));
$expected->set('TYPE',  Farly::Value::String->new('extended'));

ok( $generator->container->[0]->equals( $expected), 'generator' );