#!/usr/bin/env perl

use strict;
use warnings;
use Encode;

# This script demonstrates...
my $descr  = "File upload";

# Always use latest and greatest Neaf, no matter what's in the @INC
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

# Add some flexibility to run alongside other examples
my $script = basename(__FILE__);

# And some HTML boilerplate.
my $tpl = <<"TT";
<html><head><title>$descr - $script</title></head>
<body><h1>$script</h1><h2>$descr</h2>
<h1>Content analysis of [% IF name %][% name %][% ELSE %]files[% END %].</h1>
<form method="POST" enctype="multipart/form-data">
    <input type="file" name="count">
    <input type="submit" value="&gt;&gt;">
</form>
[% IF top %]
    <hr>
    <h2>Most common words[% IF name; " in " _ name; END %]</h2>
    [% FOREACH record IN top %]
        [% record.0 %]: [% record.1 %]<br>
    [% END %]
[% END %]
TT

MVC::Neaf->route(cgi => $script => sub {
    my $req = shift;

    my @top;
    my $up = $req->upload("count");
    if ($up) {
        my $fd = $up->handle;
        my %count;
        while (<$fd>) {
            $_ = decode_utf8($_);
            $count{$_}++ for /(\w\w\w+)/g;
        };

        # transform hash into set of tuples; filter count > 1;
        # sort tuples by count, then alphabetically
        @top = sort { $b->[1] <=> $a->[1] or $a->[0] cmp $b->[0] }
            grep { $_->[1] > 1 }
            map { [ $_, $count{$_} ] }
            keys %count;
    };

    return {
        -template => \$tpl,
        size      => $up && $up->size,
        name      => $up && $up->filename,
        top       => @top ? \@top : undef,
    };
}, description => $descr);

MVC::Neaf->run;
