# NAME

File::RotateLogs - File logger supports log rotation

# SYNOPSIS

    use File::RotateLogs;
    use Plack::Builder;
    
    my $rotatelogs = File::RotateLogs->new(
        logfile => '/path/to/access_log.%Y%m%d%H%M',
        linkname => '/path/to/access_log',
        rotationtime => 3600,
        maxage => 86400, #1day
    );
    
    builder {
        enable 'AccessLog',
          logger => sub { $rotatelogs->print(@_) };
        $app;
    };

# DESCRIPTION

File::RotateLogs is utility for file logger.
Supports logfile rotation and makes symlink to newest logfile.

# CONFIGURATION

- logfile

    This is file name pattern. It is the pattern for filename. The format is POSIX::strftime(), see also [POSIX](https://metacpan.org/pod/POSIX).

- linkname

    Filename to symlink to newest logfile. default: none

- rotationtime

    default: 86400 (1day)

- maxage

    Maximum age of files (based on mtime), in seconds. After the age is surpassed, 
    files older than this age will be deleted. Optional. Default is undefined, which means unlimited.
    old files are removed at a background unlink worker.

- sleep\_before\_remove

    Sleep seconds before remove old log files. default: 3
    If sleep\_before\_remove == 0, files are removed within plack processes. Does not fork background 
    unlink worker.

- offset

    The number of seconds offset form UTC. default: 0
    If offset is omitted or set zero, UTC is used.
    When rotationtime is 24h and offset is 0, log is going to be rotated at 0 O'clock (UTC).
    For example, to use local timezone in the zone UTC +9 (Asia/Tokyo), set 32400 (9\*60\*60).

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[File::Stamped](https://metacpan.org/pod/File::Stamped), [Log::Dispatch::Dir](https://metacpan.org/pod/Log::Dispatch::Dir)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
