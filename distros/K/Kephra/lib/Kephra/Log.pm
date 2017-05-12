package Kephra::Log;
$VERSION = '0.01';

use strict;
use warnings;

sub setup_logging {
    eval {
        require Log::Dispatch;
        require Log::Dispatch::File;
    };
    if ($@) {
        _setup_fake_logger();
    } else {
        _setup_real_logger();
    }
    $main::logger->info("Starting");
    return;
}

sub _setup_fake_logger {
    package Kephra::FakeLogger;
    $main::logger = bless {}, __PACKAGE__; 
    no strict 'refs';
    foreach my $l ( qw( debug info notice warning err error crit critical alert emerg emergency ) )
    {
        *{$l} = sub {};
    }
    return;
}

sub _setup_real_logger {
    mkdir $Kephra::temp{path}{logger};
    # TODO: setup pseudo logger in case the directory does not exist or
    # otherwise cannot start the logger, report error
    $main::logger = Log::Dispatch->new;
    require POSIX;
    my $ts = POSIX::strftime("%Y%m%d", localtime);
            print File::Spec->catfile($Kephra::temp{path}{logger}, "$ts.log");
    $main::logger->add( Log::Dispatch::File->new( 
            name        => 'file1',
            min_level   => ($ENV{KEPHRA_LOGGIN} || 'debug'),
            filename    => File::Spec->catfile($Kephra::temp{path}{logger}, "$ts.log"),
            mode        => 'append',
            callbacks   => \&_logger,
    ));
    $SIG{__WARN__} = sub { $main::logger->warning($_[0]) };
    return;
}


sub _logger {
    my %data = @_;
    # TODO maybe we should use regular timestamp here and turn on the hires timestamp
    # only if KEPHRA_TIME or similar env variable is set
    require Time::HiRes;
    return sprintf("%s - %s - %s - %s\n", Time::HiRes::time(), $$, $data{level}, $data{message});
}

sub msg { message(@_) }
sub message {
	#Wx::LogMessage( "Hello from MyTimer::Notify!" );
#  Wx::Log::SetActiveTarget( delete $this->{OLDLOG} );
    #$this->{OLDLOG} =
      #Wx::Log::SetActiveTarget( Wx::LogTextCtrl->new( $this->{TEXT} ) );
#
    #Wx::LogTraceMask( 'test', "You can't see this!" );
    #Wx::Log::AddTraceMask( 'test' );
    #Wx::LogTraceMask( "Wx::LogTraceMask" );
    #Wx::Log::SetActiveTarget( $this->{PANEL}->{OLDLOG} );
}

sub warn { Kephra::App::StatusBar::info_msg(@_) }


1;