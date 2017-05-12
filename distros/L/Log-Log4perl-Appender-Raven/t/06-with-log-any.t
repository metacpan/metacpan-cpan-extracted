#! perl -T
use strict;
use warnings;

package MyObject;
{
    use Moose;
    use Log::Any qw/$log/;
    sub do_stuff{
        $log->error("Some error via Log::Any");
    }
}
1;

package main;

use Carp;
use Data::Dumper;
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
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}
log4perl.appender.Raven.sentry_culprit_template={$function}-{$line}

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is good";

use Log::Any::Adapter;
Log::Any::Adapter->set('Log::Log4perl');

ok( my $ra = Log::Log4perl->appender_by_name('Raven') , "Ok got Raven appender");


# HACK Sentry::Raven so we capture capture_message
my $last_call;
my $call_count  = 0;
{
    no strict;
    no warnings;
    *{'Sentry::Raven::capture_message'} = sub{
        my ($self, $message ,  %context) = @_;
        # diag "MESSAGE: ".$message;
        # diag "CONTEXT: ".Dumper(\%context);
        $last_call = { message => $message , %context };
        $call_count++;
    };
    use strict;
    use warnings;
}


my $object = MyObject->new();
$object->do_stuff();

ok( $last_call , "Raven was used");
# The culprit is not directly the eval, but the caller of the eval.
is( $last_call->{culprit} , 'MyObject::do_stuff-10' );
$last_call = undef;


ok(1);
done_testing();
