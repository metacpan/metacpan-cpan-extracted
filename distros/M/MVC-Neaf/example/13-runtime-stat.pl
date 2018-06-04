#!/usr/bin/env perl

# This script demonstrates the usage of hooks to gather runtime statistics.
# Also a simple web interface is provide for peeking at the data.
# Note that these RPS stats differ from those gathered by ab(1)
#    by a factor of roughly 1.5
# Would probably be closer to reality in case of real app with database
#    and lots of logic inside, though.

use strict;
use warnings;

use Time::HiRes qw(time);
use MVC::Neaf;

# This is only an example.
# Insert your favorite database writer here!
my %stat;
sub write_stat {
    my %opt = @_;
    $stat{ $opt{path} }{count} ++;
    $stat{ $opt{path} }{time}  += $opt{elapsed};
};

# Insert hooks as early as possible.
# NOTE We postpone as much processing as we can to the pre_cleanup stage
#      when the client is already served and (hopefully) happy.
#      Plus a faulty hook will not disrupt actual request processing.
# Set path => '/interesting' in all three of the below hooks
#      to limit statictics to just interesting path.
neaf pre_logic => sub { $_[0]->stash(start_time => time) };
neaf pre_reply => sub { $_[0]->stash(reply_time => time) };
neaf pre_cleanup => sub {
    my $req = shift;
    my $stash = $req->stash;

    # This is possible if we brokeout of execution before prelogic,
    #    e.g. on a "not found" error
    # Change pre_logic to pre_route in the above code if you want
    #    to measure 404's and 405's, too.
    return unless $stash->{start_time};
    write_stat(
        id       => $req->id,
        path     => $req->script_name,
        reply_in => $stash->{reply_time} - $stash->{start_time},
        elapsed  => time - $stash->{start_time},
    );
};

# Usual Neaf setup
neaf view => TT13 => 'TT';

# We don't even return the data, because it's possible with Neaf,
#    but still you're better of preprocessing it in this handler
#    e.g. to feed via JS
get '/13/stat' => sub { +{}}, default => {
    -view => 'TT13',
    -template => 'stat.html',
    title => 'Runtime statistics',
    file  => 'example/13 NEAF '.neaf->VERSION,
    stat  => \%stat,
}, public => 1, description => 'Runtime performance statictics';

neaf->load_resources(\*DATA); # Alas, not automatic (yet)
neaf->run;

__DATA__

@@ [TT13] stat.html

<html>
<head>
</head>
<body>
<h1>[% title | html %]</h1>
<table border="1" width="60%">
    <tr>
        <th width="100%">URI</th>
        <th>Hits</th>
        <th>Total(s)</th>
        <th>Average(s)</th>
        <th>RPS</th>
    </tr>
[% FOREACH uri IN stat.keys %]
    <tr>
        <td>[% uri | html %]</td>
        <td>[% stat.$uri.count %]</td>
        <td>[% stat.$uri.time %]</td>
        <td>[% stat.$uri.time / stat.$uri.count %]</td>
        <td>[% IF stat.$uri.time; stat.$uri.count / stat.$uri.time; END %]</td>
    </tr>
[% END %]
</table>
</body>
</html>
