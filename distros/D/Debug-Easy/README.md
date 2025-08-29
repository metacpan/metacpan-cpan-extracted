# Debug-Easy

![Debug::Easy Logo](Debug-Easy.png?raw=true "Debug::Easy")

## DESCRIPTION

This module makes debugging Perl code much easier and even allows you to retain the debugging code without interference in production.  Using an options switch, you can enable, disable or adjust the level of debugging.

Typically, debugging runs at errors only level, but you can have verbose, ordinary debugging or quite noisy (max) debugging for very difficult problems.  Add the lines to your code and leave them there.

Output can be using ANSI color codes (default), but can also be turned off to be ordinary ASCII text.  Output is timestamped and location logged as well.

## INSTALLATION

To install this module, run the following commands:

```bash
        perl Makefile.PL
        make
        make test
 [sudo] make install
```

## SAMPLE CODE

The "examples" directory in the tar package has two code examples on how to use this module.

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

`perldoc Debug::Easy`

You can also look for information at:

* **GitHub** - https://github.com/richcsst/Debug-Easy
* **GitHub Clone** - https://github.com/richcsst/Debug-Easy.git

  GitHub will always have the latest version available, even before CPAN.

## LICENSE AND COPYRIGHT

Copyright © 2013-2025 Richard Kelsch

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

* **Artistic License** - https://www.perlfoundation.org/artistic_license_2_0
