#!perl
use File::Temp 0.20 qw(tempdir);
use Log::Any::Adapter 1.03;
use Log::Any::Adapter::Util qw(read_file);
use Log::Log4perl;
use Test::More;
use strict;
use warnings;

my $dir = tempdir( 'log-any-log4perl-XXXX', TMPDIR => 1, CLEANUP => 1 );
my $conf = "
log4perl.rootLogger                = WARN, Logfile
log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $dir/test.log
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = %C:%F:%L; %c; %p; %m%n
";
Log::Log4perl::init( \$conf );
Log::Any::Adapter->set('Log::Log4perl');

my @methods = ( Log::Any->logging_methods, Log::Any->logging_aliases );
push( @methods, ( map { $_ . "f" } @methods ) );

my $test_count =
  scalar(@methods) +
  scalar( Log::Any->detection_methods ) +
  scalar( Log::Any->detection_aliases );
plan tests => $test_count;

my $next_line;
foreach my $method (@methods) {
    my $log = Log::Any->get_logger( category => "category_$method" );
    $log->$method("logging with $method");
    $next_line = __LINE__;
}
my $log_line = $next_line - 1;
my $contents = read_file("$dir/test.log");
foreach my $method (@methods) {
    ( my $level = $method ) =~ s/f$//;
    for ($level) {
        s/^(notice|inform)$/info/;
        s/^(warning)$/warn/;
        s/^(err)$/error/;
        s/^(crit|critical|alert|emergency)$/fatal/;
    }
    if ( $level !~ /trace|debug|info|notice/ ) {
        $level = uc($level);
        like(
            $contents,
            qr/main:.*log4perl.t:$log_line; category_$method; $level; logging with $method\n/,
            "found $method"
        );
    }
    else {
        unlike( $contents, qr/logging with $method/, "did not find $method" );
    }
}
my $log = Log::Any->get_logger();
foreach my $method ( Log::Any->detection_methods, Log::Any->detection_aliases )
{
    if ( $method !~ /trace|debug|info|notice/ ) {
        ok( $log->$method, "$method" );
    }
    else {
        ok( !$log->$method, "!$method" );
    }
}
