use strict;
use warnings;

use Test::More tests => 8;
use File::MimeInfo::Simple;

# Test that file extensions are correctly extracted by the internal lookup table
# The regex should capture the full extension after the last dot
# We test _find_mimetype_by_table directly since on Unix the file command
# analyzes content, not extensions

# Access internal function for testing
my $lookup = \&File::MimeInfo::Simple::_find_mimetype_by_table;

# Test 1: Simple extension
is($lookup->('document.pdf'), 'application/pdf', 'simple .pdf extension');

# Test 2: Double extension - should use last extension (.gz not .tar)
is($lookup->('archive.tar.gz'), 'application/x-gzip', 'double extension .tar.gz uses .gz');

# Test 3: Another double extension (.bz2)
is($lookup->('archive.tar.bz2'), 'application/x-bzip', 'double extension .tar.bz2 uses .bz2');

# Test 4: Long extension
is($lookup->('file.html'), 'text/html', 'standard .html extension');

# Test 5: Mixed case extension (should be case-insensitive)
is($lookup->('image.PNG'), 'image/png', 'uppercase .PNG extension');

# Test 6: Multiple dots in filename
is($lookup->('my.file.name.zip'), 'application/zip', 'multiple dots uses last extension');

# Test 7: Full path with extension
is($lookup->('/path/to/some/file.jpg'), 'image/jpeg', 'full path extracts extension correctly');

# Test 8: No extension returns undef
is($lookup->('noextension'), undef, 'no extension returns undef');

