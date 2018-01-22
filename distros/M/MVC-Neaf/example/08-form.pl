#!/usr/bin/env perl

# This example shows form validation & resubmission.
# A 'form' is represented by a predefined set of validation rules.
# When applied to a request's parameters, it generates a reply
#     containing both original data and validation results.
# Further validation can be performed on that object if needed,
#     e.g. also check that specified user ID is in the database.
# Should the validation fail, original data may be returned to user
#     together with error messages for amendment.

use strict;
use warnings;

use MVC::Neaf qw(:sugar);

# Some inline html
my $tpl = <<'TT';
<html>
<head>
    <title>Form validation and resubmission - example/08 NEAF [% ver | html %]</title>
</head>
<body>
    <style>
        .error { color: red; }
        .ok    { color: green; }
    </style>
<h1>Form validation and resubmission</h1>
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

# Prepare a form once.
neaf form => "rules" => {
    name    => [ required => '\w+' ],
    email   => [ required => '\S+@\S+' ],
    email2  => [ required => '\S+@\S+' ],
    country => '..',
    age     => '\d+',
};

# Apply to every incoming request
get+post '/08/form' => sub {
    my $req = shift;

    # run basic validation
    my $form = $req->form( "rules" );

    # Add custom rules that do not fit into form definition
    # All errors will be presented to the user
    if ($form->data->{age}) {
        $form->data->{age} >= 18
            or $form->error( age => "Age must be 18+" );
    };

    if ($form->is_valid) {
        $form->data->{email} eq $form->data->{email2}
            or $form->error( "email2" => "Addresses do not match" );
    };

    return {
        is_valid => $form->is_valid,
        form     => $form,
        ver      => MVC::Neaf->VERSION,
    };
}, -view => 'TT', -template => \$tpl,
    description => 'Form validation and resubmission';

neaf->run;

