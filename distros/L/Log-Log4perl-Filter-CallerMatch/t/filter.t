# Tests for Log::Log4perl::Filter::CallerMatch

use warnings;
use strict;
use Test::More tests => 16;
use Log::Log4perl;
use Log::Log4perl::Filter::CallerMatch;

my $base_config = <<"END_CONFIG";
    log4perl.logger = ALL, A1
    log4perl.appender.A1        = Log::Log4perl::Appender::TestBuffer
    log4perl.appender.A1.Filter = MyFilter
    log4perl.appender.A1.layout = Log::Log4perl::Layout::SimpleLayout
END_CONFIG

# Defaults
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter    = Log::Log4perl::Filter::CallerMatch
END_CONFIG

    $logger->info('ok yes');
    like( $buffer->buffer(), qr/ok yes/, 'By default accept everything' );
    end($buffer);
}

# AcceptOnMatch
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = false
END_CONFIG

    $logger->info('umm no');
    like( $buffer->buffer(), qr//, 'AcceptOnMatch can filter out matches' );
    end($buffer);
}

# StringToMatch
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.StringToMatch  = curry
END_CONFIG

    $logger->info('curry');
    like( $buffer->buffer(), qr/curry/, 'StringToMatch found curry' );
    $buffer->buffer("");

    $logger->info('porridge');
    is( $buffer->buffer(), q{}, 'StringToMatch only found porridge' );
    end($buffer);
}

# PackageToMatch
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.StringToMatch  = curry
    log4perl.filter.MyFilter.PackageToMatch = main
END_CONFIG

    $logger->info('curry');
    like( $buffer->buffer(), qr/curry/, 'PackageToMatch found main' );
    end($buffer);

    ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.StringToMatch  = curry
    log4perl.filter.MyFilter.PackageToMatch = porridge
END_CONFIG

    $logger->info('curry');
    is( $buffer->buffer(), q{}, 'PackageToMatch only found porridge' );
    end($buffer);
}

# SubToMatch
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.StringToMatch  = curry
    log4perl.filter.MyFilter.PackageToMatch = main
    log4perl.filter.MyFilter.SubToMatch     = curry
END_CONFIG

    curry($logger);
    like( $buffer->buffer(), qr/curry/, 'SubToMatch found curry' );
    end($buffer);

    ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.StringToMatch  = curry
    log4perl.filter.MyFilter.PackageToMatch = main
    log4perl.filter.MyFilter.SubToMatch     = porridge
END_CONFIG

    $logger->info('curry');
    is( $buffer->buffer(), q{}, 'PackageToMatch only found porridge' );
    end($buffer);
}

# CallFrame
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.SubToMatch     = main::curry
    log4perl.filter.MyFilter.CallFrame      = 1
END_CONFIG

    curry($logger);
    like( $buffer->buffer(), qr/curry/, 'curry found at CallFrame 1' );
    end($buffer);

    ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.SubToMatch     = main::nested_curry
    log4perl.filter.MyFilter.CallFrame      = 2
END_CONFIG

    nested_curry($logger);
    is( $buffer->buffer(), q{}, 'nested_curry not found at CallFrame 2 when called directly' );
    $buffer->buffer("");

    nested_curry_outer($logger);
    like( $buffer->buffer(), qr/curry/, '..but found when called from outer sub' );
    end($buffer);
}

# Min/Max
{
    my ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.SubToMatch     = main::nested_curry
    log4perl.filter.MyFilter.MinCallFrame      = 3
    log4perl.filter.MyFilter.MaxCallFrame      = 4
END_CONFIG

    nested_curry_outer($logger);
    is( $buffer->buffer(), q{}, 'Nothing found when Min/Max Call Frame excludes target range' );
    end($buffer);

    ( $buffer, $logger ) = start(<<"END_CONFIG");
    log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.MyFilter.AcceptOnMatch  = true
    log4perl.filter.MyFilter.SubToMatch     = main::nested_curry
    log4perl.filter.MyFilter.MinCallFrame      = 0
    log4perl.filter.MyFilter.MaxCallFrame      = 2
END_CONFIG

    nested_curry_outer($logger);
    like( $buffer->buffer(), qr/curry/, '..but found when Min/Max includes target range' );
    end($buffer);
}

# With Bool
{
    my $config = <<END_CONFIG;
    log4perl.logger = ALL, A1
    log4perl.appender.A1        = Log::Log4perl::Appender::TestBuffer
    log4perl.appender.A1.Filter = f3
    log4perl.appender.A1.layout = Log::Log4perl::Layout::SimpleLayout

    log4perl.filter.f1 = Log::Log4perl::Filter::CallerMatch
    log4perl.filter.f1.StringToMatch  = curry

    log4perl.filter.f2 = Log::Log4perl::Filter::LevelRange
    log4perl.filter.f2.LevelMin  = WARN

    log4perl.filter.f3 = Log::Log4perl::Filter::Boolean
    log4perl.filter.f3.logic = f1 || f2
END_CONFIG

    Log::Log4perl->init( \$config );
    my $buffer = Log::Log4perl::Appender::TestBuffer->by_name("A1");
    my $logger = Log::Log4perl->get_logger("Some.Where");

    $logger->info('curry');
    like( $buffer->buffer(), qr/curry/, 'Bool did not block us' );
    $buffer->buffer("");

    $logger->warn('porridge');
    like( $buffer->buffer(), qr/porridge/, 'Got through via LevelRange' );
    $buffer->buffer("");

    $logger->debug('soup');
    is( $buffer->buffer(), q{}, 'Nothing got through' );
    end($buffer);
}

sub curry {
    my $logger = shift;
    $logger->info('curry');
}

sub nested_curry {
    my $logger = shift;
    $logger->info('curry');
}

sub nested_curry_outer {
    nested_curry(@_);
}

sub start {
    my $config = shift;
    $config = "$base_config \n $config";
    Log::Log4perl->init( \$config );
    my $buffer = Log::Log4perl::Appender::TestBuffer->by_name("A1");
    my $logger = Log::Log4perl->get_logger("Some.Where");
    return ( $buffer, $logger );
}

sub end {
    my $buffer = shift;
    Log::Log4perl->reset();
    $buffer->reset();
}
