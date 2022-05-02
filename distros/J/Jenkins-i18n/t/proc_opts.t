use warnings;
use strict;
use Test::More;
use Test::Exception;
use Test::Warnings qw(:all);

use Jenkins::i18n::ProcOpts;

my $class = 'Jenkins::i18n::ProcOpts';
can_ok( $class,
    qw(new inc use_counter get_counter is_remove is_add is_debug get_language)
);
dies_ok { Jenkins::i18n::ProcOpts->new( 'foo', 'bar', 1, 1, 1, 0, 'foobar' ) }
'dies with both removing and adding is configured';
like( $@, qr/excluding\soperations/, 'got the expected error message' );
dies_ok { Jenkins::i18n::ProcOpts->new } 'dies with missing parameters';
like( $@, qr/must\sreceive/, 'got the expected error message' );
my $instance
    = Jenkins::i18n::ProcOpts->new( '/foo', '/bar', 1, 0, 0, 0, 'pt_BR' );
isa_ok( $instance, $class );
my @attribs = sort( keys( %{$instance} ) );
is_deeply(
    \@attribs,
    [
        'counter',  'is_add',     'is_debug',   'is_remove',
        'language', 'source_dir', 'target_dir', 'use_counter'
    ],
    'instance has the expected attributes'
);
is( $instance->get_counter, 0, 'got the expected files counter' );
ok( $instance->inc, 'can invoke inc' );
is( $instance->get_counter, 1, 'got the expected files counter' );
ok( $instance->use_counter, 'file counter is in use' );
is( $instance->is_remove,    0,       'file removal is disabled' );
is( $instance->is_add,       0,       'file addition is disabled' );
is( $instance->is_debug,     0,       'debugging is disabled' );
is( $instance->get_language, 'pt_BR', 'get_language() works as expected' );
is( $instance->get_source,   '/foo',  'get_source() works as expected' );
is( $instance->get_target,   '/bar',  'get_target() works as expected' );

foreach my $target (qw(/foo /bar)) {
    note("Using $target as target directory");
    my $instance2 = Jenkins::i18n::ProcOpts->new( '/foo', $target, 1, 0, 0, 0,
        'pt_BR' );
    my %expected_files = (
        '/foo/message.properties' =>
            [ "$target/message_pt_BR.properties", '/foo/message.properties' ],
        '/foo/message.jelly' =>
            [ "$target/message_pt_BR.properties", '/foo/message.properties' ],
    );

    foreach my $file_path ( keys(%expected_files) ) {
        my @files = $instance2->define_files($file_path);
        is_deeply( \@files, $expected_files{$file_path},
'got the expected results from define_files() with a given file type'
        ) or diag( explain( \@files ) );
    }
}

note('New instance with file counter disabled');
$instance
    = Jenkins::i18n::ProcOpts->new( 'foo', 'bar', 0, 0, 0, 0, 'foobar' );
my $result;
like( warning { $result = $instance->inc },
    qr/^Useless/, 'got expected warning' );
is( $result, 0, 'inc returns false' );

done_testing;

# -*- mode: perl -*-
# vi: set ft=perl :
