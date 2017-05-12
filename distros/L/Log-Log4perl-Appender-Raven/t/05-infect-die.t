#! perl -T
use strict;
use warnings;

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
log4perl.appender.Raven.infect_die=1
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}
log4perl.appender.Raven.sentry_culprit_template={$function}-{$line}

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is good";

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


eval{
    no_existant_function();
};

ok( $last_call , "Raven was used");
# The culprit is not directly the eval, but the caller of the eval.
is( $last_call->{culprit} , 'main-53' );

$last_call = undef;


sub die_horribly{ die "I died horribly"; }
eval{
    die_horribly();
};

ok( $last_call , "Raven was used");
is( $last_call->{culprit} , 'main::die_horribly-63' );

$last_call = undef;

sub do_confess{ confess("Some confession"); };

eval{
    do_confess();
};

ok( $last_call , "Raven was used");
is( $last_call->{culprit} , 'main::do_confess-73' );

$last_call = undef;


sub eval_wrapper{
    eval{
        eval{
            simply_not_there();
        };
    };
}

eval{
    eval_wrapper();
};

ok( $last_call , "Raven was used");
is( $last_call->{culprit} , 'main::eval_wrapper-86' );
$last_call = undef;
$call_count = 0;


my $LOGGER = Log::Log4perl->get_logger();
eval{
    $LOGGER->logdie("Do'h");
};
ok( $last_call , "Raven was used");
is( $last_call->{culprit} , 'main-105' );
is( $call_count , 1 , "Raven send message called only once, not two times (the sig DIE one is avoided)");
$last_call = undef;

ok(1);
done_testing();
