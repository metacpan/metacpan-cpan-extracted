#!/usr/bin/perl -w

# $Id: 05a-email-report.t,v 1.2 2003/09/05 19:33:40 m_ilya Exp $

# Unit tests for HTTP::WebTest::ReportPlugin (email sending functionality)

use strict;

use Test::More tests => 41;
use Test::MockObject;

my $WEBTEST;
my $SMTP;
my %GLOBAL_PARAMS;
my $REPORT_PLUGIN;
{
    $WEBTEST = Test::MockObject->new;
    $WEBTEST->mock(global_test_param =>
                   sub {
                       my($self, $param, $default) = @_;
                       return $GLOBAL_PARAMS{$param}
                           if exists $GLOBAL_PARAMS{$param};
                       return $default;
                   });

    $SMTP = Test::MockObject->new;
    Test::MockObject->fake_module('Net::SMTP',
                                  new => sub { $SMTP }
                                 );

    require_ok('HTTP::WebTest::ReportPlugin');

    $REPORT_PLUGIN = HTTP::WebTest::ReportPlugin->new($WEBTEST);
    isa_ok($REPORT_PLUGIN, 'HTTP::WebTest::ReportPlugin');
}

{
    ok(!$REPORT_PLUGIN->_email_report_is_expected(),
       "'mail' param is not set - do not send email report");

    $GLOBAL_PARAMS{mail} = 'all';
    $WEBTEST->set_series(have_succeed => 0, 1);
    ok($REPORT_PLUGIN->_email_report_is_expected(),
       "'mail' param is 'all' - always send email report");
    ok($REPORT_PLUGIN->_email_report_is_expected(),
       "'mail' param is 'all' - always send email report");

    $GLOBAL_PARAMS{mail} = 'errors';
    $WEBTEST->set_series(have_succeed => 1, 0);
    ok(!$REPORT_PLUGIN->_email_report_is_expected(),
       "'mail' param is 'errors' - only send email report if failed tests");
    ok($REPORT_PLUGIN->_email_report_is_expected(),
       "'mail' param is 'errors' - only send email report if failed tests");
}

{
    $SMTP->set_true('mail');
    $SMTP->set_true('to');
    $SMTP->set_true('data');
    $SMTP->set_true('datasend');
    $SMTP->set_true('dataend');
    $SMTP->set_true('quit');
    $WEBTEST->set_always(num_fail => 0);
    $WEBTEST->set_always(num_succeed => 0);
    $WEBTEST->set_always(have_succeed => 1);
    $GLOBAL_PARAMS{mail_addresses} = ['x@y.z'];
    $SMTP->clear;
    $REPORT_PLUGIN->test_output(\'TEST OUTPUT');
    $REPORT_PLUGIN->_send_email_report;
    my $from = getlogin() || getpwuid($<) || 'nobody';
    $SMTP->called_pos_ok(1, 'mail', 'Test for MAIL FROM command');
    $SMTP->called_args_pos_is(1, 2, $from,
                         'Test for content of MAIL FROM command');
    $SMTP->called_pos_ok(2, 'to', 'Test for RCPT TO command');
    $SMTP->called_args_pos_is(2, 2, 'x@y.z',
                         'Test for content of RCPT TO command');
    $SMTP->called_pos_ok(3, 'data', 'Test for DATA command');
    $SMTP->called_pos_ok(4, 'datasend', 'Test for From: header');
    $SMTP->called_args_pos_is(4, 2, "From: $from\n",
                         'Test for default From: header');
    $SMTP->called_pos_ok(5, 'datasend', 'Test for To: header');
    $SMTP->called_args_pos_is(5, 2, "To: x\@y.z\n");
    $SMTP->called_pos_ok(6, 'datasend', 'Test for Subject: header');
    $SMTP->called_args_pos_is(6, 2, "Subject: Web tests succeeded\n",
                              'Test for default success subject');
    $SMTP->called_pos_ok(7, 'datasend', 'Test for headers/body separator');
    $SMTP->called_args_pos_is(7, 2, "\n");
    $SMTP->called_pos_ok(8, 'datasend', 'Test for test report itself');
    $SMTP->called_args_pos_is(8, 2, 'TEST OUTPUT');
    $SMTP->called_pos_ok(9, 'dataend', 'End email');
    $SMTP->called_pos_ok(10, 'quit', 'Disconnect from SMTP server');

    $WEBTEST->set_always(have_succeed => 0);
    $SMTP->clear;
    $REPORT_PLUGIN->_send_email_report;
    $SMTP->called_pos_ok(6, 'datasend', 'Test for Subject: header');
    $SMTP->called_args_pos_is(6, 2,
                              "Subject: WEB TESTS FAILED! FOUND 0 ERROR(S)\n",
                              'Test for default failure subject');

    $WEBTEST->set_always(num_fail => 2);
    $WEBTEST->set_always(num_succeed => 3);
    $WEBTEST->set_always(have_succeed => 1);
    $SMTP->clear;
    $GLOBAL_PARAMS{mail_success_subject} = 'OK - %% %f + %s = %t';
    $REPORT_PLUGIN->_send_email_report;
    $SMTP->called_pos_ok(6, 'datasend', 'Test for Subject: header');
    $SMTP->called_args_pos_is(6, 2,
                              "Subject: OK - % 2 + 3 = 5\n",
                              'Test for customized success subject');

    $WEBTEST->set_always(num_fail => 5);
    $WEBTEST->set_always(num_succeed => 6);
    $WEBTEST->set_always(have_succeed => 0);
    $SMTP->clear;
    $GLOBAL_PARAMS{mail_failure_subject} = 'NOT OK - %% %f + %s = %t';
    $REPORT_PLUGIN->_send_email_report;
    $SMTP->called_pos_ok(6, 'datasend', 'Test for Subject: header');
    $SMTP->called_args_pos_is(6, 2,
                              "Subject: NOT OK - % 5 + 6 = 11\n",
                              'Test for customized failure subject');

    $SMTP->clear;
    $GLOBAL_PARAMS{mail_from} = '123456@example.com';
    $REPORT_PLUGIN->_send_email_report;
    $SMTP->called_pos_ok(4, 'datasend', 'Test for From: header');
    $SMTP->called_args_pos_is(4, 2, "From: 123456\@example.com\n",
                         'Test for non-default From: header');

    $SMTP->clear;
    $GLOBAL_PARAMS{mail_from} = '123456@example.com';
    $REPORT_PLUGIN->_send_email_report;
    $SMTP->called_pos_ok(1, 'mail', 'Test for MAIL FROM command');
    $SMTP->called_args_pos_is(1, 2, '123456@example.com',
                         'Test for content of MAIL FROM command');
    $SMTP->called_pos_ok(4, 'datasend', 'Test for From: header');
    $SMTP->called_args_pos_is(4, 2, "From: 123456\@example.com\n",
                         'Test for non-default From: header');

    $SMTP->clear;
    $GLOBAL_PARAMS{mail_addresses} = ['1@a.b', '2@c.d'];
    $REPORT_PLUGIN->_send_email_report;
    $SMTP->called_pos_ok(2, 'to', 'Test for RCPT TO command');
    $SMTP->called_args_pos_is(2, 2, '1@a.b',
                         'Test for content of RCPT TO command');
    $SMTP->called_args_pos_is(2, 3, '2@c.d',
                         'Test for content of RCPT TO command');
    $SMTP->called_pos_ok(5, 'datasend', 'Test for To: header');
    $SMTP->called_args_pos_is(5, 2, "To: 1\@a.b, 2\@c.d\n");
}
