use strict;
use warnings;

use Test::More tests => 5;

# ABSTRACT: Basic Test for documentation in .pod

use Test::DZil qw( simple_ini Builder );
use Path::Tiny qw( path );

my $files = {};
$files->{'source/lib/Example.pm'}  = 1;
$files->{'source/lib/Example.pod'} = <<'EOF';

# PODNAME: Foo

=head1 DESCRIPTION

This is a description

=cut

1;

EOF
$files->{'source/dist.ini'} = simple_ini( [ 'GatherDir' => {} ], [ 'Readme::Brief' => {} ], );
my $test = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
$test->chrome->logger->set_debug(1);
$test->build;

my $src_file = path( $test->tempdir, 'build', 'README' );
ok( $src_file->exists, 'README generated' );
my @lines = $src_file->lines_utf8( { chomp => 1 } );

use List::Util qw( first );

ok( ( first { $_ eq 'Foo' } @lines ),                   'Document name found and injected' );
ok( ( first { $_ eq 'This is a description' } @lines ), 'Description injected' );
ok( ( first { $_ eq 'INSTALLATION' } @lines ),          'Installation section injected' );
ok( ( first { $_ eq 'COPYRIGHT AND LICENSE' } @lines ), 'Copyright section injected' );
