use strict;
use warnings;
use lib '.';
use inc::Module::Install;

name            'MIME-tools';
module_name     'MIME::Tools';
version_from    'lib/MIME/Tools.pm';
author          q{Eryq <eryq@zeegee.com>, Dianne Skoll <dfs@roaringpenguin.com>, Dave O'Neill <dmo@roaringpenguin.com>};
abstract        'Tools to manipulate MIME messages';
license         'perl';

# We require 5.8.x, for PerlIO support of "in memory" filehandles opened on scalars
perl_version    '5.008';

# Runtime deps
requires        'Mail::Header'   => 1.01;
requires        'Mail::Internet' => 1.0203;
requires        'Mail::Field'    => 1.05;

# We prefer 3.03, but can work with 2.20
requires        'MIME::Base64'   => 2.20;
recommends      'MIME::Base64'   => 3.03;

# Convert::BinHex is needed if you want to process
# BinHex-encoded mail.  These aren't really specified
# by the MIME standards-track RFCs, so it's a
# recommends rather than a requires
recommends      'Convert::BinHex';

requires        'IO::File'       => 1.13;
requires        'IO::Handle';
requires        'File::Spec'     => 0.6;
requires        'File::Path'     => 1;
requires        'File::Temp'     => 0.18;

# Build deps
build_requires	'Test::More';
build_requires	'Test::Deep';

WriteAll;
