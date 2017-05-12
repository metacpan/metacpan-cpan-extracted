{
    modules => ['Logger::Log4perl'],
    modules_init => {
        'Logger::Log4perl' => {
            category => '',
            conf     => 'conf/logger.conf',
        }
    }
};

