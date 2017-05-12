use strict;
use warnings;
use File::Spec::Functions qw( catdir catfile updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );
use utf8;

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'POD spelling test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Spelling";

$EVAL_ERROR and plan skip_all => 'Test::Spelling required but not installed';

$ENV{TEST_SPELLING}
   or plan skip_all => 'Environment variable TEST_SPELLING not set';

no warnings 'redefine'; no warnings 'once';

*Test::Spelling::invalid_words_in = sub { # Have utf8 stopwords
   my $file = shift; my $document = q(); open my $ofh, '>', \$document;

   open my $ifh, '<:utf8', $file or die "File ${file} cannot open: ${OS_ERROR}";

   Pod::Spell->new->parse_from_filehandle( $ifh, $ofh );

   my @words = Test::Spelling::_get_spellcheck_results( $document );

   chomp for @words;
   return @words;
};

my $checker = has_working_spellchecker(); # Aspell is prefered

if ($checker) { warn "Check using ${checker}\n" }
else { plan skip_all => 'No OS spell checkers found' }

add_stopwords( <DATA> );

all_pod_files_spelling_ok();

done_testing();

# Local Variables:
# coding: utf-8
# mode: perl
# tab-width: 3
# End:

__DATA__
appendln
autoclose
api
buildargs
canonpath
classname
cwd
datetime
dir
dirname
döt
dtd
extn
filename
filenames
filepath
flanigan
getline
getlines
gettext
hexdigest
ingy
io
json
mealmaster
merchantability
metadata
mkpath
mta
NTFS
namespace
nulled
oo
pathname
Prepends
println
resultset
rmtree
splitdir
splitpath
stacktrace
stateful
stringifies
subdirectories
utf
or'ed
resultset's
