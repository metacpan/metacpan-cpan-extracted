# NAME

Die::To::Stdout - Make die() print the error to both STDOUT and SDERR, then die.

# SYNOPSIS

This ...

    use Die::To::Stdout;
    die("An error has occured");
    

Will print out something like this to STDOUT, then die.    

      +-- DIED --------------------
      | Package  : main
      | Filename : ........
      | Line     : ........
      | Err      : An error has occured
      +----------------------------
    

This ...

      use Die::To::Stdout { banner => 0 };
      die("An error has occured");
    

Will print out something like this to STDOUT, then die.    

    An error has occured

# DESCRIPTION

## What?

This module when loaded will make die() print the error to both STDOUT and SDERR, then die.

## Why?

You migth want to use this module in case when both STDOUT and STDERR of your Perl script is redirected to the file.
If this is the case, and the script dies, the error message might be located at the TOP of your log file. 

Alternative solution could be to switch-off caching, like this:

    $| = 1;

# SEE ALSO

[Die::Alive](https://metacpan.org/pod/Die%3A%3AAlive)

# LICENSE

Copyright (C) Jan Herout.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Herout <jan.herout@gmail.com>
