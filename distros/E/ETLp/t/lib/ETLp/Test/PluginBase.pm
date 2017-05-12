package ETLp::Test::PluginBase;

use strict;
use Test::More;
use Data::Dumper;
use Carp;
use FindBin qw($Bin);
use base (qw(ETLp::Test::Base ETLp::Test::DBBase));
use Try::Tiny;
use ETLp::Role::Config;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use File::Basename;
use ETLp;
use Carp;
use autodie;

sub new_args {
    (
        keep_logger     => 0,
        create_log_file => 0
    );
}

sub _general_ddl {
    return (
        q{
            create table stg_customer(
                first_name varchar(30),
                last_name varchar(30),
                email varchar(255),
                street varchar(255),
                city varchar(25),
                post_code varchar(10),
                state  varchar(25),
                country  varchar(50),
                file_id  integer
            )
        }
    );
}

sub _drop_general_ddl {
    #return;
    return (q{drop table stg_customer});
}

sub _get_app_root {
    my $self     = shift;
    my $app_root = "$Bin/app_root";
}

sub _app_dirs {
    my $self = shift;
    return qw(bin conf conf/control log lock data data/incoming data/archive
      data/fail);
}

sub create_test_environment : Test(setup) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    unless (-d $app_root) {
        mkdir $app_root || croak "Unable to create $app_root: $!";
    }

    foreach my $dir ($self->_app_dirs) {
        unless (-d "$app_root/$dir") {
            mkdir "$app_root/$dir";
        }
    }

    my $env_file = "$app_root/conf/env.conf";

    open(my $fh, '>', $env_file);
    print $fh "user = $ENV{USER}\n";

    if ($ENV{PASS}) {
        print $fh "password = $ENV{PASS}\n";
    } else {
        print $fh "password = \n";
    }
    print $fh "dsn = $ENV{DSN}\n";
    print $fh 'allow_env_vars = 1';
    close $fh;

    my $end_to_end = "$Bin/tests/end_to_end";

    foreach my $directory (qw/bin conf/) {
        dircopy("$end_to_end/$directory", "$app_root/$directory")
          || croak "unable to copy confguration files from "
          . "$end_to_end/$directory'"
          . " to $app_root: $!";
    }

    foreach my $file (glob("$Bin/test_data/customer*.csv.gz")) {
        copy $file, "$app_root/data/incoming" || croak $!;
    }
}

sub remove_test_environment : Test(teardown) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;
    $self->cleanup_dirs($app_root);
}

sub cleanup_dirs {
    my $self = shift;
    my $dir  = shift;
    local *DIR;

    opendir DIR, $dir or die "opendir $dir: $!";
    for (readdir DIR) {
        next if /^\.{1,2}$/;
        my $path = "$dir/$_";
        unlink $path if -f $path;
        $self->cleanup_dirs($path) if -d $path;
    }
    closedir DIR;
    rmdir $dir or print "error - $!";
}

1;
