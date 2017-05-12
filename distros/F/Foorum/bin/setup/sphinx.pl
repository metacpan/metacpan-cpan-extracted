#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use Cwd qw/abs_path/;
use YAML::XS qw/LoadFile/;
use File::Path;
use File::Spec;

my $path = abs_path( File::Spec->catdir( $FindBin::RealBin, '..', '..' ) );

print "You are going to configure Sphinx for foorum.\n",
    '=' x 50,
    "\nPlease report bugs to AUTHORS if u meet any problem.\n\n";

my $module_installed
    = eval 'use Sphinx::Search;1;';    ## no critic (ProhibitStringyEval)
unless ($module_installed) {
    print "Please cpan Sphinx::Search first!\n\n";
}

my $config = LoadFile( File::Spec->catfile( $path, 'foorum_local.yml' ) );
my $dsn    = $config->{dsn};
my $user   = $config->{dsn_user};
my $pass   = $config->{dsn_pwd};

# $dsn = 'DBI:mysql:database=foorum;host=mysql.foorumbbs.com;port=3306';
my $host = 'localhost';
my $port = 3306;
if ( $dsn =~ /host=([^\;]+)/is ) {
    $host = $1;
}
if ( $dsn =~ /port=(\d+)/ ) {
    $port = $1;
}

open( my $fh, '<',
    File::Spec->catfile( $path, 'conf', 'examples', 'sphinx.conf' ) )
    or die $!;
local $/ = undef;
my $content = <$fh>;
close($fh);

$content =~ s/__HOST__/$host/isg;
$content =~ s/__USER__/$user/isg;
$content =~ s/__PASS__/$pass/isg;
$content =~ s/__PORT__/$port/isg;
$content =~ s/__HOME__/$path/isg;

open( my $fh2, '>', File::Spec->catfile( $path, 'conf', 'sphinx.conf' ) )
    or die $!;
print $fh2 $content;
close($fh2);

unless ( -d File::Spec->catdir( $path, 'log' ) ) {
    mkpath(
        [ File::Spec->catdir( $path, 'log' ) ],    ## no critic
        0, 0777    ## no critic (ProhibitLeadingZeros)
    );             ## no critic (ProhibitLeadingZeros)
}
unless ( -d File::Spec->catdir( $path, 'data', 'sphinx' ) ) {
    mkpath(
        [ File::Spec->catdir( $path, 'data', 'sphinx' ) ],    ## no critic
        0, 0777    ## no critic (ProhibitLeadingZeros)
    );             ## no critic (ProhibitLeadingZeros)
}

print "Configure is saved: $path/conf/sphinx.conf\n",
    "You can edit it later or run this script again\n",
    "Please use\nindexer --all --config $path/conf/sphinx.conf\nOR\n",
    "searchd --config $path/conf/sphinx.conf\n";

print '=' x 50, "\nDone!\n", "Thanks For Join US!\n";

1;
