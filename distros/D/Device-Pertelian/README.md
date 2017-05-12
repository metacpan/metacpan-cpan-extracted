# NAME

Device::Pertelian - a driver for the Pertelian X2040 USB LCD

# SYNOPSIS

If you have a Pertelian X2040 USB LCD screen, then you can do
things with it.

    use Device::Pertelian;

    my $lcd = Device::Pertelian->new('/dev/ttyUSB0');
    $lcd->clearscreen();

    # write to the top row
    $lcd->writeline(0, "Hello, world!");
    ...

# METHODS

## new

The constructor accepts one parameter, $device, which is a path in /dev.
You may find it out from your logs.

## clearscreen

This function does a simple thing -- clears all the 4 lines of the screen.

## writeline

This function takes two parameters, $row and $text. The screen has 4 rows,
so you may pass a number from 0 to 3 as $row and the $text should be
under 20 characters, that is the width of the screen.

# AUTHOR

Alex Kapranoff, `<alex at kapranoff.ru>`

# BUGS

Please report any bugs or feature requests to `bug-device-pertelian at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Pertelian](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Pertelian).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Pertelian

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Pertelian](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Pertelian)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Device-Pertelian](http://annocpan.org/dist/Device-Pertelian)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Device-Pertelian](http://cpanratings.perl.org/d/Device-Pertelian)

- Search CPAN

    [http://search.cpan.org/dist/Device-Pertelian](http://search.cpan.org/dist/Device-Pertelian)

# DOCUMENTATION

See [http://www.ekenrooi.net/lcd/lcd.shtml](http://www.ekenrooi.net/lcd/lcd.shtml), 
[http://web.archive.org/web/20100903020330/http://developer.pertelian.com/index.php?option=com\_content&view=section&id=3&Itemid=9](http://web.archive.org/web/20100903020330/http://developer.pertelian.com/index.php?option=com_content&view=section&id=3&Itemid=9)
and the pertd software that vanished with the main website pertelian.com.

# COPYRIGHT & LICENSE

Copyright 2008 Alex Kapranoff, all rights reserved.

This program is released under the following license: GPL version 3

In the included pertd.tgz archive there is code by:
Frans Meulenbroeks, Ron Lauzon, Pred S. Bundalo, Chmouel Boudjnah,
W. Richard Stevens.

The code in pertd.tgz is either in Public Domain or available for
distribution in unmodified form. See the relevant files.
