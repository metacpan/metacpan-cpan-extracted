$ENV{TEST_MYSQL} ||= do {
    require Test::mysqld;
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '', # no TCP socket
        }
    ) or die $Test::mysqld::errstr;
    $HARRIET_GUARDS::MYSQLD = $mysqld;
    $mysqld->dsn;
};

