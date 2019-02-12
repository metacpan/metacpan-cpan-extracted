#!/usr/bin/perl -w

our $tok_sep = "\x1e"; ##-- ascii 0x1e : RS (record separator);
our $col_sep = "\x1c"; ##-- ascii 0x1c : FS (file|field separator)

@s=qw();
while (<>) {
  chomp;
  if (/^$/) {
    print join($tok_sep, @s), "\n" ;#if (@s);
    @s=qw();
    next;
  }
  s/\t/$col_sep/g;
  push(@s,$_);
}
print join($tok_sep, @s), "\n" if (@s);
