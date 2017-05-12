#!/usr/bin/env perl 
use strict;
use warnings;
use INI::ReadPath;
use Getopt::Long qw( GetOptions );

my %args = ();

GetOptions(
    "file=s"   => \$args{file},
    "string=s" => \$args{string},
    "env=s"    => \$args{env},
    "path=s"   => \$args{path},
);

my $path = $args{path}
    or exit;

my $file   = $args{file};
my $string = $args{string};
my $env    = $args{env} || q{};

$string ||= $ENV{$env};

my $reader = INI::ReadPath->new(
    ( $file   ? ( file   => $file )   : () ),
    ( $string ? ( string => $string ) : () ),
);

print $reader->get( $path );
