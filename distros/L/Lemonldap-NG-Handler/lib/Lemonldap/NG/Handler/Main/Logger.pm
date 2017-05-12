package Lemonldap::NG::Handler::Main::Logger;

use Lemonldap::NG::Handler::API qw( :httpCodes );

my $logLevel;    # To control Lemonldap::NG logs: allows to overwrite
                 # log level defined in server config, or to set it
                 # if it can't be configured elsewhere (e.g. on CGIs)
my $logLevels = {    # To compare log levels
    emerg  => 7,
    alert  => 6,
    crit   => 5,
    error  => 4,
    warn   => 3,
    notice => 2,
    info   => 1,
    debug  => 0,
};

BEGIN {
    Lemonldap::NG::Handler::API->thread_share($logLevel);
    Lemonldap::NG::Handler::API->thread_share($logLevels);
}

# @method void logLevelInit
# Set log level for Lemonldap::NG logs
sub logLevelInit {
    my ( $class, $level ) = @_;
    $logLevel = $level || $Lemonldap::NG::Handler::API::logLevel || "debug";
    $logLevel = $logLevels->{$logLevel} || 0;
}

## @rmethod void lmLog(string msg, string level)
# Wrapper for Apache log system
# @param $msg message to log
# @param $level string (emerg|alert|crit|error|warn|notice|info|debug)
sub lmLog {
    my ( $class, $msg, $level ) = @_;
    return if ( $logLevels->{$level} < $logLevel );

    my ( $module, $file, $line ) = caller();

    if ( $level eq 'debug' ) {
        $file =~ s#.+/##;
        Lemonldap::NG::Handler::API->lmLog( "$file($line): $msg", "debug" );
    }
    else {
        Lemonldap::NG::Handler::API->lmLog( "$file($line):", "debug" )
          if ( $logLevel == 0 );
        Lemonldap::NG::Handler::API->lmLog( "Lemonldap::NG::Handler: $msg",
            $level );
    }
}

1;
