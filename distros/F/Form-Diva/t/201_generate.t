#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name => 'diva1',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name' },
        { name => 'phone', type => 'tel', extra => 'required',
            comment => 'phoney phooey', default => 'say Hello' },
        {qw / n email t email l Email c form-email placeholder doormat/},
        { name => 'our_id', type => 'number', extra => 'disabled' },
        {  name => 'onemore' },
    ],
);

note( 'a few example tests with some small data.');
my $data1 = {
    name   => 'spaghetti   bolognese',
    our_id => 41,
    email  => 'dinner@food.food',
};
my $processed1 = $diva1->generate( $data1 );
like( $processed1->[3]{input}, qr/name="our_id"/, 'Check row3 name in input tag.');
like( $processed1->[3]{input}, qr/value="41"/, 'Check row3 value in input tag.');
like( $processed1->[0]{input}, qr/class="form-control"/,
    'Row 0 has default class tag.');
like( $processed1->[2]{input}, qr/class="form-email"/,
    'Row 2 has over-ridden class tag.');
like( $processed1->[0]{input}, qr/value="spaghetti   bolognese"/,
    'Row 0 has value of spaghetti   bolognese.');
like( $processed1->[4]{input}, qr/value=""/,
    'Row 4 has empty value set.');
like( $processed1->[2]{input}, qr/value="dinner\@food\.food"/,
    'Row 2 has a value like the email address.');

is( $processed1->[0]{comment}, undef, 'first field has no comment' );
is( $processed1->[1]{comment},
    'phoney phooey', 'second field has comment of \'phoney phooey\'' );


note( 'a few example tests with no data.');
my $processed2 = $diva1->generate();
like( $processed2->[3]{input}, qr/name="our_id"/, 'Check row3 name in input tag.');
like( $processed2->[0]{input}, qr/class="form-control"/,
    'Row 0 has default class tag.');
like( $processed2->[2]{input}, qr/class="form-email"/,
    'Row 2 has over-ridden class tag.');
like( $processed2->[1]{input}, qr/value="say Hello"/,
    'Row 1 has default value set.');
like( $processed2->[2]{input}, qr/value=""/,
    'Row 2 has empty value set.');
like( $processed2->[3]{input}, qr/value=""/,
    'Check row3 has empty value set.');
like( $processed2->[2]{input}, qr/placeholder="doormat"/,
    'Row 2 has placeholder set.');

my @html_types = (
    {qw / n color t color l Colour /},
    {qw / n date   t date   l Date /},
    { n => 'datetime', t => 'datetime', l => 'Date Time' },
    {   n => 'datetime-local',
        t => 'datetime-local',
        l => 'Localized Date Time'
    	},
    {qw / n email  t email  l Email /},
    {qw / n month  t month  l Month /},
    {qw / n number t number l Number /},
    {qw / n yourpassword t password l YourSecretPassword /},
    {qw / n range  t range  l Range /},
    {qw / n search t search l Search/},
    {qw / n tel    t tel    l Telephone /},
    {qw / n url    t url    l URL /},
    {qw / n week   t week   l Week /},
);

note('Testing all of the html form field types');
my $diva_html_types = Form::Diva->new(
    form_name   => 'html_types',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => dclone( \@html_types ),
);

my @html_field_types_form = @{ $diva_html_types->generate() };
for ( my $i = 0; $i < scalar(@html_types); $i++ ) {
    my %data = %{ $html_types[$i] };
    my %res  = %{ $html_field_types_form[$i] };
    my $labelStr = qq!<LABEL for="formdiva_$data{n}"!;
    like( $res{label},
        qr/$labelStr/,
        "Label $labelStr generated for $data{t}"
    );
    my $inptStr = qq!<INPUT type="$data{t}" name="$data{n}"!;
    like( $res{input},
        qr/$inptStr/,
        "Input Field for $data{t} -- $inptStr"
    );
}

done_testing();

