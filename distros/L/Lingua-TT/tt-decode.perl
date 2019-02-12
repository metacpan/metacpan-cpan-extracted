#!/usr/bin/perl -w

our $tok_sep = "\x1e"; ##-- ascii 0x1e : RS (record separator);
our $col_sep = "\x1c"; ##-- ascii 0x1c : FS (file|field separator)

while (<>) {
  chomp;
  print join("\n",map { join("\t",split(/\x1c/,$_)) } split(/\x1e/,$_))."\n\n";
}
