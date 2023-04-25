# pure perl file magic

I just wanted a pure perl way to detect files

## Usage

### executable usage

The command will print the file name and file type

    file-pp.pl *.*

### library usage

```perl

use lib './lib';
use strict;
use warnings;

use Magic qw/file/;

for my $f(@ARGV){
  print file($f)."\n";
}
```


