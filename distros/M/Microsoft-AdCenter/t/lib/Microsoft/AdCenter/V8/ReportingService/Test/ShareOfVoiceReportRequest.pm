package Microsoft::AdCenter::V8::ReportingService::Test::ShareOfVoiceReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::ShareOfVoiceReportRequest;

sub test_can_create_share_of_voice_report_request_and_set_all_fields : Test(6) {
    my $share_of_voice_report_request = Microsoft::AdCenter::V8::ReportingService::ShareOfVoiceReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($share_of_voice_report_request);

    is($share_of_voice_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($share_of_voice_report_request->Columns, 'columns', 'can get columns');
    is($share_of_voice_report_request->Filter, 'filter', 'can get filter');
    is($share_of_voice_report_request->Scope, 'scope', 'can get scope');
    is($share_of_voice_report_request->Time, 'time', 'can get time');
};

1;
