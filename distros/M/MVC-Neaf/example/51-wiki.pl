#!/usr/bin/env perl

#####################################################
#  This example shows a real primitive Wiki engine   #
#  running under Neaf.                              #
#  It was originally written to demonstrate          #
#  the path_info() method.                          #
#                                                    #
#  Since it uses no persistent storage,             #
#  it should be run as one-threaded PSGI app         #
#  to be of any use.                                #
######################################################

use strict;
use warnings;
use FindBin qw($Bin);
use URI::Escape;
use JSON;

# always use latest and greatest Neaf
my $Bin;
use File::Basename qw(basename dirname);
BEGIN { $Bin = dirname(__FILE__); };
use lib "$Bin/../lib";
use MVC::Neaf;

# Define some escaping routines first
# (Should these really be part of # View::TT?)
# I'm not using HTML::Entities since it's not used
# in the library itself as of current
my %replace = (qw( < &lt; > &gt; & &amp; " &quot; ));
my $replace_re = join "", "[", keys %replace, "]";
$replace_re = qr/$replace_re/;
sub html {
    my $str = shift;
    $str =~ s/($replace_re)/$replace{$1}/g;
    return $str;
};

# Now some templates.
# The head/foot part is also TDB in View::TT.
my $head = <<"TT";
<html>
<head>
    <title>[% topic | html %] - [% action %]</title>
</head>
<html>
[% IF topic %]<h1>[% topic | html %]</h1>[% END %]
<form method="GET" action="/wiki_forms/search">
    <input name="q"[% IF query %] value="[% query | html %][% END %]">
    <input type="submit" value="Search!">
</form>
TT

my $show = <<"TT";
$head
<a href="/wiki_forms/edit?topic=[% topic | uri %]">
    [%- IF article %]Edit[% ELSE %]Start[% END %]</a></br>
<div>
[% article %]
</div>
TT

my $edit = <<"TT";
$head
<form method="POST" action="/wiki_forms/update">
<input type="hidden" name="topic" value="[% topic | html %]"><br>
<textarea name="article" rows="10" cols="65">[% article | html %]</textarea><br>
<input type="submit" value="Save">
</form>
TT

my $search = <<"TT";
$head
<ol>
[% FOREACH item IN result %]
    <li><a href="/wiki/[% item.0 | uri %]">
        [% item.1  | html %]
        <span style="color: red">[% item.2  | html %]</span>
        [% item.3  | html %]
    </a></li>
[% END %]
</ol>
TT

# Your favourite key-value persistent storage should be here!
my $art = {};

# Load-save data to a plain file between runs.
my $save = "$Bin/nocommit-".basename(__FILE__).".js";
$SIG{INT} = sub { exit(0); }; # exit normally on interrupt
if (-f $save) {
    eval {
        open my $fd, "<", $save
            or die "$!: $save";
        local $/;
        $art = decode_json(<$fd>);
    };
    warn "Going without content: load failed: $@"
        if $@;
};
END {
    eval {
        open my $fd, ">", $save
            or die "$!: $save";
        print $fd encode_json($art);
        close $fd or die "$!: $save";
    };
    warn "Couldn't save content: $@"
        if $@;
};

# Display article
MVC::Neaf->route( wiki => sub {
    my $req = shift;

    # This whole 100+-line example was made for the next line!
    my $topic = $req->path_info( );
    length $topic or $req->redirect( $req->script_name . "/Main%20page" );

    # Get some wiki formatting. Don't want to spend too much on it.
    my $article = $art->{$topic} || '';
    $article =~ s#\s*\n\s*\n\s*#\n<br><br>\n#gs; # tex paragraph
    $article =~ s#\[([^\]]+)\]#'<a href="/wiki/'.uri_escape_utf8($1).'">'.html($1).'</a>'#ge; # links

    return {
        -template => \$show,
        topic => $topic,
        action => "Wiki",
        article => $article,
    };
}, description => "A 200-line stupid Wiki engine", path_info_regex => '.*' );

# Update article - POST only, redirect in the end.
MVC::Neaf->route( wiki_forms => update => sub {
    my $req = shift;

    $req->method eq 'POST' or die 404;

    my $topic = $req->param( topic => '[^<>&]+' );
    my $article = $req->param( article => '.*', undef );
    defined $topic and defined $article or die 422;

    $art->{$topic} = $article;
    $req->redirect( "/wiki/" . uri_escape_utf8( $topic ) );
});

# Edit article. Not really much to discuss here...
MVC::Neaf->route( wiki_forms => edit => sub {
    my $req = shift;

    my $topic = $req->param( topic => '[^<>&]+' );
    my $article = $art->{$topic};
    defined $topic or die 422;

    return {
        -template => \$edit,
        article => $article,
        action => "Edit",
        topic => $topic,
    };
});

# Make the wiki searchable
MVC::Neaf->route( wiki_forms => search => sub {
    my $req = shift;

    my $q = $req->param( q => qr/.*/, '' );
    $q =~ s/\s+/\\s+/g;
    $q =~ s/\(/\(?:/g;

    my @ret;
    foreach (keys %$art) {
        /^(.*?)($q)(.*)$/ or $art->{$_} =~ /(.{0,40})($q)(.{0,40})/s or next;

        push @ret, [ $_, $1, $2, $3 ];
    };

    return {
        -template => \$search,
        query => $q,
        result => \@ret,
        topic => "Search results for \"$q\"",
        action => "Wiki",
    };
});

# Bring the whole thing together.
MVC::Neaf->run;
