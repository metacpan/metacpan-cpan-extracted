#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use File::Temp;
use IO::Barf;

# Content.
my $content = "foo\nbar\n";

# Temporary file.
my $temp_file = File::Temp->new->filename;

# Barf out.
barf($temp_file, $content);

# Print tempory file.
system "cat $temp_file";

# Unlink temporary file.
unlink $temp_file;

# Output:
# foo
# bar