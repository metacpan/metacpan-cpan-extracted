#!/usr/bin/env perl

use strict;
use warnings;

# Want latest & greates Neaf, not the system's one!
use File::Basename qw(dirname basename);
use lib dirname(__FILE__)."/../lib";

use MVC::Neaf;

my $dir = dirname(__FILE__);
$dir = "./$dir" unless $dir =~ m#^/#;

my @files = files_in_dir( $dir, qr/\d+-.*\.pl/ );

foreach my $file (@files) {
    scalar do "$dir/$file"
        or die $@ || "Failed to load '$dir/$file':".( $! || "for no reason");
};

my @list;
neaf->get_routes(sub {
    my ($route, $path, $method) = @_;

    my $descr = $route->{description};
    return unless $method eq 'GET' and $descr and $descr !~ /^Static/;

    push @list, {
        path  => $path,
        descr => $descr,
    };
});

@list = sort { $a->{path} cmp $b->{path} } @list;
warn basename(__FILE__).": Found $_->{path} - $_->{descr}\n"
    for @list;

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
