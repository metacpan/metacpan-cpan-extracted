package File::SmartTail::Logger;
#
# $Id: Log4perlLogger.pm,v 1.6 2008/07/09 20:40:20 mprewitt Exp $
#
# This file or one of the other loggers is copied to File/SmartTail/Logger.pm
# during the 'perl Makefile.PL' process.  Do not edit File/SmartTail/Logger.pm
# directly.  Edit one of the other Loggers and run make.
#
# DMJA, Inc <smarttail@dmja.com>
# 
# Copyright (C) 2003-2008 DMJA, Inc, File::SmartTail comes with 
# ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to 
# redistribute it and/or modify it under the same terms as Perl itself.
# See the "The Artistic License" L<LICENSE> for more details.

{
    my $v;
    sub LOG {
        $v and return $v;

        _init_log();

        $v = Log::Log4perl->get_logger(__PACKAGE__);
        $v->debug("Initializing " . __PACKAGE__ );
        
        return $v;
    }
}

use constant LOGFILE => 'log4perl.conf';

{
    my $init_log;
    sub _init_log {
        my $logpath = shift || join '/', _log4perl_conf_dir(), LOGFILE;

        require Log::Log4perl;
        require Log::Dispatch::Screen;
        require Log::Log4perl::Appender;

        if (-f $logpath) {
            # print STDERR "Using $logpath\n";
            Log::Log4perl->init_and_watch($logpath, 30);
        } else {
            # print STDERR "No @{[ LOGFILE() ]} file found, creating default\n";
            my $app = Log::Log4perl::Appender->new("Log::Dispatch::Screen");
            my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p %m %n");
            $app->layout($layout);
            my $logger = Log::Log4perl::Logger->get_root_logger();
            $logger->level($Log::Log4perl::FATAL);
            # 
            # Only do this once so we don't get duplicate appenders
            #
            $logger->add_appender($app) unless $init_log;
            $init_log = 1;
        }
    }
}

sub _log4perl_conf_dir {
    require Cwd;
    my $cwd = Cwd::getcwd();
    my $logfile = LOGFILE;
    while ( $cwd && $cwd ne "/" && !-f "$cwd/$logfile") {
        $cwd =~ s:/?[^/]*$::;
    }
    return $cwd;
}

1;
