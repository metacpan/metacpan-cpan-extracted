#! perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal qw/dies_ok lives_ok/;
use Log::Log4perl;

{
    my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

    if( $ENV{SENTRY_DSN} ){
        lives_ok { Log::Log4perl::init(\$conf); } "Ok sentry_dsn is not in the config, but taken from the ENV";
    }else{
        dies_ok{ Log::Log4perl::init(\$conf);
                 Log::Log4perl->appender_by_name('Raven')->raven();
             } "Ok sentry_dsn is missing from the config";
    }
}


my $SENTRY_DSN = $ENV{SENTRY_DSN} || 'https://blabla:blabla@app.getsentry.com/some_id';

    my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.sentry_dsn="|.$SENTRY_DSN.q|"
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is goo";

ok( my $ra =  Log::Log4perl->appender_by_name('Raven') , "Ok got appender 'Raven'");
ok( $ra->raven() , "Ok got nested raven client");


package My::Shiny::Package;
use Carp;

my $LOGGER = Log::Log4perl->get_logger();
sub emit_error{
    my ($class, $number) = @_;
    eval{
        confess("Cannot do some stuff for this number $number");
    };
    if( my $err = $@ ){
        $LOGGER->error("Error in doing stuff: ".$err);
    }
    $class->and_another_one();
}

sub and_another_one{
    $LOGGER->error('Deeper error');
}

1;

package main;


my @sentry_calls = ();

# HACK Sentry::Raven so we capture capture_message
{
    no strict;
    no warnings;
    *{'Sentry::Raven::capture_message'} = sub{
        my ($self, $message ,  %args) = @_;
        push @sentry_calls , { message => $message , %args };
    };
    use warnings;
    use strict;
}

My::Shiny::Package->emit_error(1);

is( scalar(@sentry_calls) , 2 , "Ok two calls in sentry");
is( $sentry_calls[0]->{culprit}  , 'My::Shiny::Package::emit_error' );
is( $sentry_calls[1]->{culprit}  , 'My::Shiny::Package::and_another_one' );

My::Shiny::Package->emit_error(2);

is( scalar(@sentry_calls) , 4 , "Ok four calls in sentry");

$LOGGER = Log::Log4perl->get_logger();

$LOGGER->error("Error at main level");

ok(1);
done_testing();
