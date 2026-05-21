# Debug::Easy

[![Debug::Easy Click for the jingle](pics/Debug-Easy.png?raw=true "Debug::Easy")](https://www.youtube.com/watch?v=IH_TYTW3HZ8)

<sup>Click image for something fun</sup>

![Divider](pics/pink.jpg?raw=true "Divider")

## SYNOPSIS

   ```perl
   use Debug::Easy;

   my $debug = Debug::Easy->new( 'LogLevel' => 'DEBUG', 'Color' => 1);
   ```

   'LogLevel' is the maximum level to report, and ignore the rest. The method names correspond to their loglevels, when outputting a specific message. This identifies to the module what type of message [...]

   The following is a list, in order of level, of the logging methods:

   * **ERR** or **ERROR**        - Error, shows only ERR messages (Use this level for production code as it only logs errors)
   * **WARN** or **WARNING**     - Warning, shows ERR and WARN messages
   * **NOTICE** or **ATTENTION** - Notice, shows ERR, WARN and NOTICE messages
   * **INFO** or **INFORMATION** - Information, shows ERR, WARN, NOTICE and INFO messages
   * **VERBOSE**                 - Special version of INFO that does not output any logging headings and prints to STDOUT instead of STDERR.  Very useful for verbose modes in your scripts.
   * **DEBUG**                   - Level 1 debugging messages, intended for simple helpful messages.  Shows ERR, WARN, NOTICE, INFO and DEBUG messages.
   * **DEBUGMAX**                - Level 2 debugging messages, typically much more terse like dumping variables.  Shows ERR, WARN, NOTICE, INFO, DEBUG and DEBUGMAX messages.

   The parameter is either a string or a reference to an array of strings to output as multiple lines.

   Each string can contain newlines, which will also be split into a separate line and formatted accordingly:

   ```perl
   $debug->ERR(        ['Error message']);
   $debug->ERROR(      ['Error message']);

   $debug->WARN(       ['Warning message']);
   $debug->WARNING(    ['Warning message']);

   $debug->NOTICE(     ['Notice message']);
   $debug->ATTENTION   ['Notice message']);

   $debug->INFO(       ['Information and VERBOSE mode message']);
   $debug->INFORMATION(['Information and VERBOSE mode message']);

   $debug->DEBUG(      ['Level 1 Debug message']);
   $debug->DEBUGMAX(   ['Level 2 (terse) Debug message']);

   my @messages = (
      'First Message',
      'Second Message',
      "Third Message First Line\nThird Message Second Line",
      \%hash_reference
   );

   $debug->INFO([\@messages]);
   ```

![Divider](pics/pink.jpg?raw=true "Divider")

## DESCRIPTION

   This module makes debugging Perl code much easier and even allows you to retain the debugging code without interference in production.  Using an options switch, you can enable, disable or adjust the level of debugging.

   Typically, debugging runs at errors only level, but you can have verbose, ordinary debugging or quite noisy (max) debugging for very difficult problems.  Add the lines to your code and leave them there.

   Output can be using ANSI color codes (default), but can also be turned off to be ordinary ASCII text.  Output is timestamped and location logged as well.

   You development, staging and production environments can be configured to set the appropriate debug level to run in without touching the actual code.  Very handy.

   \* You can turn on DEBUGGING in production code without actually touching the code.  This helps find an issue, if the issue is only happening in production.  Once you find it, make the change in your development environment, then test it in your staging environment and finally push it to production if all is well.

   \* **DO NOT EVER EVER EVER MODIFY PRODUCTION CODE, no matter the excuse.**

![Divider](pics/pink.jpg?raw=true "Divider")

## INSTALLATION

   To install this module, run the following commands:

   ```bash
           perl Makefile.PL
           make
           make test
    [sudo] make install
   ```

![Divider](pics/pink.jpg?raw=true "Divider")

## SAMPLE CODE

   The "examples" directory in the tar package has two code examples on how to use this module.

![Divider](pics/pink.jpg?raw=true "Divider")

## SUPPORT AND DOCUMENTATION

   After installing, you can find documentation for this module with the perldoc command.

   ```bash
   perldoc Debug::Easy
   ```

   You can also look for information at:

   * **GitHub** - [https://github.com/richcsst/Debug-Easy](https://github.com/richcsst/Debug-Easy)
   * **GitHub Clone** - [https://github.com/richcsst/Debug-Easy.git](https://github.com/richcsst/Debug-Easy.git)

   GitHub will always have the latest version available, even before CPAN.

![Divider](pics/pink.jpg?raw=true "Divider")

## COPYRIGHT

   Copyright © 2013-2026 Richard Kelsch

## LICENSE

   This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

   * **Artistic License** - [https://www.perlfoundation.org/artistic_license_2_0](https://www.perlfoundation.org/artistic_license_2_0)
