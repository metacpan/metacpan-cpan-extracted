use strict;
use warnings;
use Test::More;

eval { require Test::Spelling; };

if ($@) {
   plan skip_all => 'Test::Spelling not available';
} else {
   Test::Spelling->import();
   add_stopwords(<DATA>);
   my @poddirs = qw(lib ../lib);
   all_pod_files_spelling_ok(all_pod_files( @poddirs ));
}

done_testing;

__DATA__
CGI
CPAN
GPL
STDIN
STDOUT
DWIM
OO
RTFM
RTFS
James
Freeman
behaviour
Florent
Angly
Matsumoto
cryptographically

