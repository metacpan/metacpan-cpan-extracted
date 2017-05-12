use strict;
use warnings;
use utf8;

use Carp ();
use IO::Handle;
use Test::More;
use Test::SharedFork;
use File::Find;
use File::Path qw/make_path remove_tree/;
use parent qw/Exporter/;
our @EXPORT_OK = qw/create_paths touch delete_paths cmp_files get_filelist/;
our @EXPORT = qw/test_fork parent child/;

sub import {
    my $class = shift;
    $class->export_to_level(1, @_);
    strict->import;
    warnings->import;
    utf8->import;
    Test::More->import;
}

sub create_paths {
    my @test_paths = @_;

    my @dirs  = sort { length($a =~ m{/}g) < length($b =~ m{/}g) } grep { $_ =~ m{/$} } @test_paths;
    my @files = grep { $_ !~ m{/$} } @test_paths;

    make_path(@dirs, +{
        mode => 0777,
    });
    touch(@files);
}

sub touch {
    my @files = @_;
    foreach my $file (@files) {
        open my $fh, '>', $file or die $!;
        print $fh 'foo';
        close $fh;
    }
}

sub delete_paths {
    my @test_paths = @_;

    my @dirs  = grep { -d $_ } @test_paths;
    my @files = grep { -f $_ } @test_paths;

    unlink(@files);
    remove_tree(@dirs);
}

sub cmp_files {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my($files1, $files2) = @_;

    is_deeply [sort {$a cmp $b} @$files1] => [sort {$a cmp $b} @$files2], 'watching all file';
}

sub get_filelist {
    my $path = shift;
    my @files;

    find +{
        wanted => sub { push @files => $File::Find::name },
        no_chdir => 1,
    } => $path;

    return @files;
}

sub parent (&);
sub child (&);
sub test_fork (&) {## no critic
    my $code = shift;

    my $child_code;
    my $parent_code;
    {
        local *child = sub (&) {## no critic
            $child_code = shift;
        };
        local *parent = sub (&) {## no critic
            $parent_code = shift;
        };
        $code->();
    }

    pipe(my $child_rdr,   my $parent_wtr);
    pipe(my $parent_rdr,  my $child_wtr);
    $parent_wtr->autoflush(1);
    $child_wtr->autoflush(1);

    if ($parent_code and $child_code) {
        my $pid = fork;
        if ($pid == 0) {
            Test::SharedFork->child;
            close $parent_rdr;
            close $parent_wtr;
            $child_code->($child_rdr, $child_wtr);
            close $child_rdr;
            close $child_wtr;
            exit(0);
        }
        elsif ($pid != 0) {
            Test::SharedFork->parent;
            close $child_rdr;
            close $child_wtr;
            $parent_code->($parent_rdr, $parent_wtr);
            close $parent_rdr;
            close $parent_wtr;
            waitpid $pid, 0;
        }
        else {
            die $!;
        }
    }
    else {
        Carp::croak 'parent code or child code not found.';
    }
}

1;
