use lib qw(./t/lib ./dist/lib ./lib);
use strict;
use warnings;
use Haineko::SMTPD::Milter;
use Test::More;

my $modulename = 'Haineko::SMTPD::Milter';
my $pkgmethods = [ 'import', 'libs', 'conn', 'ehlo', 'mail', 'rcpt', 'head', 'body' ];

can_ok( $modulename, @$pkgmethods );

METHODS: {

    my $x = Haineko::SMTPD::Milter->libs( [ '/tmp', '/var/tmp', './t' ] );
    is $x, 3, '->libs => 3';

    $x = Haineko::SMTPD::Milter->libs(1); is $x, 0;
    $x = Haineko::SMTPD::Milter->libs('.'); is $x, 0;

    my $y = Haineko::SMTPD::Milter->import( [ 'Example' ] );
    is $y->[0], 'Haineko::SMTPD::Milter::Example', '->import => [ Haineko::SMTPD::Milter::Example ]';

    $y = Haineko::SMTPD::Milter->import(1);
    is $y, 0;

    for my $e ( @$pkgmethods ){
        next if $e eq 'import' || $e eq 'libs';
        is( Haineko::SMTPD::Milter->$e, 1, '->'.$e.' => 1 ' );
    }
}

done_testing;

