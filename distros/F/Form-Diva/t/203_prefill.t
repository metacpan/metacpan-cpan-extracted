#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

sub Tester {
    my $generated = shift ;
    my $test = shift ;
    my $row = $test->{row};
    my $input = $test->{input};
    my $testType = $test->{testType} || 'like' ;
    my $comment = $test->{comment};
    if ( $testType eq 'like'){
        like( $generated->[ $row ]{ input },
            qr/$input/, "$comment  -- $input");}
    elsif ( $testType eq 'unlike'){
        unlike( $generated->[ $row ]{ input },
            qr/$input/, "$comment  -- $input");}
    else { fail( "Ivalid testType $testType provided for test: $comment") }
}

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name => 'diva1',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name' },
        { name => 'phone', type => 'tel', extra => 'required',
            comment => 'phoney phooey', default => 'say Hello' },
        {qw / n email t email l Email c form-email placeholder doormat/},
        { name => 'our_id', type => 'number',
                extra => 'disabled', placeholder => 11 },
        {  name => 'onemore', default => 'old college try' },
        {   name    => 'checktest',
            type    => 'checkbox',
            default => 'French',
            id      => 'checktest',
            values  => [
                qw /Argentinian American English Canadian French Irish Russian/
            ]
        },
    ],
);

my $data1 = {
    name   => 'spaghetti',
    email  => 'dinner@food.food',
};

my $data2 = {
    checktest   => 'Irish',
    name  => 'Coffee',
};


# need to create series of tests, several iterations of prefill and then do a plain generate to
# confirm original default/placholder still exist.
my @results1 = (
    {   row => 0 ,  input => q|value="spaghetti"|,
        comment => 'prefilled name with value spaghetti is set'},
    {   row => 0 ,  input => q|placeholder="Your Name"|,
        comment => 'prefilled name with value gets placeholder of "Your Name"'},
    {   row => 1 ,  input => q|value="say Hello"|,
        comment => 'prefilled with no value for phone gets default'},
    {   row => 2 ,    input => q|value="dinner\@food.food"|,
        comment => 'prefilled email with value dinner@food.food is set'},
    {   row => 3 ,  input => q|value=""|,
        comment => 'prefilled our_id with no value gets no value'},
    {   row => 3 ,  input => q|placeholder="11"|,
        comment => 'prefilled our_id with no value gets placeholder of 11'},
    {   row => 4 ,    input => q|value="old college try"|,
        comment => 'prefilled with no value for onemore gets default'},
    {   row => 5 ,    input => q|checked="checked">French|, testType => 'like',
        comment => 'checkbox has selected French'},
    {   row => 5 ,    input => q|"checked">Argentinian|, testType => 'unlike',
        comment => 'confirm that another item is not checked'},
);

my @results2 = (
    {   row => 0 ,  input => q|value="Coffee"|,
        comment => 'prefilled name with value Coffee is set'},
    {   row => 1 ,  input => q|value="say Hello"|,
        comment => 'prefilled with no value for phone gets default'},
    {   row => 2 ,    input => q|placeholder="doormat"|,
        comment => 'doormat is the placeholder (default) for email'},
    {   row => 3 ,  input => q|value=""|,
        comment => 'prefilled our_id with no value gets no value'},
    {   row => 3 ,  input => q|placeholder="11"|,
        comment => 'prefilled our_id with no value gets placeholder of 11'},
    {   row => 4 ,    input => q|value="old college try"|,
        comment => 'prefilled with no value for onemore gets default'},
    {   row => 5 ,    input => q|checked="checked">Irish|, testType => 'like',
        comment => 'checkbox has selected Irish'},
    {   row => 5 ,    input => q|"checked">Argentinian|, testType => 'unlike',
        comment => 'confirm that another item is not checked'},
);

my $nodatagenerate = $diva1->generate ;
my $nodataprefill = $diva1->prefill ;

is_deeply( $nodataprefill, $nodatagenerate,
    "With no data prefill and generate return the same" );

my $data_prefill_1 = $diva1->prefill( $data1 );
foreach my $test ( @results1) { Tester( $data_prefill_1, $test ) }

my $data_prefill_2 = $diva1->prefill( $data2 );
foreach my $test ( @results2) { Tester( $data_prefill_2, $test ) }

my $post_generate = $diva1->generate ;
is_deeply( $post_generate, $nodatagenerate,
    "Generate without Data returns the same after prefill was used as it did before." );

done_testing();

