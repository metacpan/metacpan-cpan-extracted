use warnings;
use strict;
use Test::More tests => 34;
use Test::Exception;
use Test::Warnings qw(:all);
use File::Spec;

use Jenkins::i18n::ProcOpts;

my $class = 'Jenkins::i18n::ProcOpts';

my @expected_methods = (
    'new',            'inc',            'use_counter',  'get_counter',
    'is_remove',      'is_add',         'is_debug',     'get_language',
    'get_source_dir', 'get_target_dir', 'is_to_search', 'search_term'
);

can_ok( $class, @expected_methods );
my $source = File::Spec->catdir( File::Spec->rootdir(), 'foo' );
my $target = File::Spec->catdir( File::Spec->rootdir(), 'bar' );

dies_ok {
    Jenkins::i18n::ProcOpts->new( $source, $target, 1, 0, 0, 0, 'pt_BR' )
}
'new() dies receives something else than a hash refence as parameter';
like( $@, qr/hash/, 'got the expected error message' );

my %new_params = (
    source_dir  => $source,
    target_dir  => $target,
    use_counter => 1,
    is_remove   => 1,
    is_add      => 1,
    is_debug    => 0,
    lang        => 'pt_BR',
    search      => 'foobar'
);

dies_ok { Jenkins::i18n::ProcOpts->new( \%new_params ) }
'dies with both removing and adding is configured';
like( $@, qr/excluding\soperations/, 'got the expected error message' );

$new_params{is_add}    = 0;
$new_params{is_remove} = 0;
$new_params{search}    = undef;
my $instance = Jenkins::i18n::ProcOpts->new( \%new_params );
isa_ok( $instance, $class );
my @attribs = sort( keys( %{$instance} ) );
is_deeply(
    \@attribs,
    [
        'counter',    'ext_sep',   'has_search', 'is_add',
        'is_debug',   'is_remove', 'language',   'source_dir',
        'target_dir', 'use_counter'
    ],
    'instance has the expected attributes'
) or diag( explain( \@attribs ) );
is( $instance->get_counter, 0, 'got the expected files counter' );
ok( $instance->inc, 'can invoke inc' );
is( $instance->get_counter, 1, 'got the expected files counter' );
ok( $instance->use_counter, 'file counter is in use' );
is( $instance->is_remove,    0,       'file removal is disabled' );
is( $instance->is_add,       0,       'file addition is disabled' );
is( $instance->is_debug,     0,       'debugging is disabled' );
is( $instance->get_language, 'pt_BR', 'get_language() works as expected' );
is( $instance->get_source_dir, $source,
    'get_source_dir() works as expected' );
is( $instance->get_target_dir, $target,
    'get_target_dir() works as expected' );
is( $instance->is_to_search, 0, 'is_to_search() works as expected' );

note('Switching target_dir');
my $jelly_file = 'message.jelly';
my $jelly_path = File::Spec->catfile( $source, $jelly_file );

foreach my $new_target ( ( $source, $target ) ) {
    note("Using $new_target as target directory, source as $source");
    $new_params{target_dir} = $new_target;
    my $instance2 = Jenkins::i18n::ProcOpts->new( \%new_params );
    my $file_in   = File::Spec->catfile( $source, 'message.properties' );
    my $file_out
        = File::Spec->catfile( $new_target, 'message_pt_BR.properties' );
    my %expected_files = (
        $file_in    => [ $file_out, $file_in, $jelly_path ],
        $jelly_path => [ $file_out, $file_in, $jelly_path ],
    );

    my $counter = 1;

    foreach my $file_path ( keys(%expected_files) ) {
        note("Test case #$counter: using $file_path to test define_files()");
        my @files = $instance2->define_files($file_path);
        is( scalar(@files), 3, 'define_files returns 3 files path' );
        is_deeply( \@files, $expected_files{$file_path},
'got the expected results from define_files() with a given file type'
        ) or diag( explain( \@files ) );
        $counter++;
    }
}

note('Testing with long paths');
$source = File::Spec->catdir( File::Spec->rootdir(), 'home', 'foobar',
    'Projects', 'jenkins' );
my $relative_path = File::Spec->catdir(
    'jenkins',   'cli',    'src', 'main',
    'resources', 'hudson', 'cli', 'client'
);
my $input
    = File::Spec->catfile( $source, $relative_path, 'Messages.properties' );
$new_params{source_dir} = $source;
$new_params{target_dir} = $source;
$instance               = Jenkins::i18n::ProcOpts->new( \%new_params );
my @files = $instance->define_files($input);
is_deeply(
    \@files,
    [
        File::Spec->catfile(
            $source, $relative_path, 'Messages_pt_BR.properties'
        ),
        $input,
        File::Spec->catfile( $source, $relative_path, 'Messages.jelly' )
    ],
    'got the expected results from define_files() with source = target'
) or diag( explain(@files) );

$target = File::Spec->catdir( File::Spec->rootdir(), 'home', 'barfoo',
    'Projects', 'jenkins' );
$new_params{target_dir} = $target;
$instance               = Jenkins::i18n::ProcOpts->new( \%new_params );
@files                  = $instance->define_files($input);
is_deeply(
    \@files,
    [
        File::Spec->catfile(
            $target, $relative_path, 'Messages_pt_BR.properties'
        ),
        $input,
        File::Spec->catfile( $source, $relative_path, 'Messages.jelly' )
    ],
    'got the expected results from define_files source != target'
);

note('New instance with file counter disabled and a search term');
$new_params{use_counter} = 0;
$new_params{search}      = '[Bb]uild';
$instance                = Jenkins::i18n::ProcOpts->new( \%new_params );
my $result;
like( warning { $result = $instance->inc },
    qr/^Useless/, 'got expected warning' );
is( $result,                 0, 'inc returns false' );
is( $instance->is_to_search, 1, 'is_to_search() works as expected' );
is( ref( $instance->search_term ),
    'Regexp', 'search_term() returns a regular expression' );

note('Testing files at the current directory');
$input = 'build.jelly';
@files = $instance->define_files($input);
is_deeply(
    \@files,
    [ 'build_pt_BR.properties', 'build.properties', $input, ],
    'got the expected results from define_files source != target'
);

# -*- mode: perl -*-
# vi: set ft=perl :
