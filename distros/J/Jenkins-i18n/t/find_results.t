use strict;
use warnings;
use Test::More tests => 7;

use Jenkins::i18n::FindResults;

my $instance = Jenkins::i18n::FindResults->new;
isa_ok( $instance, 'Jenkins::i18n::FindResults' );
ok( $instance->add_file('foo'), 'Can add a file' );
ok( $instance->add_file('bar'), 'Can add another file' );
is( $instance->size, 2, 'have the expected number of files' );
my $next = $instance->files();
is( ref($next), 'CODE', 'the iterator is a sub reference' );
my $file = $next->();
is( $file, 'bar', 'iterator returned the expected file' )
    or diag( explain($instance) );
$file = $next->();
is( $file, 'foo', 'iterator returned the expected file' )
    or diag( explain($instance) );

