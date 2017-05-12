package Global::MutexLock;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.026";

our @EXPORT_OK = qw( 
    mutex_create
    mutex_lock
    mutex_unlock
    mutex_destory
);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Global::MutexLock - A xs module to give perl global mutex-lock between crons or web-app's workers

=head1 SYNOPSIS

    use Global::MutexLock;

=head1 DESCRIPTION

Global::MutexLock is a module to create os-level global mutex-lock for perl.  
You can lock anything between process to others, or web-applications, or threads,cron.  
  
Mutex-lock's pointer is stored in System V IPC.  
You should let the process to know the IPC-ID for locking.  
  
If you want to delete IPC-ID by yourself, please use 'ipcs','ipcrm'.  

=head1 USAGE
  
# 0. use Global::MutexLock;  
  
    use Global::MutexLock qw(mutex_create mutex_destory mutex_lock mutex_unlock);   
  
# 1. create a new global mutex id  
# tips: you can create an id, and use it in different crons or apps  
  
    my $mutex_id = mutex_create();  
  
# 2. take a lock  
  
    unless (mutex_lock($mutex_id)) {  
        warn "lock error";  
    }  
  
# 3. do something...  
# ...  
  
# 4. release lock  
  
    unless (mutex_unlock($mutex_id)) {  
        warn "release lock error";  
    }  
  
# 5. destory mutex lock id  
# you must do it. otherwise the IPC id will be leaved in system.  
# or you can rm it by `ipcrm -m IPCID`  
# you can find IPCID by `ipcs`  
  
    mutex_destory($mutex_id);  
  
=head1 LICENSE

Copyright (C) itsusony. FreakOut.  
MIT LICENSE

=head1 AUTHOR

itsusony <itsusony@fout.jp>

=cut

