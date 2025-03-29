#!/usr/bin/perl

# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Example demonstrating interaction with the store from a CGI script

use strict;
use warnings;

use File::FStore;
use CGI::Simple;
use Template;
use URI;

my %_domain_keys = (
    properties => [qw(size inode contentise mediasubtype media_type)],
    digests => [
        qw(md-5-128 sha-1-160),
        (map {'sha-2-'.$_, 'sha-3-'.$_} 224, 256, 384, 512),
    ],
);

my $store = File::FStore->new(path => $ENV{FSTORE_PATH});
my %cgi;
{
    my $cgi = CGI::Simple->new;
    foreach my $key ($cgi->param) {
        $cgi{$key} = $cgi->param($key);
    }
}

# defaults:
$cgi{limit}  //= 150;
$cgi{order}  //= 'asc';
$cgi{offset} //= 0;
$cgi{mode}   //= 'list';

eval {
    my @query;
    my @files;
    my $file;
    my %res;

    foreach my $key (qw(dbname)) {
        my $v = $cgi{$key} or next;
        push(@query, $key => $v);
    }

    foreach my $domain (qw(properties digests)) {
        foreach my $key (@{$_domain_keys{$domain}}) {
            my $v = $cgi{$domain.'.'.$key} or next;
            push(@query, $domain => $key => $v);
        }
    }

    @query = qw(all) unless scalar @query;
    @files = $store->query(
        @query,
        limit  => $cgi{limit} + 1,
        order  => $cgi{order},
        offset => $cgi{offset},
    );
    if (scalar(@files) > $cgi{limit}) {
        $#files--;
        $res{have_more} = 1;
    }

    if ($cgi{mode} eq 'download') {
        my $fh = $files[0]->open;
        my $mediasubtype = eval { $files[0]->get(properties => 'mediasubtype')} // # primary key
            eval { $files[0]->get(properties => 'media_type')} // # old versions seems to use this
            'application/octet-stream'; # fallback
        my $size = ($files[0]->stat)[7];
        local $/ = \65536;

        print 'Content-type: ', $mediasubtype, "\x0D\x0A";
        print 'Content-length: ', $size, "\x0D\x0A";
        print "\x0D\x0A";

        $fh->binmode; # enter binary mode before transfer.

        print $_ while <$fh>;
    } else {
        my $tt = Template->new;

        print "Content-type: text/html\x0D\x0A";
        print "\x0D\x0A";

        if ($cgi{mode} eq 'single') {
            $res{single} = $files[0];
            $res{stat_order} = [0..12];
            $res{stat_keys}  = {
                0   => 'Device number',
                1   => 'Inode number',
                2   => 'File mode',
                3   => 'Link counter',
                4   => 'User ID',
                5   => 'Group ID',
                6   => 'Represented device number',
                7   => 'File size',
                8   => 'Access time',
                9   => 'Modify time',
                10  => 'Change time',
                11  => 'Block size',
                12  => 'Number of blocks',
            };
        }

        $tt->process(\*DATA, {
                %res,
                ENV => \%ENV,
                cgi => \%cgi,
                files => \@files,
                slashbreak => sub { $_[0] =~ s#/#/\n#gr },
                sortedkeys => sub { sort keys %{$_[0]} },
                updatedlink => sub {
                    my (%updates) = @_;
                    my %link = (%cgi, %updates);
                    my $u = URI->new('?', 'https');
                    $u->query_form(%link);
                    return $u;
                },
                basename => sub { $_[0] =~ s#^.*/##r },
            });
    }
};

$store->close;

#ll
__DATA__
<!DOCTYPE html>
<html>
    <head>
        <title>Store: [% ENV.FSTORE_PATH | html %]</title>
        <meta charset="utf-8">
        <style>
        * {
            vertical-align: top;
        }
        th {
            white-space: nowrap;
        }
        body {
            background: beige;
            margin: 1em;
            margin-top: 0;
        }
        body, a:link, a:visited {
            color: black;
            text-decoration: none;
        }
        h1 {
            margin-top: 0;
        }
        ul, menu {
            display: flex;
            list-style: none;
            flex-wrap: wrap;
        }
        li, body > table {
            background: lightblue;
            min-width: 380px;
        }
        li {
            margin: 5px;
        }
        menu > li {
            min-width: 120px;
        }
        li:hover {
            background: darkviolet;
        }
        li:target:not(:hover) {
            background: violet;
        }
        li > a {
            display: block;
        }
        li h3 {
            white-space: break-spaces;
            margin: 3px;
            padding-left: 1em;
            text-indent: -1em;
        }
        th:not([colspan]) {
            text-align: left;
        }
        .float-right {
            float: right;
            margin-right: 3px;
        }
        .inline-buttonbox {
            display: inline-block;
        }
        .buttonbox > a, .inline-buttonbox > a, .button {
            margin: 2px;
            background: #ccff00;
            min-width: 1.4em;
            min-height: 1.4em;
            text-align: center;
            display: inline-block;
            border-radius: 5px;
            font-size: 80%;
        }
        </style>
    </head>
    <body id="top">
        <h1>Store: [% ENV.FSTORE_PATH | html %]</h1>

        [% IF single %]
        <div class="float-right buttonbox">
            <a href="?dbname=[% single.dbname | uri %]&amp;mode=download" title="view">&#128462;</a>
            <a href="?dbname=[% single.dbname | uri %]&amp;mode=download" title="download" download="[% basename(single.dbname) | html %]">&#128190;</a>
        </div>
        <h2>File: [% single.dbname | html %]</h2>
        [% data = single.get %]
        <table>
            [% FOREACH domain IN ['properties', 'digests'] %]
            <tr id="single-domain-[% domain | html %]">
                <th colspan="2">
                    Domain: [% domain | html %]
                    <div class="inline-buttonbox">
                        <a href="#single-domain-[% domain | html %]">&#9875;</a>
                        <a href="#top">&#128285;</a>
                    </div>
                </th>
            </tr>
            [% FOREACH key IN sortedkeys(data.$domain) %]
            <tr>
                <th>[% key | html %]</th>
                <td>[% data.$domain.$key | html %] <a href="?[% domain | uri %].[% key | uri %]=[% data.$domain.$key | uri %]" class="button">&#128269;</a></td>
            </tr>
            [% END %]
            [% END %]
            <tr id="single-stat">
                <th colspan="2">
                    Stat:
                    <div class="inline-buttonbox">
                        <a href="#single-stat">&#9875;</a>
                        <a href="#top">&#128285;</a>
                    </div>
                </th>
            </tr>
            [% FOREACH key IN stat_order %]
            [% IF single.stat.$key %]
            <tr>
                <th>[% stat_keys.$key | html %]</th>
                <td>[% single.stat.$key | html %]</td>
            </tr>
            [% END %]
            [% END %]
        </table>
        [% ELSE %]
        <h2>Entries:</h2>
        <menu>
            <li><a href="[% updatedlink('order', 'asc') | html %]">order ASC &#8593;</a></li>
            <li><a href="[% updatedlink('order', 'desc') | html %]">order DESC &#8595;</a></li>
            <li><a href="[% updatedlink('limit', 50) | html %]">limit 50</a></li>
            <li><a href="[% updatedlink('limit', 150) | html %]">limit 150</a></li>
            <li><a href="[% updatedlink('limit', 250) | html %]">limit 250</a></li>
            [% IF cgi.offset %]<li><a href="[% updatedlink('offset', 0) | html %]">offset 0 &#9198;</a></li>[% END %]
            [% n = cgi.offset - cgi.limit %][% IF n > 0 %]<li><a href="[% updatedlink('offset', n) | html %]">offset [% n | html %] &#9194;</a></li>[% END %]
            [% n = cgi.offset + cgi.limit %][% IF n > 0 and have_more %]<li><a href="[% updatedlink('offset', n) | html %]">offset [% n | html %] &#9193;</a></li>[% END %]
            <li><a href="?">Reset filter &#128473;</a></li>
        </menu>
        <ul>
        [% FOREACH file IN files %]
        [% properties = file.get('properties') %]
        <li [% IF properties.contentise %]id="contentise-[% properties.contentise | html %]"[% END %]>
        <div class="float-right buttonbox">
            <a href="?dbname=[% file.dbname | uri %]&amp;mode=download" title="view">&#128462;</a>
            <a href="?dbname=[% file.dbname | uri %]&amp;mode=download" title="download" download="[% basename(file.dbname) | html %]">&#128190;</a>
            [% IF properties.contentise %]<a href="#contentise-[% properties.contentise | html %]">&#9875;</a>[% END %]
            <a href="#top">&#128285;</a>
        </div>
        <a href="?dbname=[% file.dbname | uri %]&amp;mode=single">
        <h3>[% slashbreak(file.dbname) | html%]</h3>
        <table>
            [% FOREACH key IN ['size', 'inode', 'contenise', 'mediasubtype'] %]
            [% IF properties.$key %]
            <tr>
                <th>[% key | html %]</th>
                <td>[% properties.$key | html %] <a href="?properties.[% key | uri %]=[% properties.$key | uri %]" class="button">&#128269;</a></td>
            </tr>
            [% END %]
            [% END %]
        </table>
        </a>
        </li>
        [% END %]
        </ul>
        [% END %]
    </body>
</html>
