use warnings; use strict;
use File::Copy;
use File::Path;

mkpath 'bin';
copy('scripts/ebook.pl','bin/ebook') or die("Could not create bin/ebook");
chmod(0755,'bin/ebook');
