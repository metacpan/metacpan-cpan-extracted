package Microsoft::AdCenter::V7::ReportingService::Test::AccountReportScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::AccountReportScope;

sub test_can_create_account_report_scope_and_set_all_fields : Test(2) {
    my $account_report_scope = Microsoft::AdCenter::V7::ReportingService::AccountReportScope->new
        ->AccountIds('account ids')
    ;

    ok($account_report_scope);

    is($account_report_scope->AccountIds, 'account ids', 'can get account ids');
};

1;
