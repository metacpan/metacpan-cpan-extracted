$ENV{TEST_STF} ||= do {
    require Test::STF::MockServer;
    my $stf = Test::STF::MockServer->new();
    $HARRIET_GUARDS::STF = $stf;
    $stf->url;
}
