#!/usr/bin/env perl
use strict;
use Cwd qw(abs_path cwd);
use Scope::Guard qw(guard);

my $dir = "smhasher";
if ( ! -d $dir ) {
    system "svn checkout http://smhasher.googlecode.com/svn/trunk smhasher";
}

my $pwd   = abs_path( cwd() );
{
    my $guard = guard { chdir $pwd };
    chdir $dir;
    system "svn update";
}

my $src = "src";
my @files = qw(MurmurHash3.cpp MurmurHash3.h);
foreach my $file ( @files ) {
    open my $dst, '>', "$src/$file" or die;
    open my $org, '<', "$dir/$file" or die;

    while ( <$org> ) {
        s/\r\n/\n/;
        print $dst $_;
    }
}