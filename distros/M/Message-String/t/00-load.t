use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper::Concise;
use Capture::Tiny ':all';

BEGIN {
    use_ok( 'Message::String', MSG001     => 'Test message %s.' );
    use_ok( 'Message::String', 'MSG002:N' => 'Test message %s.' );

    # Geez, this done properly would be handy if it was in Test::Deep :(
    sub cmp_not_deeply
    {
        my ( $s1, $s2, $name ) = @_;
        my ( $identical ) = Test::Deep::cmp_details( $s1, $s2 );
        ok( !$identical, $name );
    }
}

BEGIN {

    package Foo;
    use Message::String EXPORT    => INF003 => 'Info message %s.';
    use Message::String EXPORT_OK => INF004 => 'Info message 4.';
    use Message::String ':TAG'    => INF005 => 'Info message 5.',
        INF006                    => 'Info message 6.';
    use Message::String EXPORT => I_007       => 'Info message 7.';
    use Message::String EXPORT => FOO_008_I   => 'Info message 8.';
    use Message::String EXPORT => FOO_009_INF => 'Info message 9.';
    use Message::String EXPORT => XXX         => 'message 10.';
    use Message::String EXPORT => R_011       => 'message 11.';
    use Message::String EXPORT => I_012       => 'message 12 %s.';
}

BEGIN {
    Foo->import();
    Foo->import( 'INF004' );
    Foo->import( ':TAG' );
}

# Give the types system a damn good thrashing
{
    my $result = message->_initial_types;
    is( $result, 'ACDEIMNRW', '_initial_types' );
}

{
    my $result = [ message->_initial_types ];
    is_deeply( $result, [qw/A C D E I M N R W/], '_initial_types' );
}

{
    # INSTANCE->_types same as CLASS->_types initially
    my $class_types    = message->_types;
    my $instance_types = MSG001->_types;
    is( $instance_types, $class_types, '_types' );

    # Until they're copied for write
    $instance_types = MSG001->_types( 1 );
    isnt( $instance_types, $class_types, '_types' );

    # And once copied, that's the instance world view
    my $copied_types = $instance_types;
    $instance_types = MSG001->_types;
    is( $instance_types, $copied_types, '_types' );

    # Until the instance is reset
    MSG001->_reset;
    $class_types    = message->_types;
    $instance_types = MSG001->_types;
    is( $instance_types, $class_types, '_types' );

    # Copied again, let's confirm they're identical in every way
    $class_types    = message->_types;
    $instance_types = MSG001->_types( 1 );
    cmp_deeply( $class_types, $instance_types, '_types' );

    # Set the default level for Type M to 100
    message->_type_level( 'M', 100 );
    # And make sure the class and instance structures differ
    cmp_not_deeply( $class_types, $instance_types, '_types' );
    # Now reset the types structure to its private backup
    message->_reset;
    # And make sure we're back to normal
    $class_types = message->_types;
    cmp_deeply( $class_types, $instance_types, '_types' );
}

{
    my $result = [ message->_message_types ];
    is_deeply( $result, [qw/A C D E I M N R W/], '_message_types' );
}

{
    is( message->_type_level(),        undef, '_type_level' );
    is( message->_type_level( undef ), undef, '_type_level' );
    is( message->_type_level( 'X' ),   undef, '_type_level' );
    message->_type_level( 'M', '0E0' );
    is( message->_type_level( 'M' ), 6, '_type_level' );
}

{
    # Instance changes level of a class of message
    my $level = MSG001->_type_level( 'M' );
    is( $level, 6, '_type_level' );
    MSG001->_type_level( 'M', 20 );
    # Did it work?
    is( MSG001->_type_level( 'M' ), 20, '_type_level' );
    # Did it set the instance level, too?
    is( MSG001->level, 20, '_type_level' );
    # Make sure we can make global change to ACEW messages
    message->_type_level( 'A', 100 );
    is( message->_type_level( 'A' ), 1, '_type_level' );
    message->_type_level( 'C', 100 );
    is( message->_type_level( 'C' ), 2, '_type_level' );
    message->_type_level( 'E', 100 );
    is( message->_type_level( 'E' ), 3, '_type_level' );
    message->_type_level( 'W', 100 );
    is( message->_type_level( 'W' ), 4, '_type_level' );
}

