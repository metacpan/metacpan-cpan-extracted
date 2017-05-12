use strict;
use warnings;
use Test::More;
use Module::Runtime qw( require_module );

use Git::Database;

use lib 't/lib';
use TestUtil;

plan skip_all => 'Git::Sub not available'
  if !eval { require Git::Sub; };

my %builder_for = (
    'File::Fu'    => sub { File::Fu->dir(shift) },
    'Path::Class' => sub { Path::Class::Dir->new(shift) },
    'Path::Tiny'  => sub { Path::Tiny->new(shift) },
);

my @classes = grep eval { require_module($_) }, sort keys %builder_for;

plan skip_all => "None of @{[ sort keys %builder_for ]} is installed"
  if !@classes;

my $dir = repository_from('basic');

for my $class (@classes) {
    my $obj = $builder_for{$class}->($dir);
    my $db = Git::Database->new( store => $obj );
    isa_ok( $db, 'Git::Database::Backend::Git::Sub', "Backend for $class" );

    # some minimal test
    my $blob = $db->get_object('b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
    isa_ok( $blob, 'Git::Database::Object::Blob' );
    is( $blob->content, 'hello', 'content is "hello"' );

    isa_ok( $db->store, ref $obj, $obj );
}

done_testing;
