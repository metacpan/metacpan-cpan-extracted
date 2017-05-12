#! perl -T

use strict;
use warnings;

use Test::More;

use Log::Log4perl::Appender::Raven;

ok( my $appender = Log::Log4perl::Appender::Raven->new({ sentry_dsn => 'http://blabla:secret@app.getsentry.com/project_id' }) , "Ok can build appender");
ok( $appender->raven() , "Ok can get the raven instance");


done_testing();
