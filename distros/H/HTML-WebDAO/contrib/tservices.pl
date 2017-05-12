#!/usr/bin/perl
#===============================================================================
#
#         FILE: tservices.pl
#
#  DESCRIPTION:  Utils for test applictions from shell script for WebDAO project
#       AUTHOR:  Aliaksandr P. Zahatski , <zag@cpan.org>
#===============================================================================

use File::Basename;
use Data::Dumper;
use Cwd;
use strict;
sub get_envdir {
    my $name = shift || die "need env dir";
    my $curr_dir = getcwd;
    my $target_dir = "$curr_dir/t/$name";
    unless (-d $target_dir) { die " not exists path $target_dir" }
    $target_dir
}

sub main::prepare_env {
    my $name = shift || die "need env name";
    my $dir = get_envdir($name);
    eval "use lib qw( $dir);";
    my @auto_run;
    opendir ( DIR, $dir);
    while  ( my $file =  readdir DIR ) {
        next unless -x "$dir/$file";
        next unless $file =~ /^init/;
        push @auto_run,"$dir/$file"
    }
    close DIR;
    foreach my $file2run ( @auto_run ) {
        my $curr_dir = getcwd;
        chdir ($dir);
        local $!;
        if (my $rc = system $file2run ) {
            die "Exec $file2run: return code $rc\n";
        }
        chdir ($curr_dir);
        
    }
}

sub main::clean_env {
    my $name = shift || die "need env name";
    my $dir = get_envdir($name);
    my @auto_clean;
    opendir ( DIR, $dir);
    while  ( my $file =  readdir DIR ) {
        next unless -x "$dir/$file";
        next unless $file =~ /^clean/;
        push @auto_clean,"$dir/$file"
    }
    close DIR;
    foreach my $file2run ( @auto_clean ) {
        my $curr_dir = getcwd;
        chdir ($dir);
        local $!;
        if (my $rc = system $file2run ) {
            die "Exec $file2run: return code $rc\n";
        }
        chdir ($curr_dir);
        
    }
}

sub main::execute_test {
    my ($env_name, $file_name) = @_;
    my $dir = get_envdir($env_name);
    my $exec_cmd;
    my %tests_hash;
    opendir ( DIR, $dir);
    while  ( my $file =  readdir DIR ) {
        my $path = "$dir/$file";
        if ( $file =~ /run_test/ && -x $path ) {
            $exec_cmd = $path;
            next;
        }
        next unless $file =~ /\.t$/;
        $tests_hash{$file} = $path
    }
    close DIR;
    die "Not exists $dir/run_test.XX file in " unless $exec_cmd;
    die "Not found test" if $file_name and !exists( $tests_hash{$file_name} ) ;
    my @runtests = $file_name ? ($file_name) : sort {$a cmp $b } keys %tests_hash;
    foreach my $test (@runtests) {
      my $curr_dir = getcwd;
      chdir ($dir);
      local $!;
      if (my $rc = system "$exec_cmd $test" ) {
          die "Exec $test: return code $rc\n";
      }
      print "Exec $test: return code $! \n";
      chdir ($curr_dir);
     }
}
sub main::get_engine {
    my %args = @_;
    my $name = $args{env};
    prepare_env($name);

}
1;
