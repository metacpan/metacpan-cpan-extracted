#!/usr/bin/env perl

# This example demonstrates forms with unforeknown fields.
# We only know how the fields would look like, but not the exact list;
#    collect ALL such fields, organize them in tuples, and
#    show the form again with ability to add even more fields.

use strict;
use warnings;

use MVC::Neaf qw(:sugar);

my $tpl = <<'HTML';
<html>
<head>
    <title>[% title | html %] - [% file | html %]</title>
    <style>
        .error {
            border: red solid 1px;
        }
    </style>
</head>
<body>
    <h1>[% title | html %]</h1>
    [% IF is_valid %]
        <h1>Guests welcome!</h2>
    [% END %]
    <form name="guest" method="POST">
        [% FOREACH item IN guest_list %]
            <div[% IF item.error %] class="error"[% END %]>
                Guest [% item.id %]: <i>name as word(s), arrival as time</i><br>
                <input name="name[% item.id %]" value="[% item.name | html %]">
                <input name="stay[% item.id %]" value="[% item.stay | html %]">
            </div>
        [% END %]
        Add guest [% last_index %]: <i>name as word(s), arrival as time</i><br>
        <input name="name[% last_index %]">
        <input name="stay[% last_index %]">
        <br>
        <input type="submit" value="Submit guests">
    </form>
</body>
HTML

# Define form spec. This will be compiled once and applied to
#    multiple requests.
neaf form => guest => (
    [ [ 'name\d+' => '\w+( +\w+)*' ], [ 'stay\d+' => '\d+:\d+' ] ],
    engine => 'Wildcard',
);

get+post '/12/wildcard' => sub {
    my $req = shift;

    # Get form object, all data inside
    my $guest = $req->form("guest");

    # Clusterize the data
    my %tuples;
    foreach ($guest->fields) {
        /^(\w+)(\d+)$/ or die "How is this even possible?";
        $tuples{$2}{$1} = $guest->raw->{$_};
        $tuples{$2}{error}++ if $guest->error->{$_};
        $tuples{$2}{id} = $2; # redundant, but simplifies processing
    };

    # Listify the data
    my @list = sort { $a->{id} <=> $b->{id} }
        grep { $_->{name} } values %tuples;

    # ... and return it for good
    return {
        guest_list => \@list,
        last_index => @list ? ($list[-1]{id} + 1) : 1,
        is_valid   => !grep { $_->{error} } @list,
    };
}, default => {
    -view     => 'TT',
    -template => \$tpl,
     title    => 'Unforeknown form fields',
     file     => 'example/12 NEAF '.neaf->VERSION,
}, description => 'Unforeknown form fields';

neaf->run;

