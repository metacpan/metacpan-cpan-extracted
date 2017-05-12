# NAME

    Log::Log4perl::Appender::Raven - Append log events to your Sentry account.

# BUILD STATUS

<div>
    <a href="https://travis-ci.org/jeteve/l4p-appender-raven"><img src="https://travis-ci.org/jeteve/l4p-appender-raven.svg?branch=master"></a>
</div>

# WARNING(s)

This appender will send ALL the log events it receives to your
Sentry DSN synchronously. If you generate a log of logging, that can make your sentry account
saturate quite quickly and your application come to a severe slowdown.

Using Log4perl appender's Threshold or [Log::Log4perl::Filter](https://metacpan.org/pod/Log::Log4perl::Filter) in your log4perl config, and
experimenting a little bit is Highly Recommended.

Remember sentry is designed to record errors, so hopefully your application will
not generate too many of them.

You have been warned.

# SYNOPSIS

Read the [CONFIGURATION](https://metacpan.org/pod/CONFIGURATION) section, then use Log4perl just as usual.

If you are not familiar with Log::Log4perl, please check [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl)

In a nutshell, here's the minimul l4p config to output anything from ERROR to Sentry:

    log4perl.rootLogger=DEBUG, Raven

    log4perl.appender.Raven=Log::Log4perl::Appender::Raven
    log4perl.appender.Raven.Threshold=ERROR
    log4perl.appender.Raven.sentry_dsn="https://user:key@sentry-host.com/project_id"
    log4perl.appender.Raven.layout=Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Raven.layout.ConversionPattern=%X{chunk} %d %F{1} %L> %m %n

# CONFIGURATION

This is just another [Log::Log4perl::Appender](https://metacpan.org/pod/Log::Log4perl::Appender).

## Simple Configuration

The only mandatory configuration key
is \*sentry\_dsn\* which is your sentry dsn string obtained from your sentry account.
See http://www.getsentry.com/ and https://github.com/getsentry/sentry for more details.

Alternatively to setting this configuration key, you can set an environment variable SENTRY\_DSN
with the same setting. - Not recommended -

Example:

    log4perl.rootLogger=ERROR, Raven

    layout_class=Log::Log4perl::Layout::PatternLayout
    layout_pattern=%X{chunk} %d %F{1} %L> %m %n

    log4perl.appender.Raven=Log::Log4perl::Appender::Raven
    log4perl.appender.Raven.sentry_dsn="http://user:key@host.com/project_id"
    log4perl.appender.Raven.sentry_timeout=1
    log4perl.appender.Raven.layout=${layout_class}
    log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

## Timeout

The default timeout is 1 second. Feel free to bump it up. If sending an event
timesout (or if the sentry host is down or doesn't exist), a plain Perl
warning will be output.

## Configuration with Static Tags

You have the option of predefining a set of tags that will be send to
your Sentry installation with every event. Remember Sentry tags have a name
and a value (they are not just 'labels').

Example:

    ...
    log4perl.appender.Raven.tags.application=myproduct
    log4perl.appender.Raven.tags.installation=live
    ...

## Configure and use Dynamic Tagging

Dynamic tagging is performed using the Log4Perl MDC mechanism.
See [Log::Log4perl::MDC](https://metacpan.org/pod/Log::Log4perl::MDC) if you are not familiar with it.

Config (which MDC key to capture):

    ...
    log4perl.appender.Raven.mdc_tags=my_sentry_tags
    ...

Then anywhere in your code.

    ...
    Log::Log4perl::MDC->set('my_sentry_tags' , { subsystem => 'my_subsystem', ... });
    $log->error("Something very wrong");
    ...

Note that tags added this way will be added to the statically define ones, or override them in case
of conflict.

## Configure and use User Data

Sentry supports structured user data that can be added to your event.
User data works a bit like the tags, except only three keys are supported:

id, username and email. See [Sentry::Raven](https://metacpan.org/pod/Sentry::Raven) (capture\_user) for a description of those keys.

Config:

    ...
    log4perl.appender.Raven.mdc_user=my_sentry_user
    ...

Then in your code:

    ...
    Log::Log4perl::MDC->set('my_sentry_user' , { id => '123' , email => 'jeteve@cpan.org', username => 'jeteve' });
    $log->error("Something very wrong");
    ...

## Configure and use Dynamic Extra

Sentry allows you to specify any data (as a Single level HashRef) that will be stored with the Event.

It's very similar to dynamic tags, except its not tags.

Config (which MDC key to capture):

    ...
    log4perl.appender.Raven.mdc_extra=my_sentry_extra
    ...

Then anywere in your code:

    ...
    Log::Log4perl::MDC->set('my_sentry_extra' , { session_id => ... , ...  });
    $log->error("Something very wrong");
    ...

## Configuration with a Static Context.

You can use lines like:

    log4perl.appender.Raven.context.platform=myproduct

To define static [Sentry::Raven](https://metacpan.org/pod/Sentry::Raven) context. The list of context keys supported is not very
long, and most of them are defined dynamically when you use this package anyway.

See [Sentry::Raven](https://metacpan.org/pod/Sentry::Raven) for more details.

# AUTHOR

Jerome Eteve jeteve@cpan.com
