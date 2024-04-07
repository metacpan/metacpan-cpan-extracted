[![Perl application](https://github.com/glasswalk3r/Linux-NFS-BigDir/actions/workflows/unit-test.yml/badge.svg)](https://github.com/glasswalk3r/Linux-NFS-BigDir/actions/workflows/unit-test.yml)

# Linux-NFS-BigDir

This module was created to solve a very specific problem: you have a directory over NFS, mounted by
a Linux OS, and that directory has a very large number of items (files, directories, etc). The number of entries
is so large that you have trouble to list the contents with `readdir` or even `ls` from the shell. In extreme
cases, the operation just "hangs" and will provide a feedback hours later.

I observed this behavior only with NFS version 3 (and wasn't able to simulate it with local EXT3/EXT4): you might find in different situations, 
but in that case it migh be a wrong configuration regarding the filesystem. Ask your administrator first.

If you can't fix (or get fixed) the problem, then you might want to try to use this module. It will use the `getdents`
syscall from Linux. You can check the documentation about this syscall with `man getdents` in a shell.

In short, this syscall will return a data structure, but you probably will want to use only the name of each entry in the directory.

How can this be useful? Here are some directions:

1. You want to remove all directory content.
2. You want to remove files from the directory with a pattern in their filename (using regular expressions, for example).
3. You want to select specific files by their filenames and then test something else (like atime).

These are examples, but it should cover the vast majority of what you want to do. `getdents` syscall will be more effective because
it will not call `stat` of each of those files before returning the information to you. That means, you will have the opportunity to filter
whatever you need and then call `stat` if you really need.

I came up at `getdents` after researching about "how to remove million of files". After a while I reached an C program example that uses `getdents`
to print the filenames under the directory. By using it, I was able to cleanup directories with thousands (or even millions) of files in a couple of minutes, 
instead of many hours.

This module is a Perl implementation of that.

## Install

This distribution will only work in Linux OS with perl version 5.14.4 or higher.

You will need [Dist::Zilla](https://dzil.org/) installed first. Check the `dist.ini` file for details on that.

