# NAME

File::Print::Many - Print to more than one file descriptor at once

# VERSION

Version 0.04

# SYNOPSIS

Print to more than one file descriptor at once.

# SUBROUTINES/METHODS

## new

    use File::Print::Many;
    open(my $fout1, '>', '/tmp/foo') or die "Cannot open file: $!";
    open(my $fout2, '>', '/tmp/bar') or die "Cannot open file: $!";
    my $many = File::Print::Many->new(fds => [$fout1, $fout2]);
    print $fout1 "this only goes to /tmp/foo\n";
    $many->print("this goes to both files\n");

## print

Send output.

    $many->print("hello, world!\n");
    $many->print('hello, ', "world!\n");
    $many->print('hello, ')->print("world!\n");

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-file-print-many at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Print-Many](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Print-Many).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Print::Many

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Print-Many](http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Print-Many)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/File-Print-Many](http://annocpan.org/dist/File-Print-Many)

# LICENCE AND COPYRIGHT

Copyright 2018-2025 Nigel Horne.

This program is released under the following licence: GPL2
