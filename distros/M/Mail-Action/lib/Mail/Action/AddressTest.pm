package Mail::Action::AddressTest;

use strict;
use warnings;

use base 'Test::Class';
use Test::More;

sub module { 'Mail::Action::Address::Base' };

sub startup :Test( startup => 2 )
{
    my $self   = shift;
    my $module = $self->module();

    use_ok( 'Mail::Action::Address' );
    use_ok( $module );
}

sub setup :Test( setup => 1 )
{
    my $self         = shift;
    my $module       = $self->module();
    $self->{address} = $module->new();

    isa_ok( $self->{address}, $module );
}

sub test_description :Test( 4 )
{
    my $self = shift;
    my $add  = $self->{address};

    can_ok( $add, 'description' );
    is( $add->description(), '',
    	'description() should be blank unless set in constructor' );

    $add->{description} = 'now set';
    is( $add->description(), 'now set',
	    '... or whatever is set in constructor' );

    $add->description( 'set here' );
    is( $add->description(), 'set here',
    	'... and should be able to set description' );
}

sub test_name :Test( 4 )
{
    my $self = shift;
    my $add  = $self->{address};

    can_ok( $add, 'name' );
    is( $add->name(), undef,
        'name() should be undef unless set in constructor' );

    $add->{name} = 'newname';
    is( $add->name(), 'newname', '... or whatever is set' );

    $add->name( '!my Name$ ' );
    is( $add->name(), 'myName',  '... or cleaned name, if mutator' );
}

sub test_process_time :Test( 8 )
{
    my $self = shift;
    my $add  = $self->{address};

    can_ok( $add, 'process_time' );

    is( $add->process_time( 100 ), 100,
        'process_time() should return raw seconds directly' );
    is( $add->process_time( '1d' ), 24 * 60 * 60,
                              '... processing days correctly' );
    is( $add->process_time( '2w' ), 2 * 7 * 24 * 60 * 60,
                              '... processing weeks correctly' );
    is( $add->process_time( '4h' ), 4 * 60 * 60,
                              '... processing hours correctly' );
    is( $add->process_time( '8m' ), 8 * 60,
                              '... processing minutes correctly' );
    is( $add->process_time( '16M' ), 16 * 30 * 24 * 60 * 60,
                              '... processing months correctly' );
    is( $add->process_time( '1M2w3d4h5m' ),
           30 * 24 * 60 * 60 +
        2 * 7 * 24 * 60 * 60 +
        3     * 24 * 60 * 60 +
        4     * 60 * 60 +
        5          * 60,     '... even in a nice list' );
}

sub test_expires :Test( 5 )
{
    my $self   = shift;
    my $add    = $self->{address};
    my $module = $self->module();

    can_ok( $add, 'expires' );
    is( $add->expires(), 0,
        'expires() should default to 0 unless set in constructor' );

    $add = $module->new( expires => 1003 );
    is( $add->expires(), 1003,
        'expires() should report expiration time from constructor' );

    my $expiration = time() + 100;
    $add->expires( 100 );

    ok( $add->expires() - $expiration < 10, '... and should set expiration' )
        or diag "Possible clock skew: (" . $add->expires() .
                ") [$expiration]\n";

    my $time = time() + 7 * 24 * 60 * 60;
    is( $add->expires( '7d' ), $time, '... parsing days correctly' );
}

package Mail::Action::Address::Base;

BEGIN { $INC{'Mail/Action/Address/Base.pm'} = 1 }

use Mail::Action::Address;

use Class::Roles
    does => 'address_expires',
    does => 'address_named',
    does => 'address_described';

sub new
{
    my ($class, %args) = @_;
    bless \%args, $class;
}

1;
