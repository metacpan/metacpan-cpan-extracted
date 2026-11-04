package Fixture;

# ABSTRACT: Fixture checkouts and standards for the tests of Dist::Conformance

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';

use File::Find();
use File::Temp();
use FindBin();
use Mojo::File();

use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Source::Directory();
use Dist::Conformance::Update();

# The fixture standards in t/data/standards.
sub standards () {
    return Dist::Conformance::Source::Directory->new( directory => "$FindBin::Bin/data/standards" );
}

# A temporary checkout with a .git/hooks directory and %files, path => bytes.
sub checkout (%files) {
    my $root = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    $root->child(qw{.git hooks})->make_path;
    for my $path ( sort keys %files ) {
        my $file = $root->child( split m{/}, $path );
        $file->dirname->make_path;
        $file->spew( $files{$path} );
    }
    return $root;
}

# A check of $class with $config, reading the fixture standards, and named by the last part of the class.
sub make_check ( $class, $config, %variables ) {
    return $class->from_config( name => $class =~ s/\A.*:://r, config => $config, source => standards(), variables => \%variables );
}

# Runs the update of $check on $root, and returns the Update.
sub run_update ( $check, $root, $dry_run = 0 ) {
    my $update = Dist::Conformance::Update->new( snapshot => Dist::Conformance::Snapshot::Directory->new( root => $root ), dry_run => $dry_run );
    $check->update($update);
    return $update;
}

# Every file below $root, .git included, with its bytes and mode, to show that a dry run changed nothing.
sub tree_of ($root) {
    my %tree;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                my $file = Mojo::File->new($File::Find::name);
                return if -d $file;
                $tree{ $file->to_rel($root)->to_string } = [ $file->slurp, $file->stat->mode ];
            },
        },
        "$root",
    );
    return \%tree;
}

1;
