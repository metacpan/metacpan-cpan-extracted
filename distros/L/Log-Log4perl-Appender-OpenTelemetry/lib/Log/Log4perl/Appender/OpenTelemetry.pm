use v5.42;
package Log::Log4perl::Appender::OpenTelemetry 0.001000;
# ABSTRACT: Send logs via OpenTelemetry

use OpenTelemetry qw( otel_logger_provider );
use OpenTelemetry::Constants qw(
    LOG_LEVEL_TRACE
    LOG_LEVEL_DEBUG
    LOG_LEVEL_INFO
    LOG_LEVEL_WARN
    LOG_LEVEL_ERROR
    LOG_LEVEL_FATAL
);
use Time::HiRes;

our @ISA = qw(Log::Log4perl::Appender);


sub new ($proto, %args) {
    my $class = ref $proto || $proto;

    bless {
        %args,
    }, $class;
}


sub log ($self, %params) {
    state %LOG2OTEL = (
        TRACE => LOG_LEVEL_TRACE,
        DEBUG => LOG_LEVEL_DEBUG,
        INFO  => LOG_LEVEL_INFO,
        WARN  => LOG_LEVEL_WARN,
        ERROR => LOG_LEVEL_ERROR,
        FATAL => LOG_LEVEL_FATAL,
    );

    my $level = $params{log4p_level};

    my $severity_number = 0+$LOG2OTEL{$level};

    otel_logger_provider->logger(name => $params{log4p_category})->emit_record(
        attributes      => {
            Log::Log4perl::MDC->get_context->%*,
        },
        timestamp       => Time::HiRes::time,
        severity_text   => $level,
        severity_number => $severity_number,
        body            => $params{message},
    );

    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Log4perl::Appender::OpenTelemetry - Send logs via OpenTelemetry

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

    use v5.42;
    use Log::Log4perl;

    # just to make our synopsis test no hang
    local $ENV{OTEL_SDK_DISABLED} = false;

    require OpenTelemetry::SDK;
    OpenTelemetry::SDK->import;

    # %x prefixes each log message with the NDC
    my $log4perl_config = q{
        log4perl.logger = DEBUG, OpenTelemetry
        log4perl.appender.OpenTelemetry = Log::Log4perl::Appender::OpenTelemetry
        log4perl.appender.OpenTelemetry.layout = PatternLayout
        log4perl.appender.OpenTelemetry.layout.ConversionPattern = %x %m{chomp}
    };

    Log::Log4perl::init(\$log4perl_config);

    my $log = Log::Log4perl->get_logger();

    $log->warn('this is my message');

=head1 DESCRIPTION

This L<Log::Log4perl::Appender> gets a L<OpenTelemetry::Logs::LoggerProvider>, gets a logger via
L<OpenTelemetry::Logs::LoggerProvider/logger> and calls L<OpenTelemetry::Logs::Logger/emit_record>.

=head1 METHODS

=head2 log

See L<Log::Log4perl::Appender/log>.

=head1 AUTHOR

Alexander Hartmaier <alex@hartmaier.priv.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
