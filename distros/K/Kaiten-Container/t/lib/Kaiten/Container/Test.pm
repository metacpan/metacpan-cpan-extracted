package Kaiten::Container::Test;

use v5.10;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Warn;

# for Sponge test
use DBI;

#======== DEVELOP THINGS ===========>
# develop mode
#use Smart::Comments;
#use Data::Printer;

#======== DEVELOP THINGS ===========<

use lib::abs qw(../../../../lib);

use Kaiten::Container;

my $configutarion_safe = {
    ralational => {
                    handler  => sub        { return 'FooSQL there!' },
                    probe    => sub        { return 1 },
                    settings => { reusable => 1 }
                  },
    ralational2 => {
                     handler  => sub        { return 'BarSQL there!' },
                     probe    => sub        { return 1 },
                     settings => { reusable => 1 }
                   },
    key_value => {
                   handler => sub { return 'NoSQL there! YAPPP!!!' },
                   probe   => sub { return 1 },
                 },

};

#<<<  do not let perltidy touch this
my $configutarion_explodable = {
                 explode => {
                              handler  => sub        { return 'ExplodeSQL there!' },
                              probe    => sub        { state $a= [ 1, 0, 0 ]; return shift @$a; },
                              settings => { reusable => 1 }
                            },
                 explode_now => { handler => sub { return 'ExplodeNowSQL there!' }, },
};
#>>>

# setup methods are run before every test method.
sub make_fixture : Test(setup) {
    my $self = shift;

    # its because we are have global vars, all go wrong if we not de-referenced it first. yap!
    my %init_config_safe       = %$configutarion_safe;
    my %init_config_explodable = %$configutarion_explodable;


    # new key to turn on DEBUG mode
    $self->{connection_storage_safe}       = Kaiten::Container->new( init => \%init_config_safe, DEBUG => 1 );
    $self->{connection_storage_explodable} = Kaiten::Container->new( init => \%init_config_explodable, DEBUG => 1 );

}

sub check_class : Test(1) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};
    isa_ok( $object, "Kaiten::Container" );
}

sub check_get_by_name_normal : Test(3) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    foreach ( keys %$configutarion_safe ) {
        is( $object->get_by_name($_), $configutarion_safe->{$_}{handler}->(), "handler $_ work correctly" );
    }

}

sub check_init_without_probe : Test(1) {
    my $self = shift;

    my $object = $self->{connection_storage_explodable};

    is( !eval { $object->get_by_name('explode_now') }, $@ && $@ =~ /\[probe\] sub not defined/, 'probe checked at init' );

}

sub check_reuse_normal : Test(1) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    warnings_are {
        eval { $object->get_by_name('ralational') } for ( 0 .. 3 );
    }
    [], "positive probe checked";

}

sub check_reuse_failed : Test(3) {
    my $self = shift;

    my $object = $self->{connection_storage_explodable};

    # nothing happened in first touch.
    warnings_are { $object->get_by_name('explode') }[], "no warnings in first touch";

    # and BOOM on second touch
    warning_like {
        eval { $object->get_by_name('explode') };
    }
    [ { carped => qr/try to create new one/i } ], 'negative probe on reuse checked';

    ok( $@ =~ /don`t pass \[probe\] check on create/, 'negative probe on creation checked' );

}

sub check_ExampleP_example : Test(4) {
    my $self = shift;

  SKIP: {

        skip 'No ExampleP DBD finded, strange...', 4 unless eval "require DBD::ExampleP";

    my $config = {
         examplep_config => {
            handler  => sub { { RaiseError => 1 } },
            probe    => sub { 1 },
            settings => { reusable => 1 },
         },
         examplep_dbd => {
            handler  => sub { "dbi:ExampleP:" },
            probe    => sub { 1 },
            settings => { reusable => 1 },      
         },
         ExampleP => {
             handler  => sub { 
                my $c = shift;
                my $dbd = $c->get_by_name('examplep_dbd');
                my $conf = $c->get_by_name('examplep_config');
                return DBI->connect( $dbd, "", "", $conf ) or die $DBI::errstr;
              },
             probe    => sub { shift->ping() },
             settings => { reusable => 1 }
         },
    };

        my $conn_storage = Kaiten::Container->new( init => $config, DEBUG => 1 );

        warnings_are { $conn_storage->get_by_name('ExampleP') }[], "no warnings in first touch ExampleP";

        warnings_are { $conn_storage->get_by_name('ExampleP') }[], "no warnings in second touch ExampleP";

        ok( !$@, 'no error defined at ExampleP' );
        
        ok( $conn_storage->get_by_name('ExampleP')->{RaiseError}, 'deep dependency worked properly');

    }

}

sub check_add_normal : Test(2) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    my $settings = {
                     handler  => sub        { return 'Hello world!' },
                     probe    => sub        { return 1 },
                     settings => { reusable => 1 }
                   };

    ok( eval { $object->add( 'ralational_new' => $settings ) }, "new handler added" );
    is( $object->get_by_name('ralational_new'), $settings->{handler}->(), "new handler working" );

}

sub check_add_exploidable : Test(4) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    my $settings = {
                     handler  => sub        { return 'Hello world!' },
                     probe    => sub        { return 1 },
                     settings => { reusable => 1 }
                   };

    ok( !eval { $object->add() }, 'empty add error checked' );

    ok( eval  { $object->add( 'ralational_new' => $settings ) }, "new handler added first ok" );
    ok( !eval { $object->add( 'ralational_new' => $settings ) }, "new handler added second time error checked" );
    ok( $@ =~ /handler \[.*?\] exists/, 'new handler added second time error message correct' );

}

sub check_remove_normal : Test(6) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    my $settings = {
                     handler  => sub        { return 'Hello world!' },
                     probe    => sub        { return 1 },
                     settings => { reusable => 1 }
                   };

    ok( eval { $object->add( 'remove_test1' => $settings, 'remove_test2' => $settings ) }, "new handler added" );
    is( $object->get_by_name('remove_test1'), $settings->{handler}->(), "new handler1 working" );
    is( $object->get_by_name('remove_test2'), $settings->{handler}->(), "new handler2 working" );
    ok( eval { $object->remove( 'remove_test1', 'remove_test2' ) }, "handlers removed" );
    ok( !eval { $object->get_by_name('remove_test1') }, 'handler1 remove checked' );
    ok( !eval { $object->get_by_name('remove_test2') }, 'handler2 remove checked' );
}

sub check_remove_exploidable : Test(3) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    ok( !eval { $object->remove() }, "empty remove error check" );

    ok( !eval { $object->remove( 'remove_test1', 'remove_test2' ) }, "not exists handlers removed error check" );

    ok( $@ =~ /handler \[.*?\] NOT exists/, 'not exists error message correct' );

}

sub check_show_list : Test(2) {
    my $self = shift;

    my $object = $self->{connection_storage_safe};

    my @handlers_list;
    my @test_list = sort keys %$configutarion_safe;

    ok( eval { @handlers_list = $object->show_list }, "show_list worked" );

    ok( @handlers_list ~~ @test_list, 'show_list worked correctly' );

}
1;
