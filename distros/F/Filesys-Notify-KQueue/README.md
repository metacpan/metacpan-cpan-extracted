[![Build Status](https://travis-ci.org/karupanerura/p5-Filesys-Notify-KQueue.svg?branch=master)](https://travis-ci.org/karupanerura/p5-Filesys-Notify-KQueue)
# NAME

Filesys::Notify::KQueue - Wrap IO::KQueue for watching file system.

# SYNOPSIS

    use Filesys::Notify::KQueue;

    my $notify = Filesys::Notify::KQueue->new(
        path    => [qw(~/Maildir/new)],
        timeout => 1000,
    );
    $notify->wait(sub {
        my @events = @_;

        foreach my $event (@events) {
            ## ....
        }
    });

# DESCRIPTION

Filesys::Notify::KQueue is IO::KQueue wrapper for watching file system.

# METHODS

## new - Hash or HashRef

This is constructor method.

- path - ArrayRef\[Str\]

    Watch files or directories.

- timeout - Int

    KQueue's timeout. (millisecond)

## wait - CodeRef

There is no file name based filter. Do it in your own code.
You can get types of events (create, modify, rename, delete).

# AUTHOR

Kenta Sato <karupa@cpan.org>

# SEE ALSO

[IO::KQueue](https://metacpan.org/pod/IO::KQueue) [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple) [AnyEvent::Filesys::Notify](https://metacpan.org/pod/AnyEvent::Filesys::Notify) [File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify) [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents) [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
