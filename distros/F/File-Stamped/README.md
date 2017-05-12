# NAME

File::Stamped - time stamped log file

# SYNOPSIS

    use File::Stamped;
    my $fh = File::Stamped->new(pattern => '/var/log/myapp.log.%Y%m%d.txt');
    $fh->print("OK\n");

    # with Log::Minimal
    use Log::Minimal;
    my $fh = File::Stamped->new(pattern => '/var/log/myapp.log.%Y%m%d.txt');
    local $Log::Minimal::PRINT = sub {
        my ( $time, $type, $message, $trace) = @_;
        print {$fh} "$time [$type] $message at $trace\n";
    };

# DESCRIPTION

File::Stamped is utility library for logging. File::Stamped object mimic file handle.

You can use "myapp.log.%Y%m%d.log" style log file.

# METHODS

- my $fh = File::Stamped->new(%args);

    This method creates new instance of File::Stamped. The arguments are followings.

    You need to specify one of **pattern** or **callback**.

    - pattern : Str

        This is file name pattern. It is the pattern for filename. The format is POSIX::strftime(), see also [POSIX](https://metacpan.org/pod/POSIX).

    - callback : CodeRef

        You can use a CodeRef to generate file name.

        File::Stamped pass only one arguments to callback function.

        Here is a example code:

            my $pattern = '/path/to/myapp.log.%Y%m%d.log';
            my $f = File::Stamped->new(callback => sub {
                my $file_stamped = shift;
                local $_ = $pattern;
                s/!!/$$/ge;
                $_ = POSIX::strftime($_, localtime());
                return $_;
            });

    - close\_after\_write : Bool

        Default value is 1.

    - iomode: Str

        This is IO mode for opening file.

        Default value is '>>:utf8'.

    - autoflush: Bool

        This attribute changes $|.

    - rotationtime: Int

        The time between log file generates in seconds. Default value is 1.

    - auto\_make\_dir: Bool

        If this attribute is true, auto make directry of log file. Default value is false.

    - symlink: Str

        generate symlink file for log file.

- $fh->print($str: Str)

    This method prints the $str to the file.

- $fh->syswrite($str: Str \[, $len: Int, $offset: Int\])

    This method prints the $str to the file.
    This method uses syswrite internally. Writing is not buffered.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ gmail.com>

# SEE ALSO

[Log::Dispatch::File::Stamped](https://metacpan.org/pod/Log::Dispatch::File::Stamped)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
