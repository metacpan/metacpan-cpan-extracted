Log::Basic
==========

- [SYNOPSIS](#synopsis)
	- [One-liner](#one-liner)
	- [Full Perl example](#full-perl-example)
- [DESCRIPTION](#description)
	- [Format](#format)
	- [Levels](#levels)
	- [Special cases](#special-cases)
	- [Saving to file](#saving-to-file)
- [INSTALLATION](#installation)
- [DEPENDENCIES](#dependencies)
- [ISSUES](#issues)
- [COPYRIGHT AND LICENCE](#copyright-and-licence)


#SYNOPSIS

##One-liner
```
perl -MLog::Basic -e 'info "Hello"'
```
This outputs `[info]  [proc:21699] [2016-02-17 18:20:43] Hello`

##Full Perl example
```perl
use Log::Basic;
$Log::Basic::VERBOSITY=3;
debug "stuff"; # won't be printed
info "here is the info message"; # won't be printed
warning "wow! beware!";
error "something terrible happend !";
msg "this message will be displayed whatever the verbosity level";
sep "a separator";
fatal "fatal error: $!";
```

#DESCRIPTION

Log::Basic displays formatted messages according to the defined verbosity level (default:4).

##Format
Log messages are formatted as: `[<level>] [<pid>] [<date>] <message>`.
Dates are formatted as: `YYYY-MM-DD hh:mm:ss`.
Your message could be whatever you what.

##Levels
Verbosity and associated levels are:
- level 1, `msg`
- level 2, `error`
- level 3, `warn`
- level 4, `info`
- level 5, `debug`
- no level, `fatal`

Setting verbosity to 3 will print `warn`, `info`, and `msg` only.

##Special cases
`fatal` is a special level, corresponding to perl's `die()`.

`sep` (stands for separator) is a special function which displays a line of 80 dashes, with your message eventually.

##Saving to file
All messages will also be appended to a file named `<date>.$$.log`. If a `./log/` folder exists, the file is created in this folder, otherwise it is created in the current directory.
<date> is formatted as `YYYYMMDDhhmmss` to allow chronological sorting.

#INSTALLATION

To install, get the latest [release](https://github.com/keuv-grvl/perl-log-basic/releases) or clone the repo, then type the following:

```
perl Makefile.PL
make
make install
make clean
perl -MLog::Basic -e 'info "done"'
```

#DEPENDENCIES

None.

# ISSUES

Please report issues at https://github.com/keuv-grvl/perl-log-basic/issues.

#COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) 2016 by Kévin Gravouil

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.

