package Mason::Tidy::t::CLI;
BEGIN {
  $Mason::Tidy::t::CLI::VERSION = '2.57';
}
use Capture::Tiny qw(capture capture_merged);
use File::Slurp;
use File::Temp qw(tempdir);
use Mason::Tidy;
use Mason::Tidy::App;
use IPC::System::Simple qw(capturex);
use Test::Class::Most parent => 'Test::Class';

local $ENV{MASONTIDY_OPT};

my @std_argv = ( "--perltidy-argv='--noprofile'", "-m=2" );

sub test_cli : Tests {
    my ( $out, $err );

    my $tempdir = tempdir( 'name-XXXX', TMPDIR => 1, CLEANUP => 1 );
    write_file( "$tempdir/comp1.mc", "<%2+2%>" );
    write_file( "$tempdir/comp2.mc", "<%4+4%>" );
    write_file( "$tempdir/comp3.mc", "%if (foo){\n%bar\n%}\n" );

    my $cli = sub {
        local @ARGV = @_;
        ( $out, $err ) = capture {
            Mason::Tidy::App->run();
        };
        is( $err, "", "err empty" );
    };

    $cli->( "-r", "$tempdir/comp1.mc", "$tempdir/comp2.mc", @std_argv );
    is( $out,                           "$tempdir/comp1.mc\n$tempdir/comp2.mc\n", "out empty" );
    is( read_file("$tempdir/comp1.mc"), "<% 2 + 2 %>",                            "comp1" );
    is( read_file("$tempdir/comp2.mc"), "<% 4 + 4 %>",                            "comp2" );

    write_file( "$tempdir/comp1.mc", "<%2+2%>" );
    $cli->( "$tempdir/comp1.mc", @std_argv );
    is( $out,                           "<% 2 + 2 %>", "single file - out" );
    is( read_file("$tempdir/comp1.mc"), "<%2+2%>",     "comp1" );

    $cli->( "$tempdir/comp3.mc", @std_argv );
    is( $out, "% if (foo) {\n%     bar\n% }\n", "no options" );
    $cli->( '--perltidy-line-argv="-i=2"', "$tempdir/comp3.mc", @std_argv );
    is( $out, "% if (foo) {\n%   bar\n% }\n", "no options" );

    throws_ok { $cli->("$tempdir/comp1.mc") } qr/mason-version required/;
    throws_ok { $cli->( "-m", "3", "$tempdir/comp1.mc" ) } qr/must be 1 or 2/;
    throws_ok { $cli->( "-p", "$tempdir/comp1.mc", @std_argv ) } qr/pipe not compatible/;
    throws_ok { $cli->(@std_argv) } qr/must pass either/;
    throws_ok { $cli->( "$tempdir/comp1.mc", "$tempdir/comp2.mc", @std_argv ) }
    qr/must pass .* with multiple filenames/;
}

sub test_pipe : Tests {
    return "author only" unless ( $ENV{AUTHOR_TESTING} );

    require IPC::Run3;
    local $ENV{MASONTIDY_OPT} = "-p";
    my $in = "<%2+2%>\n<%4+4%>\n";
    my ( $out, $err );
    IPC::Run3::run3( [ $^X, "bin/masontidy", @std_argv ], \$in, \$out, \$err );
    is( $err, "", "pipe - no error" );
    is( $out, "<% 2 + 2 %>\n<% 4 + 4 %>\n", "pipe - output" );
}

sub test_usage : Tests {
    my $out;

    return "author only" unless ( $ENV{AUTHOR_TESTING} );
    $out = capture_merged { system( $^X, "bin/masontidy", "-h" ) };
    like( $out, qr/Usage: masontidy/ );

    $out = capture_merged { system( $^X, "bin/masontidy", "--version" ) };
    like( $out, qr/masontidy .* on perl/ );

}

1;
