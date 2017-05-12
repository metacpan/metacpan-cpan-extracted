use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Tie::Input::Insertable;
use Capture::Tiny ':all';
use Test::More;
use Data::Dumper::Concise;

# Loading nine types of message in all sorts of really funky ways just to
# test coverage on the import method -- it is kind of important :-)
BEGIN {
    use_ok( 'Message::String' );
    use_ok( 'message' );
    #<<<
    use_ok(
        'message',
        ALT_MESSAGE_001  => 'Alert.',
        EXPORT           => (),
        EXPORT           => ( CRT_MESSAGE_002 => 'Critical.' ),
        EXPORT           => (),
        EXPORT_OK        => ( ERR_MESSAGE_003 => 'Error.\n' ),
        EXPORT_OK        => (),
        ':TAG1'          => ( WRN_MESSAGE_004 => 'Warning.' ),
        ':TAG1'          => (),
        ':TAG1', ':TAG2' => ( NTC_MESSAGE_005 => 'Notice.' ),
        ':TAG1', ':TAG2' => (),
        ':TAG1,:TAG2'    => ( INF_MESSAGE_006 => 'Info.' ),
        ':TAG1,:TAG2'    => (),
        { DGN_MESSAGE_007 => 'Debug.\t' }, {},
        [ RSP_MESSAGE_008 => 'Password:\s' ], [],
    );
    #>>>
    use_ok( 'message', << 'EOF');
  
# Comment under a blank line
MSG_MESSAGE_009 Other type of
...             really, really long message.
+               With two lines.
RSP_ANOTHER_010 Another response.\r\a
EOF
}

my ( $stdout, $stderr, @result );
no warnings 'once';
tie *FAKE_STDIN, 'Tie::Input::Insertable', *STDIN;
*Message::String::INPUT_ORIGINAL = \*Message::String::INPUT;
*Message::String::INPUT          = \*FAKE_STDIN;

eval {
    message->import( sub {'Nonsense, should generate error'} );
};
like( $@, qr/C_EXPECT_HAREF_OR_KVPL/, "Caught 'C_EXPECT_HAREF_OR_KVPL'" );

eval { ALT_MESSAGE_001; 1 };
like( $@, qr/ALT_MESSAGE_001 Alert\./, "Caught 'ALT_MESSAGE_001 Alert.'" );

eval { CRT_MESSAGE_002; 1 };
like( $@, qr/CRT_MESSAGE_002 Critical\./,
      "Caught 'CRT_MESSAGE_002 Critical.'" );

eval { ERR_MESSAGE_003; 1 };
like( $@, qr/Error\./,
      "Caught 'Error.'" );

( $stderr ) = capture_stderr { WRN_MESSAGE_004; 1 };
like( $stderr && $stderr, qr/Warning\./, "Got 'Warning.' on stderr" );

( $stderr ) = capture_stderr { NTC_MESSAGE_005; 1 };
like( $stderr && $stderr, qr/Notice\./, "Got 'Notice.' on stderr" );

( $stdout ) = capture_stdout { INF_MESSAGE_006; 1 };
like( $stdout && $stdout, qr/Info\./, "Got 'Info.' on stdout" );

( $stdout ) = capture_stdout { DGN_MESSAGE_007; 1 };
like( $stdout && $stdout, qr/# Debug\./, "Got '# Debug .' on stdout" );

( $stdout ) = capture_stdout {
    print Message::String::INPUT "User Input\n";
    RSP_MESSAGE_008; 1;
};
like( $stdout && $stdout, qr/Password:/, "Got 'Password:' on stdout" );
like( RSP_MESSAGE_008->response, qr/User Input/,
      "Got 'User Input' on stdin" );

( $stdout ) = capture_stdout { MSG_MESSAGE_009; 1 };
like(
    $stdout && $stdout, qr/Other type of.*message.\nWith two lines/s,
    "Got 'Other type of message' on stdout" );

*Message::String::INPUT = \*Message::String::INPUT_ORIGINAL;

# Ok that basically gets us to 100% of statements, 90.6% of branches, 76.8%
# of conditionals, 95.1% aggregate on coverage tests.

done_testing;
