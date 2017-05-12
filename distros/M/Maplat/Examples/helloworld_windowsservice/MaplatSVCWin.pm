package MaplatSVCWin;
use strict;
use warnings;

use Win32::Process;
use Win32;
use Maplat::Helpers::Cache::Memcached;
use Maplat::Helpers::BuildNum;

sub new {
    my ($class, $isService, $basePath, $memhserver, $memhnamespace,
        $APPNAME, $VERSION, $isCompiled) = @_;
    my $self = bless {}, $class;
    
    $self->{isService} = $isService;
    
    $basePath =~ s/\//\\/g; # Convert to Win32 Path
    $self->{basePath} = $basePath;
    
    if($memhserver ne "none") {
        my $memd = new Maplat::Helpers::Cache::Memcached {
                        servers   => [ $memhserver ],
                        namespace => $memhnamespace . "::",
        };
        $self->{memd} = $memd;
        
        $self->memhset("VERSION::" . $APPNAME, $VERSION);
        $self->memhset("BUILD::" . $APPNAME, readBuildNum(undef, $isCompiled));
    }
    
    return $self;
}

sub startconfig {
    my ($self) = @_;
    
    $self->{apps} = ();
    $self->{startup_scripts} = ();
    $self->{shutdown_scripts} = ();
}

sub configure_module {
    my ($self, $module) = @_;
    
    print "Configuring module " . $module->{description} . "...\n";
    $module->{handle} = undef;
    
     # Convert to Win32 Paths
    my $fullapp = $module->{app};
    $fullapp =~ s/\//\\/g;
    $module->{app} = $fullapp;

    my $fullconf = $module->{conf};
    $fullconf =~ s/\//\\/g;
    $module->{conf} = $fullconf;
    
    
    push @{$self->{apps}}, $module;
}

sub configure_startup {
    my ($self, $command) = @_;
    
    $command =~ s/\//\\/g;
    push @{$self->{startup_scripts}}, $command;
}

sub configure_shutdown {
    my ($self, $command) = @_;
    
    $command =~ s/\//\\/g;
    push @{$self->{shutdown_scripts}}, $command;
}

sub endconfig {
    my ($self) = @_;
    
    foreach my $script (@{$self->{startup_scripts}}) {
        $self->run_script($script);
    }
    print "Startup scripts complete\n";
    
    foreach my $app (@{$self->{apps}}) {
        $self->start_app($app);
    }
    print "Initial apps startup complete\n";
    $self->{shutdown_complete} = 0;
    
}

sub work {
    my ($self) = @_;
    
    my $workCount = 0;
    
    foreach my $app (@{$self->{apps}}) {
        if(!$self->check_app($app)) {
            print "*** App " . $app->{description} . " FAILED! ***\n"
        }
        
        $workCount++;
    }    
    
    return $workCount;
    
}

sub shutdown {
    my ($self) = @_;
    
    print "Shutdown started.\n";
    
    foreach my $app (@{$self->{apps}}) {
        $self->stop_app($app);
    }
    
    print "Apps shut down.\n";
    
    foreach my $script (@{$self->{shutdown_scripts}}) {
        $self->run_script($script);
    }
    print "Shutdown scripts complete\n";
    $self->{shutdown_complete} = 1;
}

sub DESTROY {
    my ($self) = @_;
    
    if(!$self->{shutdown_complete}) {
        $self->shutdown();
    }
}

sub check_app {
    my ($self, $app) = @_;
    
    if(!defined($app->{handle})) {
        return $self->start_app($app);
    }
    
    # First, check if the process exited
    if($app->{handle}->Wait(1)) {
        # Process exited, so, restart
        print "Process exit detected: " . $app->{description} . "!n";
        return $self->start_app($app);
    }
    
    if(!defined($app->{lifetick}) || $app->{lifetick} == 0) {
        return 1;
    } else {
        # Process itself is still running, so check its lifetick
        # to see if it hangs
        my $app_pid = $app->{handle}->GetProcessID();
        my $apptick = $self->memhget("LIFETICK::" . $app_pid);
        if(!defined($apptick)) {
            #print "Apptick not set for " . $app->{description} . "!\n";
            return 1;
        } elsif($apptick == 0) {
            # Client requested a temporary suspension of lifetick handling
            return 1;
        }
        my $tickage = time - $apptick;
        if($tickage > $app->{lifetick}) {
            # Stale lifetick
            print "Stale Lifetick detected: " . $app->{description} . "!\n";
            $self->stop_app($app);
            return $self->start_app($app);
        } else {
            return 1;
        }
        
    }
    
}

sub start_app {
    my ($self, $app) = @_;
    
    my $ProcessObj;
    
    if(!Win32::Process::Create($ProcessObj,
                                $app->{app},
                                $app->{app} . " " . $app->{conf},
                                0,
                                NORMAL_PRIORITY_CLASS,
                                $self->{basePath})) {
        print "Error starting app " . $app->{description} . ": " .
                Win32::FormatMessage( Win32::GetLastError() ) .
                "\n";
        $app->{handle} = undef;
        return 0;
    } else {
        $app->{handle} = $ProcessObj;
        my $app_pid = $app->{handle}->GetProcessID();
        my $stime = time;
        $self->memhset("LIFETICK::" . $app_pid, $stime);
        print "Started app " . $app->{description} . " with PID " .
                $ProcessObj->GetProcessID() . "\n";
        return 1;
    }
}

sub stop_app {
    my ($self, $app) = @_;
    
    if(defined($app->{handle}) && $app->{handle}) {
        print "Killing app " . $app->{description} . "...\n";
        my $app_pid = $app->{handle}->GetProcessID();
        $app->{handle}->Kill(0);
        $app->{handle}->Wait(2000);
        $app->{handle} = undef;
        print "...killed.\n";
        $self->memhdelete("LIFETICK::" . $app_pid);
    } else {
        print "App " . $app->{description} . " already killed\n";
    }
    
}

sub run_script {
    my ($self, $command) = @_;
    
    my $ProcessObj;
    
    if(!Win32::Process::Create($ProcessObj,
                                $command,
                                $command,
                                0,
                                NORMAL_PRIORITY_CLASS,
                                $self->{basePath})) {
        print "Error starting script " . $command . ": " .
                Win32::FormatMessage( Win32::GetLastError() ) .
                "\n";
        return 0;
    } else {
        my $app_pid = $ProcessObj->GetProcessID();
        print "Started script " . $command . " with PID " .
                $ProcessObj->GetProcessID() . "\n";
                
        while(1) {
            if($ProcessObj->Wait(1000)) {
                print "Script " . $command . " finished\n";
                last;
            }
            print "Waiting for script to end...\n";
        }
                
        return 1;
    }
}

sub memhget {
	my ($self, $key) = @_;
	
    return if(!defined($self->{memd}));
    
	$key = $self->memhsanitize_key($key);
	
	return $self->{memd}->get($key);
}

sub memhset {
	my ($self, $key, $data) = @_;
	
    return if(!defined($self->{memd}));
    
	$key = $self->memhsanitize_key($key);
	
	return $self->{memd}->set($key, $data);
}

sub memhdelete {
	my ($self, $key) = @_;
	
    return if(!defined($self->{memd}));
    
	$key = $self->memhsanitize_key($key);
	
	return $self->{memd}->delete($key);
}

sub memhsanitize_key {
	my ($self, $key) = @_;
	
	# Certain chars are not allowed in keys for whatever reason.
	# This *should* be handled by the Cache::Memcached module, but isn't
	# We handle this by substituting them with a tripple underline
	
	$key =~ s/\ /___/go;
	
	return $key;
}



1;
