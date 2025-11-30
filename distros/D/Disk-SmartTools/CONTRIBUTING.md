# CONTRIBUTING

If you're reading this document, that means you might be thinking about
helping me out with this project. Thanks!

Here's some ways you could help out:

## RAID Controler Information
As I am limited in the RAID controllers available to me, any information about
other RAID devices would be very helpful.  Please provide the output of:
`lspci -nnd ::0104`, and the correct way to access the RAID disks via
`smartctl -d <disk specification>`

## Bug reports
Found a bug? Great! (Well, not so great I suppose.)

The place to report them is [RT, CPAN's request tracker](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Disk-SmartTools). 
Don't e-mail me about it, as your e-mail is more than likely to
get lost amongst the spam.

An example script clearly demonstrating the bug (preferably written
using `Test2::V0`) would be greatly appreciated.

## Patches
If you've found a bug and written a fix for it, even better!

Generally speaking you should check out the latest copy of the code
from the source repository rather than using the CPAN distribution.
The file META.yml should contain a link to the source repository. If
not, then try [Github: Disk-SmartTools](https://github.com/mattmartini/Disk-SmartTools) 
or submit a bug report. (As far as I'm concerned the lack of a
link is a bug.)

To submit the patch, do a [pull request](https://github.com/mattmartini/Disk-SmartTools/pulls) 
on GitHub, or attach a diff file to a bug report. Unless otherwise
stated, I'll assume that your contributions are licensed under the same
terms as the rest of the project.

If using git, please work in a branch.

## Documentation
If there's anything unclear in the documentation, please submit this as
a bug report or patch as above.

Example scripts that I can bundle would also be appreciated.

## Translation
Translations of documentation would be welcome.

For translations of error messages and other strings embedded in the
code, check with me first. Sometimes the English strings may not in a
stable state, so it would be a waste of time translating them.

## Coding Style
I tend to write using something approximating the K&R style, using
spaces for indentation and Unix-style line breaks.

The best way to conform to my style preferences is to run `perltidy`
utilizing the `support/perltidyrc` configuration file.

I nominally encode all source files as UTF-8, though in practice most of
them use a 7-bit-safe ASCII-compatible subset of UTF-8.

# AUTHOR
    Matt Martini <matt.martini@imaginarywave.com>

# LICENSE AND COPYRIGHT
This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
