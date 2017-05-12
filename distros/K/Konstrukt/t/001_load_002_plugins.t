#test if all plugins can be loaded and if the `use stict`

use Test::Strict;
all_perl_files_ok('lib/Konstrukt/Plugin'); # Syntax ok and use strict;