{
    is( message->_type_id(),        undef, '_type_id' );
    is( message->_type_id( undef ), undef, '_type_id' );
    is( message->_type_id( 'X' ),   undef, '_type_id' );
    # Embed message id in Type M messages
    message->_type_id( 'M', 1 );
    is( message->_type_id( 'M' ), 1, '_type_id' );
    # Don't embed message id in any type of message
    message->_type_id( 0 );
    is( message->_type_id( 'A' ), '', '_type_id' );
    is( message->_type_id( 'C' ), '', '_type_id' );
    is( message->_type_id( 'E' ), '', '_type_id' );
    is( message->_type_id( 'W' ), '', '_type_id' );
    is( message->_type_id( 'N' ), '', '_type_id' );
    is( message->_type_id( 'I' ), '', '_type_id' );
    is( message->_type_id( 'D' ), '', '_type_id' );
    is( message->_type_id( 'R' ), '', '_type_id' );
    is( message->_type_id( 'M' ), '', '_type_id' );
    # Don't embed message id in any type of message
    message->_type_id( '' );
    is( message->_type_id( 'A' ), '', '_type_id' );
    is( message->_type_id( 'C' ), '', '_type_id' );
    is( message->_type_id( 'E' ), '', '_type_id' );
    is( message->_type_id( 'W' ), '', '_type_id' );
    is( message->_type_id( 'N' ), '', '_type_id' );
    is( message->_type_id( 'I' ), '', '_type_id' );
    is( message->_type_id( 'D' ), '', '_type_id' );
    is( message->_type_id( 'R' ), '', '_type_id' );
    is( message->_type_id( 'M' ), '', '_type_id' );
    # Embed message id in all types of message
    message->_type_id( 1 );
    is( message->_type_id( 'A' ), 1, '_type_id' );
    is( message->_type_id( 'C' ), 1, '_type_id' );
    is( message->_type_id( 'E' ), 1, '_type_id' );
    is( message->_type_id( 'W' ), 1, '_type_id' );
    is( message->_type_id( 'N' ), 1, '_type_id' );
    is( message->_type_id( 'I' ), 1, '_type_id' );
    is( message->_type_id( 'D' ), 1, '_type_id' );
    is( message->_type_id( 'R' ), 1, '_type_id' );
    is( message->_type_id( 'M' ), 1, '_type_id' );
}

{
    is( message->_type_timestamp(),        undef, '_type_timestamp' );
    is( message->_type_timestamp( undef ), undef, '_type_timestamp' );
    is( message->_type_timestamp( 'X' ),   undef, '_type_timestamp' );
    is( message->_type_timestamp( 'A' ),   0,     '_type_timestamp' );
    message->_type_timestamp( 'A', 1 );
    is( message->_type_timestamp( 'A' ), 1, '_type_timestamp' );
    message->_type_timestamp( 'A', '' );
    is( message->_type_timestamp( 'A' ), '', '_type_timestamp' );
    message->_type_timestamp( 1 );
    is( message->_type_timestamp( 'C' ), 1, '_type_timestamp' );
    message->_type_timestamp( 0 );
    is( message->_type_timestamp( 'C' ), 0, '_type_timestamp' );
    message->_type_timestamp( '' );
    is( message->_type_timestamp( 'C' ), '', '_type_timestamp' );
}

{
    is( message->_type_tlc(),        undef, '_type_tlc' );
    is( message->_type_tlc( undef ), undef, '_type_tlc' );
    is( message->_type_tlc( 'X' ),   undef, '_type_tlc' );
    is( message->_type_tlc( 'A' ),   '',    '_type_tlc' );
    message->_type_tlc( 'A', 'YYZ' );
    is( message->_type_tlc( 'A' ), 'YYZ', '_type_tlc' );
    message->_type_tlc( 'A', 'ALTYYZ' );
    is( message->_type_tlc( 'A' ), 'ALT', '_type_tlc' );
}

{
    my @x = message->_type_aliases();
    is_deeply( \@x, [], '_type_aliases' );
    is( message->_type_aliases(),        undef, '_type_aliases' );
    is( message->_type_aliases( undef ), undef, '_type_aliases' );
    is( message->_type_aliases( 'X' ),   undef, '_type_aliases' );
    my $aliases = message->_type_aliases( 'A' );
    message->_type_aliases( 'A', undef );
    is_deeply(
        [ message->_type_aliases( 'A' ) ], [],
        '_type_aliases' );
    message->_type_aliases( 'A', 'AFOO' );
    is_deeply(
        [ message->_type_aliases( 'A' ) ], ['AFOO'],
        '_type_aliases' );
    message->_type_aliases( 'A', [qw/ALT ALR ALERT/] );
    is_deeply(
        [ message->_type_aliases( 'A' ) ], [ 'ALT', 'ALR', 'ALERT' ],
        '_type_aliases' );
    my @array = message->_type_aliases( 'A' );
    is_deeply(
        \@array, [ 'ALT', 'ALR', 'ALERT' ],
        '_type_aliases' );
}

