use 5.005_62;
use strict;

use File::Spec::Functions qw( catfile );

use constant MOD_REQS =>
  [
   { name    => 'Pod::Usage',
     version => '1.12', },

   { name    => 'Class::MethodMaker',
     package => 'Class-MethodMaker',
     version => '1.02', },

   { name     => 'Digest::MD5',
     package  => 'Digest-MD5',
     version  => '2.00',
     optional => 1,
     message  => 'MD5 features will be unavailable', },

   { name    => 'MLDBM',
     package => 'MLDBM',
     version => '2.00', },

   { name    => 'Storable',
     package => 'Storable',
     version => '1.014', },

   { name    => 'DB_File',
     package => 'DB_File',
     version => '1.803', },

   { name    => 'Log::Info',
     package => 'Log-Info',
     version => '1.03', },

   # Used by test.pm
   { name    => 'IPC::Run',
     package => 'IPC-Run',
     version => '0.44', },

   { name     => 'Archive::Par',
     package  => 'Archive-Par',
     optional => 1,
     version  => '1.52',
     message  => 'Par-specific features will be unavailable',
   },
  ];

use constant EXEC_REQS =>
  [
  ];

use constant NAME         => 'File-Info';
use constant VERSION_FROM => catfile (qw( lib File Info.pm ));
use constant AUTHOR       => 'Martyn J. Pearce';
use constant ABSTRACT     => 'Tool for caching File Information';

use FindBin 1.42 qw( $Bin );
use lib $Bin;
use make;

