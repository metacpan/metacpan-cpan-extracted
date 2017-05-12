# NAME

File::Tail::Inotify2 - Simple interface to tail a file using inotify.

# SYNOPSIS

    use File::Tail::Inotify2;
    my $watcher = File::Tail::Inotify2->new(
        file    => $filename,
        on_read => sub {
            my $line = shift;
            print $line;
        }
    );
    $watcher->poll;

# DESCRIPTION

Yet another module to tail a file. Even if the file are renamed by
logrotate(8), this module tail a new file created by logrotate(8).

# WARNINGS

This module works on Linux. Other OS are not supported.

# METHOD

- $watcher = File::Tail::Inotify2->new( file => $filename, on\_read => $cb->($read\_line) )

    Returns a File::Tail::Inotify2 object. If `$filename` is modified, `$cb->($read_line)` is called per line.

- $watcher->poll

    Starts watching a file and will never exit.

# SEE ALSO

[Linux::Inotify2](http://search.cpan.org/perldoc?Linux::Inotify2), [File::Tail](http://search.cpan.org/perldoc?File::Tail), [File::SmartTail](http://search.cpan.org/perldoc?File::SmartTail), [Tail::Tool](http://search.cpan.org/perldoc?Tail::Tool)

# AUTHOR

Yoshihiro Sasaki, <ysasaki at cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2012 by Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
