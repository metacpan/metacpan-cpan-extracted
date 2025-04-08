use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use t::TestPsgi;

sub clean {
    unlink 't/log4perl-user.log';
    unlink 't/log4perl.log';
}

sub generateLogs {
    my ($level) = @_;
    my $args = {
        logLevel         => $level,
        logger           => 'Lemonldap::NG::Common::Logger::Log4perl',
        userLogger       => 'Lemonldap::NG::Common::Logger::Log4perl',
        log4perlConfFile => 't/log4perl.ini',
    };

    my $psgi = new_ok( 't::TestPsgi' => [$args] );
    $psgi->init($args);
    $psgi->logger->error('Custom');
    $psgi->logger->debug('Custom');
    my $server = Plack::Test->create( $psgi->run );
    $server->request( GET "/" );
    my $res = '';
    foreach my $file (qw(t/log4perl.log t/log4perl-user.log)) {
        local $/ = undef;
        open my $f, '<', $file or die "$file: $!";
        $res .= <$f>;
        close $f;
    }
    return $res;
}

subtest "info mode" => sub {
    clean;
    my $logs = generateLogs('info');
    ok( $logs !~ /DEBUG/s, 'Found no debug logs' ) or diag $logs;
    ok( $logs =~ /INFO/s,  'Found info logs' )     or diag $logs;
};

clean;

done_testing();