{
    message->_update_type_on_id_change( 1 );
    is( message->_update_type_on_id_change, 1,
        '_update_type_on_id_change' );
    message->_update_level_on_type_change( 1 );
    is( message->_update_level_on_type_change, 1,
        '_update_level_on_type_change' );
    is( message->_minimum_verbosity, 3, '_minimum_verbosity' );
    is( message->verbosity,          7, 'verbosity' );
    message->verbosity( '0E0' );
    is( message->verbosity, 7, 'verbosity' );
    message->verbosity( 7 );
    is( message->verbosity, 7, 'verbosity' );
    message->verbosity( 0 );
    is( message->verbosity, 3, 'verbosity' );
    message->verbosity( 'D' );
    is( message->verbosity, 7, 'verbosity' );
    message->verbosity( 'DIAGNOSTIC' );
    is( message->verbosity, 7, 'verbosity' );
}

{
    is( message->_default_timestamp_format, '%a %x %T',
        '_default_timestamp_format' );
    message->_default_timestamp_format( '' );
    is( message->_default_timestamp_format, '',
        '_default_timestamp_format' );
    message->_default_timestamp_format( '%a %x %T' );
    is( message->_default_timestamp_format, '%a %x %T',
        '_default_timestamp_format' );
}

{
    message->_reset;
    MSG001->_reset;
    message->_type_timestamp( 'M', 1 );
    message->_type_tlc( 'M', 'MSG' );
    message->_type_id( 'M', 1 );
    my ( $stdout ) = capture_stdout { MSG001( 'Foo' ); 1; };
    like(
        $stdout,
        qr/\A\w{3} \w{3} \d{1,2}, \d{4} \d{2}:\d{2}:\d{2} \*MSG\* MSG001 Test message Foo\.\n\z/s,
        'correct message issued with adornments'
    );
    message->_type_timestamp( 'M', '%a %x %T' );
    ( $stdout ) = capture_stdout { MSG001( 'Foo' ); 1; };
    like(
        $stdout,
        qr/\A\w{3} \w{3} \d{1,2}, \d{4} \d{2}:\d{2}:\d{2} \*MSG\* MSG001 Test message Foo\.\n\z/s,
        'correct message issued with adornments'
    );
    message->_type_timestamp( 'M', '' );
    ( $stdout ) = capture_stdout { MSG001( 'Foo' ); 1; };
    like(
        $stdout, qr/\A\*MSG\* MSG001 Test message Foo\.\n\z/s,
        'correct message issued with adornments' );
    my ( $stderr ) = capture_stderr { MSG002( 'Foo' ); 1; };
    like( $stderr, qr/\ATest message Foo\.\n\z/s,
          'correct message issued with adornments' );
    MSG002->level( 6 );
    is( MSG002->level, 6, 'level' );
    MSG002->level( 'M' );
    is( MSG002->level, 6, 'level' );
    MSG002->level( 'MESSAGE' );
    is( MSG002->level, 6, 'level' );
    MSG002->type( 'INFO' );
    is( MSG002->level,   6,                   'level' );
    is( MSG002->type,    'I',                 'type' );
    is( MSG002,          'Test message %s.',  'stringify' );
    is( MSG002( 'Foo' ), 'Test message Foo.', 'stringify' );
    MSG002->_rebless( foo => sub {'foo'} );
    is( MSG002->foo, 'foo', '_rebless' );
    ( $stdout ) = capture_stdout { INF003( 'Foo' ); 1; };
    like( $stdout, qr/\AInfo message Foo\.\n\z/s,
          'correct message issued' );
    ( $stdout ) = capture_stdout { INF004; 1; };
    like( $stdout, qr/\AInfo message 4.\n\z/s,
          'correct message issued' );
    ( $stdout ) = capture_stdout { INF005; 1; };
    like( $stdout, qr/\AInfo message 5.\n\z/s,
          'correct message issued' );
    like( INF006->to_string, qr/\AInfo message 6.\z/s,
          'to_string' );
    like( I_007->to_string, qr/\AInfo message 7.\z/s,
          'to_string' );
    like( FOO_008_I->to_string, qr/\AInfo message 8.\z/s,
          'to_string' );
    like( FOO_009_INF->to_string, qr/\AInfo message 9.\z/s,
          'to_string' );
    like( XXX->to_string, qr/\A\*MSG\* XXX message 10.\z/s,
          'to_string' );
    is( R_011->response, undef, 'response' );
    is( R_011->response('foo'), R_011, 'response' );
    is( I_012->to_string, 'message 12 %s.', 'to_string' );
}

done_testing;
