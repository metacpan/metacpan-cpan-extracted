use strict;
use warnings;
use Test::More;
use Module::Runtime qw( require_module );
use File::pushd qw( pushd );
use File::Spec;

use Git::Database;

use lib 't/lib';
use TestUtil;

plan skip_all => 'Git::Sub not available'
  if !eval { require Git::Sub; };

my %builder_for = (
    'string'         => sub { shift },
    'File::Fu'       => sub { File::Fu->dir(shift) },
    'Mojo::File'     => sub { Mojo::File->new(shift) },
    'Path::Abstract' => sub { Path::Abstract->new(shift) },
    'Path::Class'    => sub { Path::Class::Dir->new(shift) },
    'Path::Tiny'     => sub { Path::Tiny->new(shift) },
);

my @backends = grep $_ ne 'None', available_backends();

my @classes = ( 'string', grep eval { require_module($_) }, sort keys %builder_for );

plan skip_all => "None of @{[ sort keys %builder_for ]} is installed"
  if !@classes;

my $dir   = repository_from('basic');
my @tests = (
    [$dir],
    [ $dir, File::Spec->tmpdir ],
    [ $dir, 't' ],
    [ File::Spec->abs2rel($dir) ],
    [ File::Spec->abs2rel($dir), File::Spec->tmpdir ],
    [ File::Spec->abs2rel($dir), 't' ],
);

sub test_blob {
    my $db   = shift;
    my $blob = $db->get_object('b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
    isa_ok( $blob, 'Git::Database::Object::Blob' );
    is( eval { $blob->content }, 'hello', 'content is "hello"' );
}

for my $backend ( @backends ) {

    for my $class (@classes) {

        for my $t (@tests) {
            my ( $path, $where ) = @$t;
            my $obj = $builder_for{$class}->($path);
            my $db  = Git::Database->new(
                backend   => $backend,
                work_tree => $obj,
            );
            isa_ok(
                $db,
                "Git::Database::Backend::$backend",
                "$backend backend for $class"
            );

            # optionally change directory after object creation
            note $where ? "pushd $where" : "stay in cwd";
            $where &&= pushd $where;

            # some minimal test
            test_blob($db);

            if( $backend eq 'Git::Sub' ) {
                if ( ref $obj ) { isa_ok( $db->store, ref $obj, $obj ); }
                else { is( ref $db->store, '', "'$obj' is a plain scalar" ); }
            }
        }

        # special case of 'current dir'
        {
            my $cwd = pushd $dir;
            my $db = Git::Database->new( backend => $backend );
            test_blob($db);
            {
                my $tmp = pushd( File::Spec->tmpdir );
                test_blob($db);
            }
        }
    }
}

done_testing;
