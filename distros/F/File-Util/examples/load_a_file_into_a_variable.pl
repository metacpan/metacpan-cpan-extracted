# ABSTRACT: Load the contents of a file into a string or array

use strict;
use warnings;
use File::Util qw( NL );

my $ftl = File::Util->new();

my $file = 'example.txt'; # in this example, this file must already exist

# get the whole file in one string
my $content = $ftl->load_file( $file );

print $content;

# get the file in a list of lines
my @content_lines = $ftl->load_file( $file, '--as-lines' );

# The NL constant below will be the apropriate newline character sequence
# for your operating system... "\n" or "\r\n"
print join NL, @content_lines;

exit;
