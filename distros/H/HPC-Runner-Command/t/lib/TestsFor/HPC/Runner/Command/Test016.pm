package TestsFor::HPC::Runner::Command::Test016;

use strict;
use warnings;

use Test::Class::Moose;
use HPC::Runner::Command;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use File::Slurp;
use File::Spec;
use File::Temp qw/ tempfile /;
use Path::Tiny;
use Archive::Tar;
use File::Find::Rule;

extends 'TestMethods::Base';

=head2 Purpose

Test archiving file facilities

=cut

sub construct {
    my $self = shift;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();

    MooseX::App::ParsedArgv->new( argv => ["archive"] );

    my $test = HPC::Runner::Command->new_with_command();
    return $test;
}

sub test_001 : Tags(use_batches) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    make_path('exclude_this_dir');
    make_path('include_this_dir');
    make_path('.some_dot_dir');

    my $file =
      File::Spec->catdir( 'include_this_dir', 'include_this_file.txt' );

    write_file( $file, 'HELLO' ) or diag('We couldnt write the file');
    ok( path($file)->exists, 'File Exists' );

    $test->exclude_paths( ['exclude_this_dir'] );
    $test->include_paths( ['this_path_does_not_exist'] );
    my $files = $test->list_dirs;

    is_deeply(
        $files,
        [
            path('.some_dot_dir'), path('include_this_dir'),
            path('script'),        path('this_path_does_not_exist'),
        ],
        'exclude dirs excluded'
    );

    my $exists = $test->check_dirs_exist($files);
    is_deeply( $exists,
        [ path('.some_dot_dir'), path('include_this_dir'), path('script'), ],
        , 'Only the dirs that exist!' );
    ok(1);

    $test->create_archive($exists);

    my $tar = Archive::Tar->new;
    $tar->read( $test->archive );

    my @tar_files = $tar->list_files;
    @tar_files = sort(@tar_files);
    @tar_files = map { path($_) } @tar_files;
    is_deeply(
        \@tar_files,
        [
            path('.some_dot_dir'), path('include_this_dir'),
            path($file),           path('script'),
        ]
    );
    ok( $tar->contains_file($file), 'Tar archive contains the file.' );

    my $content = $tar->get_content($file);
    is( $content, 'HELLO', 'Content is ok' );

    chdir($Bin);
    remove_tree($test_dir);
}

1;
