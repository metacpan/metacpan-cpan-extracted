use strict;
use warnings;

package basic_test;

use Test::More qw(no_plan);
use utf8;

use ExtUtils::Scriptlet 'perl';

run();
exit;

sub ret($) { $_[0] > 0 ? $_[0] >> 8 : $_[0] }

sub run {

    is ret perl( "exit length qq[   ]" ), 3, "a simple scriptlet works";

    is eval { perl }, undef, 'code is required';

    my $os_newline = $^O eq "MSWin32" ? "\r\n" : "\n";
    is ret perl( "exit length qq[$os_newline]" ), length $os_newline, '\r in the code segment are handled correctly';

    isnt ret( eval { perl "exit 13", perl => "perl_does_not_exist" } || 1 ), 13, 'interpreter can be modified';

    my $code = 'local $/; exit length <STDIN>';
    is ret perl( $code, payload => "   " ), 3, "basic payload has the right length";

    is ret perl( $code, payload => $os_newline ), length $os_newline,
      "payload with os newlines has equal length on both sides";

    is ret perl( "$code", payload => " ä " ), 4, "payload is sent as utf8 by default";

    is ret perl( "$code", encoding => "iso-8859-15", payload => " ä " ), 3, "the payload encoding can be modified";

    is ret perl( "exit FOO", args => "-Mconstant=FOO,1" ), 1, "custom args are passed to the interpreter";

    isnt eval { perl( 'exit length $ARGV[0]', at_argv => "meep" ); 1 }, 1, "at_argv requires an array reference";

    is ret perl( 'exit length $ARGV[0]', at_argv => ["meep"] ), 4, "at_argv is passed correctly to the interpreter";

    is ret perl( 'exit length $ARGV[0]', argv => "meep" ), 4, "argv is passed correctly to the interpreter";

    isnt perl( $code, args => "-e die" ), 0, "close is protected against SIGPIPE";

    my $length = 15_000_000;
    is ret perl( "local \$/; exit if $length == length <STDIN>; die", payload => " " x $length ), 0,
      "big payloads are transmitted ok";

    return;
}
