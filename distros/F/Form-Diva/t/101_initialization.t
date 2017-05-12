#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 1.00;
use Storable qw(dclone);
use Test::Exception 0.32;

use_ok('Form::Diva');

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name', comment => 'yes' },
        { name => 'phone', type => 'tel', extra => 'required', id => 'phonefield' },
        {qw / n email t email l Email c form-email placeholder doormat/},
        { name => 'our_id', type => 'number', extra => 'disabled' },
    ],
    hidden      => [
        { n => 'secret' },
        { n => 'hush', default => 'very secret', comment => 'very secret comment'},
    ],
);

my $diva2 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { n => 'something' },
    ],
);

dies_ok(
    sub { my $baddiva = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [{qw /t email l Email /}, ],
    ) }, 'Dies: Not providing a Field Name is Fatal' );

dies_ok(
    sub { my $baddiva = Form::Diva->new(
    input_class => 'form-control',
    form        => [{qw /t email n Email /}, ],
    ) }, 'Dies: Not providing label_class is fatal' );

dies_ok(
    sub { my $baddiva = Form::Diva->new(
    label_class => 'form-control',
    form        => [{qw /t email n Email /}, ],
    ) }, 'Dies: Not providing input_class is fatal' );

my ($newform, $newmap) = $diva1->_expandshortcuts( $diva1->{form} );
my ($newhid, $hidmap)  = $diva1->_expandshortcuts( $diva1->{hidden} );

is( scalar( keys %$newmap), scalar(@$newform), 
    '_expandshortcuts check that returned hash and array are same size ');
is( scalar( keys %$hidmap), scalar(@$newhid), 
    '_expandshortcuts check the same for hidden ');    

is( $newform->[0]{label}, 'Full Name', 'record 0 label is Full Name' );
is( $newform->[0]{p},     undef,       'record 0 p is undef' );
is( $newform->[0]{placeholder},
    'Your Name', 'value from p got moved to placeholder' );
is( $newform->[2]{placeholder},
    'doormat', 'placeholder set for the email field too' );
is( $newform->[3]{name}, 'our_id', 'last record in test is named our_id' );
is( $newform->[3]{extra},
    'disabled', 'last record extra field is: disabled' );
is( $newhid->[0]{name}, 'secret', 'hidden fields 0 name is secret' );
is( $newhid->[1]{default}, 
    'very secret', 'hidden fields 1 default is \'very secret\'' );
is( $newform->[0]{comment}, 'yes', 'fields 0 has comment of \'yes\'');
is( $newhid->[1]{comment}, 
    'very secret comment', 'hidden fields 1 the comment is  \'very secret comment\'' );

my $form2 = $diva2->{form};
is( $form2->[0]{name}, 'something', 
    'Second form has a name: something');
is( $form2->[0]{type}, 'text', 
    'Second form: field type defaulted to text');

done_testing();
