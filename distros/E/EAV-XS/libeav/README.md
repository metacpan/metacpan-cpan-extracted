# libeav - Email Address Validation Library

![build](https://github.com/gh0stwizard/libeav/workflows/build/badge.svg)
[![codecov](https://codecov.io/gh/gh0stwizard/libeav/branch/master/graph/badge.svg?token=AX694KORHH)](https://codecov.io/gh/gh0stwizard/libeav)

## Description

This is a library which validates an [Email Address][1]. I do my best to
support all existing RFCs:

* [RFC 822][2]
* [RFC 5321][3]
* [RFC 5322][4] (updates `<atext>` specification)
* [RFC 6531][5] (UTF-8 support; updates `<atext>` specification)


A quick note about [RFC 6531][5]: it is possible that the correct implementation
SHOULD take into account [RFC 20][6] to exclude some characters:
``# ` { } | ~ ^``. See the [RFC 6531 switches](#rfc-6531-switches) section below.


## What it does not

You have to be NOT mistaken about the definition of [Email Address][1].
This software does NOT implement (at the moment, at least) a full support
of [Address Specification][14].

All that this software does it is validating of the [Addr-Spec Specification][15].
See details below:

	address = mailbox / group
	mailbox = name-addr / addr-spec
	addr-spec = local-part "@" domain


## Features

* UTF-8 / IDNA2008 support
* FQDN & TLD check (configurable)
* Local-Part & Domain length check


## Dependencies

* [libidn][17] or [libidn2][18] or [idnkit][8]

### Build dependecies

General requirements:

* [GNU make][10]
* C99 compiler to compile

To rebuild the documentation and auto-generate TLD database:

* [Perl][19] + [Text::CSV][29]


## Thread-safety

The library SHOULD be thread-safe. Not tested yet.


## Documentation

The documentation may be found either in [docs][16] directory
or after installing this library via `man` command:

```
% man libeav
```


## Build

### Automatic

At the moment the build system looking for IDN libraries using
next order:

1. [libidn2][18]
2. [libidn][17]
3. [idnkit][8] - see how to configure below

### Build manually with specific IDN library

In the case when you have installed `libidn2` and `libidn`
or `idnkit` (i.e. any 2 or more libraries) on the system, but
you want to build `libeav` with specific library you have to
tell about that like it shown below:

```
% make FORCE_IDN=idn
% make check FORCE_IDN=idn
% make install DESTDIR=/path/to/install/dir
```

The `FORCE_IDN` option can have the next values
(self-described, I hope):

* `idn`
* `idn2`
* `idnkit`

When there is no `libidn2.pc` file on the system (Debian 8,
for instance), then you may do this:

```
% make FORCE_IDN=idn2 DEFS="-DHAVE_LIBIDN2" LIBS="-lidn2"
```


### Build with idnkit

First of all, you have to specify the directory where [idnkit][8]
was installed. To do this you have two options:

* Export the `IDNKIT_DIR` environment variable as showed below.
* Manually change paths in Makefiles.

The library assumes that `idnkit` was installed in `/usr/local`
by default.

Secondly, if you planning to install the library to non-standard
directory you may change the destination directory by setting
`DESTDIR` variable manually.
The default value of `DESTDIR` is `/usr/local`.

```
% export INDKIT_DIR=/home/user/local
% make
% make check
% make install DESTDIR=/path/to/install
```

If you have `libidn2` or `libidn` installed, then you must
use the `FORCE_IDN` option as show above.

### RFC 6531 switches

It is possible to build the library to follow rules of [RFC 5322][4] and
[RFC 20][6]. To so, export or define inline the next options:

* `RFC6531_FOLLOW_RFC5322` = ON | OFF (default OFF)
* `RFC6531_FOLLOW_RFC20` = ON | OFF (default OFF)

For instance, define the options above inline:

```
% make clean
% make check RFC6531_FOLLOW_RFC5322=ON RFC6531_FOLLOW_RFC20=ON
```

Briefly about the switches and these RFCs:

* **RFC 5322** allows some CONTROL characters in quotes and quoted pairs. When
`RFC6531_FOLLOW_RFC5322 = OFF`, **libeav** disallows any CONTROL characters
within *local-part* (copy the **RFC 5321** behavior).
* **RFC 20** simply disallows the next GRAPHIC characters within *local-part*:
``# ` { } | ~ ^``.

See the code of [is_6531_local.c][7] file for details.

### Underscores inside of the domain part

According to "2.3.1. Preferred name syntax" of [RFC 1035][30], a mail domain
should satisfy both the rules of the **RFC 1035** and those in [RFC 822][2].

Historically, many MX servers do allow underscores in the domain part of an
email addresses. The libeav is based on the code base of the [postfix][13],
specifically, you may check this by looking at the file
`src/util/valid_hostname.c` of the current **postfix** distribution.

Since **libeav** 1.2.0 the new option was added:
* `LABELS_ALLOW_UNDERSCORE` = ON | OFF (default OFF)

Pass it to the `make` command, for instance:
```
% make FORCE_IDN=idn2 LABELS_ALLOW_UNDERSCORE=ON
```

Before this, **libeav** had allowed underscores inside of the domain part
of the email addresses by default.

Also should be noted that [idnkit][8] prohibits underscores within
the domain part of the email addresses. I'm highly recommending using
`LABELS_ALLOW_UNDERSCORE=OFF` along side with `idnkit`. At the moment,
**libeav** calls **idnkit** functions to check the domain part
only when `RFC6531` mode is on.

### Updating TLD database

First, there are three files, which corresponds to IANA's
[Root Zone Database][22]:

* [data/tld-domains.txt][23] - used by tests
* [src/auto_tld.c][27] - used by the library
* [include/eav/auto_tld.h][28] - used by the library

The [data/tld-domains.txt][23] depends on [data/raw.csv][25].
The `auto_tld.c` and `auto_tld.h` depends on [data/punycode.csv][24].

Second, to update these files you need [Perl][19] and [Text::CSV][29]
installed on your system.

Third, you have to obtain CSV files by yourself somehow. I am
using the application written to this task, you may find it
here: [github: gh0stwizard/iana-tld-extractor][26].

To update [data/tld-domains.txt][23] use the command below:

```
% make tld-domains
```

To update [src/auto_tld.c][27] and [include/eav/auto_tld.h][28]
use the next command:

```
% make auto
```


## API

When compile your application with [idnkit][8], please, pass the
`-DHAVE_IDNKIT` flag to the compiler.

Please, read the [developer documentation][20] for details.


## Tools

There is an utility called `eav`. It will be installed by default to
the `DESTDIR`/bin directory. It has a simple usage:

```
% eav emails1.txt emails2.txt
```

See its sources in the [bin][12] directory.

The sample output is:

```
FAIL: localpart-only
      email has no domain part
PASS: i.have.only.ipv4@[8.8.8.8]
PASS: this-is.ipv6@[IPv6:2001:0db8:0000:0000:0000:ff00:0042:8329]
PASS: and.this.is.ipv6-ipv4@[IPv6:::ffff:192.0.2.128]
FAIL: invalid.ipv4@[0.1.2.3]
      invalid ip address
FAIL: invalid.ipv6@[IPv6:ge80:1::]
      invalid ip address
PASS: valid.ipv6@[IPv6:2001:db8:0:1:1:1:1:1]
PASS: legacy.valid.ipv6@[IPv6:2001:db8::1:1:1:1:1]
PASS: xxx.ipv6@[2001:db8:1:1:1:1:1:1]
PASS: simple@test.com
```

## Troubleshooting

### libidn issues

The `idn` command depends on the value of `CHARSET` environment variable.
Also, this environment variable affects the behaviour of the **libidn**
library.

If you are getting `Character encoding conversion error`, then try to
check and fix the `CHARSET` variable on your system. Depending on the
type of the operating system, the correct value may be `utf-8` or
`UTF-8`, please, refer to the documentation of your system.

## See also

* [github: dertuxmalwieder/libvldmail][21]


## Credits

* [UTF-8 decoder][11] by JSON.org
* [postfix][13] written by Wietse Venema


## License

This software is released under BSD 2-clause "Simplified" License.


[1]: https://en.wikipedia.org/wiki/Email_address
[2]: https://tools.ietf.org/html/rfc822
[3]: https://tools.ietf.org/html/rfc5321
[4]: https://tools.ietf.org/html/rfc5322
[5]: https://tools.ietf.org/html/rfc6531
[6]: https://tools.ietf.org/html/rfc20
[7]: /src/is_6531_local.c
[8]: https://jprs.co.jp/idn/index-e.html
[9]: https://www.gnu.org/software/libidn/
[10]: https://www.gnu.org/software/make/
[11]: http://www.json.org/JSON_checker/
[12]: /bin/
[13]: http://www.postfix.org/
[14]: https://tools.ietf.org/html/rfc5322#section-3.4
[15]: https://tools.ietf.org/html/rfc5322#section-3.4.1
[16]: /docs/
[17]: https://www.gnu.org/software/libidn/
[18]: https://github.com/libidn/libidn2
[19]: https://www.perl.org/
[20]: /docs/libeav.3.pod
[21]: https://github.com/dertuxmalwieder/libvldmail
[22]: https://www.iana.org/domains/root/db
[23]: /data/tld-domains.txt
[24]: /data/punycode.csv
[25]: /data/raw.csv
[26]: https://github.com/gh0stwizard/iana-tld-extractor
[27]: /src/auto_tld.c
[28]: /include/eav/auto_tld.h
[29]: https://metacpan.org/pod/Text::CSV
[30]: https://tools.ietf.org/html/rfc1035
