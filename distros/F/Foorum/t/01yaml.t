#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'use Test::YAML::Valid;';    ## no critic (ProhibitStringyEval)
    $@ and plan skip_all => 'Test::YAML::Valid is required for this test';

    eval 'use File::Next;';           ## no critic (ProhibitStringyEval)
    $@ and plan skip_all => 'File::Next is required for this test';
}

use Foorum::XUtils qw/base_path/;
use File::Spec;

my $base_path = base_path();

# XXX? since make test copy files to blib
$base_path =~ s/\/blib$//isg;

my @yml_files = ( File::Spec->catfile( $base_path, 'foorum.yml' ) );

# test conf/*.yml
my $files = File::Next::files( File::Spec->catdir( $base_path, 'conf' ) );
while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.ya?ml$/ );    # only .yml or .yaml
    push @yml_files, $file;
}

plan tests => scalar @yml_files;

foreach my $file (@yml_files) {
    yaml_file_ok( $file, "$file is valid" );
}

1;
