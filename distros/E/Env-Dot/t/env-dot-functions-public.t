#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;

use English qw( -no_match_vars );

use Test2::V1 qw( -utf8 -x );
use Test2::Tools::Subtest qw( subtest_streamed );

use Env::Dot::Functions ();

subtest_streamed 'Public Subroutine extract_error_msg()' => sub {
    {
        my $msg = 'A serious Error!';
        my ($err, $line, $filepath) = Env::Dot::Functions::extract_error_msg($msg);
        T2->is( $err, 'A serious Error', 'err matches' );
        T2->is( $line, undef, 'line matches' );
        T2->is( $filepath, undef, 'filepath matches' );
    }
    {
        my $msg= 'A serious Error! line 5';
        my ($err, $line, $filepath) = Env::Dot::Functions::extract_error_msg($msg);
        T2->is( $err, 'A serious Error', 'err matches' );
        T2->is( $line, 5, 'line matches' );
        T2->is( $filepath, undef, 'filepath matches' );
    }
    {
        my $msg= 'A serious Error! line 5 file \'/home/user/file.txt\'';
        my ($err, $line, $filepath) = Env::Dot::Functions::extract_error_msg($msg);
        T2->is( $err, 'A serious Error', 'err matches' );
        T2->is( $line, 5, 'line matches' );
        T2->is( $filepath, '/home/user/file.txt', 'filepath matches' );
    }
    {
        my $msg= q{An Error for some ser[*#¤%]! line 234 file 'rewr/fasd/=%/.txt'};
        my ($err, $line, $filepath) = Env::Dot::Functions::extract_error_msg($msg);
        T2->is( $err, 'An Error for some ser[*#¤%]', 'err matches' );
        T2->is( $line, 234, 'line matches' );
        T2->is( $filepath, 'rewr/fasd/=%/.txt', 'filepath matches' );
    }
    {
        my $msg= q{An Error for some ser[*#¤%]! line 234 file 'rewr/fasd/=%/.txt' at path/file line 123.};
        my ($err, $line, $filepath) = Env::Dot::Functions::extract_error_msg($msg);
        T2->is( $err, 'An Error for some ser[*#¤%]', 'err matches' );
        T2->is( $line, 234, 'line matches' );
        T2->is( $filepath, 'rewr/fasd/=%/.txt', 'filepath matches' );
    }
    {
        my ($err, $line, $filepath);
        T2->like(
            dies { Env::Dot::Functions::extract_error_msg($err, $line, $filepath) },
            qr{^ Parameter \s error: \s missing \s parameter \s 'msg' .* $}msx,
            'dies as planned',
        );
    }
    T2->done_testing;
};

subtest_streamed 'Public Subroutine create_error_msg()' => sub {
    {
        my ($err, $line, $filepath) = (q{A serious Error}, 5, q{/home/user/file.txt});
        my $msg = Env::Dot::Functions::create_error_msg($err, $line, $filepath);
        T2->is( $msg, q{A serious Error! line 5 file '/home/user/file.txt'}, 'msg matches');
    }
    {
        my ($err, $line, $filepath) = (q{A serious Error}, 5, undef);
        my $msg = Env::Dot::Functions::create_error_msg($err, $line, $filepath);
        T2->is( $msg, q{A serious Error! line 5}, 'msg matches');
    }
    {
        my ($err, $line, $filepath) = (q{A serious Error});
        my $msg = Env::Dot::Functions::create_error_msg($err, $line, $filepath);
        T2->is( $msg, q{A serious Error!}, 'msg matches');
    }
    {
        my ($err, $line, $filepath) = (q{A common error: 'file'});
        my $msg = Env::Dot::Functions::create_error_msg($err, $line, $filepath);
        T2->is( $msg, q{A common error: 'file'!}, 'msg matches');
    }
    {
        my ($err, $line, $filepath) = (q{A common error: 'file'}, 5, q{/root/.env});
        my $msg = Env::Dot::Functions::create_error_msg($err, $line, $filepath);
        T2->is( $msg, q{A common error: 'file'! line 5 file '/root/.env'}, 'msg matches');
    }
    {
        my ($err, $line, $filepath) = (q{A serious Error}, undef, q{/file/path});
        T2->like(
            dies { Env::Dot::Functions::create_error_msg($err, $line, $filepath) },
            qr{^ Parameter \s error: \s missing \s parameter \s 'line' .* $}msx,
            'dies as planned',
        );
    }
    {
        my ($err, $line, $filepath);
        T2->like(
            dies { Env::Dot::Functions::create_error_msg($err, $line, $filepath) },
            qr{^ Parameter \s error: \s missing \s parameter \s 'err' .* $}msx,
            'dies as planned',
        );
    }
    T2->done_testing;
};

T2->done_testing;
