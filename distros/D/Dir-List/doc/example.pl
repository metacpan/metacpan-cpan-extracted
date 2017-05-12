#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Dir::List;

my $dir = Dir::List->new({
	use_cache => 1,
	exclude => [ qw/^pub$ ^welcome.msg$/ ],
});

my $path = '/var/tmp';
my $dirinfo = $dir->dirinfo($path);

print Dumper($dirinfo);

my $numdirs = scalar keys %{$dirinfo->{dirs}};
my $numfiles = scalar keys %{$dirinfo->{files}};

print "You have $numdirs directories and $numfiles files in $path\n";
print "This result came from the cache (created on $dirinfo->{cache_info}->{time_string})\n" if $dirinfo->{cache_info}->{cached};
