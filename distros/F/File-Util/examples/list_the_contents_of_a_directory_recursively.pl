# ABSTRACT: List the contents of a directory and all its subdirectories (recursive)

use strict;
use warnings;
use File::Util qw( NL );

my $ftl = File::Util->new();

my $dir = '/tmp'; # in this example, this file must already exist

# option --no-fsdots excludes "." and ".." from the list
my @dirs_and_files = $f->list_dir( $dir, '--recurse' );

# The NL constant below will be the apropriate newline character sequence
# for your operating system... "\n" or "\r\n"

# print out the list of files, each on its own line
print join NL, @dirs_and_files;

exit;
