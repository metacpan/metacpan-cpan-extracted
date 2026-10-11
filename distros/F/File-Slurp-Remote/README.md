## Name

```
File::Slurp::Remote - read/write files on remote systems using ssh.
```

## Synopsis

```perl
use File::Slurp::Remote;

write_remote_file($host, $file, @contents);

@lines = read_remote_file($host, $file);

$whole_thing = read_remote_file($host, $file);
```

## Description

This is similar to [File::Slurp](https://metacpan.org/pod/File%3A%3ASlurp), but it reads and writes files on
remote systems using `ssh` to get there.

It uses ssh/scp to get to the remote systems.  You can override the copy
command by redefining `$File::Slurp::Remote::scp`.  You can override
the remote shell command by redefining
`$File::Slurp::Remote::SmartOpen::ssh`.

## License

Copyright (C) 2008-2007,2008-2010 David Sharnoff.
Copyright (C) 2007-2008 SearchMe Inc.
Copyright (C) 2011 Google Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

## Support

Module now maintained by
Nigel Horne, `<njh at nigelhorne.com>`
