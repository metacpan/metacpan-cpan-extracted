#! perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal qw/dies_ok lives_ok/;
use Log::Log4perl;
use Log::Log4perl::MDC;

my $SENTRY_DSN = $ENV{SENTRY_DSN} || 'https://blabla:blabla@app.getsentry.com/some_id';

    my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.sentry_dsn="|.$SENTRY_DSN.q|"
log4perl.appender.Raven.context.platform=my-perl
log4perl.appender.Raven.tags.application=my-application
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is good";

ok( my $ra = Log::Log4perl->appender_by_name('Raven') , "Ok got Raven appender");
is( $ra->raven->context()->{platform} , 'my-perl'  , "Ok good platform context");
is( $ra->raven->context()->{tags}->{application}  , 'my-application' , "Ok good application tag in global context");



# HACK Sentry::Raven so we capture capture_message
my $last_call;
{
    no strict;
    no warnings;
    *{'Sentry::Raven::capture_message'} = sub{
        my ($self, $message ,  %context) = @_;
        $last_call = { message => $message , %context };
    };
    use strict;
    use warnings;
}


my $LOGGER = Log::Log4perl->get_logger();

Log::Log4perl::MDC->put('sentry_tags' , { subsystem => 'testing' });
Log::Log4perl::MDC->put('sentry_user' , { id => 123  });
Log::Log4perl::MDC->put('sentry_extra' , { session => { user_id => 'something' , request => 'blabla' } , my_own_log_id => 'foobar'  });
Log::Log4perl::MDC->put('sentry_http' , { url => 'http://www.example.com/' , method => 'GET'  } );

$LOGGER->error("Some shiny error");


ok($last_call, "Last call was recorded");
is($last_call->{tags}->{subsystem} , 'testing' , "Ok tag about testing subsystem is there");
is($last_call->{extra}->{session}->{user_id} , "something");
is($last_call->{'sentry.interfaces.User'}->{id} , 123 );
is($last_call->{'sentry.interfaces.Http'}->{method} , 'GET' );

# use Data::Dumper;
# diag(Dumper($last_call));

ok(1);
done_testing();
