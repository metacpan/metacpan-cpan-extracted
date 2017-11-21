#!/usr/bin/env perl

use strict;
use warnings;

# Want latest & greates Neaf, not the system's one!
use File::Basename qw(dirname);
use lib dirname(__FILE__)."/../lib";

use MVC::Neaf qw(:sugar);

my $dir = dirname(__FILE__);
$dir = "./$dir" unless $dir =~ m#^/#;

my @files = files_in_dir( $dir, qr/\d+-.*\.pl/ );

foreach my $file (@files) {
    scalar do "$dir/$file"
        or die $@ || "Failed to load '$dir/$file':".( $! || "for no reason");
};

# TODO callback introspection!
my $all = neaf->get_routes;

my @list;
foreach my $path (sort keys %$all) {
    my $descr = $all->{$path}{GET}{description} or next;
    $descr =~ /^Static/ and next;

    warn "Found $path - $descr";
    push @list, {
        path  => $path,
        descr => $descr,
    };
};

get '/' => sub {
    return {
        list => \@list,
        neaf => 'NEAF '.MVC::Neaf->VERSION,
    };
}, -view => 'TT', -template => \<<HTML;
<html>
<head>
    <title>List of examples - [% neaf | html %]</title>
</head>
<h1>List of examples - [% neaf | html %]</h1>
Click on each to see what they do.
<ul>
[% FOREACH item IN list %]
    <li>
        <a href="[% item.path | html %]">[% item.path | html %]</a>
        - [% item.descr | html %]
    </li>
[% END %]
</ul>
</html>
HTML

sub files_in_dir {
    my ($dir, $regex) = @_;

    opendir my $fd, $dir
        or die "Failed to read dir $dir: $!";

    return grep { /^$regex$/ } readdir $fd;
};

neaf->run;
