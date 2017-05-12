#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename qw(basename);
use lib "$Bin/../lib";
use MVC::Neaf;
use MVC::Neaf::X::Form;

$SIG{__DIE__} = sub { print STDERR "$_[0]\n" };

my $rules = MVC::Neaf::X::Form->new({
    name    => [ required => '\w+' ],
    email   => [ required => '\S+@\S+' ],
    email2  => [ required => '\S+@\S+' ],
    country => '..',
    age     => '\d+',
});

my $tpl = <<'TT';
<html>
<head>
    <title>Form validation and resubmit</title>
</head>
<body>
    <style>
        .error { color: red; }
        .ok    { color: green; }
    </style>
<h1>Form validation and resubmit</h1>
[% IF form.is_valid %]
<h2 class="ok">Form is valid, [% form.data.name | html %]</h2>
[% END %]
<form method="POST">
    Name: [% PROCESS input param="name" %]
    Email: [% PROCESS input param="email" %]
    Email again: [% PROCESS input param="email2" %]
    Age: [% PROCESS input param="age" %]
    Country: [% PROCESS input param="country" %]
    <input type="submit" value="Submit form">
</form>
</body></html>

[% BLOCK input %]
    <input name="[% param | html %]" value="[% form.raw.$param | html %]">
    [% IF form.error.$param %]
        <span class="error">[% form.error.$param | html %]</span>
    [% END %]
    <br>
[% END %]
TT

MVC::Neaf->route( cgi => basename(__FILE__) => sub {
    my $req = shift;

    my $form = $req->form( $rules );
    if ($form->data->{age}) {
        $form->data->{age} >= 18
            or $form->error( age => "Age must be 18+" );
    };

    if ($form->is_valid) {
        $form->data->{email} eq $form->data->{email2}
            or $form->error( "email" => "Addresses do not match" );
    };

    return {
        -template => \$tpl,
        form => $form,
    };
}, description => 'Form validation and resubmit');

MVC::Neaf->run;

