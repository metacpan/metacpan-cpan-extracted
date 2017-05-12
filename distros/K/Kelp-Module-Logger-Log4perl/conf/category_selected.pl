{
    modules => [ 'Logger::Log4perl' ],
    modules_init => {
        'Logger::Log4perl' => {
            category => 'kelp',
            conf     => {
                'log4perl.logger.kelp'                                 => 'ERROR, CommonLog',
                'log4perl.appender.CommonLog'                          => 'Log::Log4perl::Appender::Screen',
                'log4perl.appender.CommonLog.layout'                   => 'Log::Log4perl::Layout::PatternLayout',
                'log4perl.appender.CommonLog.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} - %5p - %m%n',
                'log4perl.appender.CommonLog.stderr'                   => '0',
            }
        }
    }
};
