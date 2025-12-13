# NAME

Dev::Util::Sem -  Module to do Semaphore locking

# VERSION

Version v2.19.29

# SYNOPSIS

To ensure that only one instance of a program runs at a time, 
create a semaphore lock file. A second instance will wait until
the first lock is unlocked before it can proceed or it times out.

    use Dev::Util::Sem;

    my $sem = Sem->new('mylock.sem');
    ...
    $sem->unlock;

# EXPORT

    new
    unlock

# METHODS

## **new**

Initialize semaphore.  You can specify the full path to the lock, 
and if the directory you specify exists and is writable then the 
lock file will be placed there.  If you don't specify a directory
or the one you specified is not writable, then a list of alternate
lock dirs will be tried.

    my $sem1 = Sem->new('/wherever/locks/mylock1.sem');
    my $sem2 = Sem->new('mylock2.sem', TIMEOUT);

`TIMEOUT` number of seconds to wait while trying to acquire a lock. Default = 60 seconds

Alternate lock dirs: 

    qw(/var/lock /var/locks /run/lock /tmp);

## **unlock**

Unlock semaphore and delete lock file.

    $sem->unlock;

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

`flock` may not work over `nfs`.

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Backup

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- Search CPAN

    [https://metacpan.org/release/Dev-Util](https://metacpan.org/release/Dev-Util)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2001-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
