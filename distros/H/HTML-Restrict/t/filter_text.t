#!perl

use strict;
use warnings;

use HTML::Restrict ();
use Test::More;

my $hr               = HTML::Restrict->new( debug => 0 );
my $hr_no_processing = HTML::Restrict->new( debug => 0, filter_text => 0 );
my $hr_code_ref
    = HTML::Restrict->new( debug => 0, filter_text => \&code_ref );

my $string = 'Terms & Conditions';
my $html   = "<h2>$string</h2>";

#plain text tests
is(
    $hr->process($string), 'Terms &amp; Conditions',
    'Plain Text being processed'
);
is(
    $hr_no_processing->process($string), $string,
    'Plain Text not being processed'
);

#html tests
is( $hr->process($html), 'Terms &amp; Conditions', 'HTML being processed' );
is(
    $hr_no_processing->process($html), 'Terms & Conditions',
    'HTML not being processed'
);

#code ref test
is(
    $hr_code_ref->process($html), 'foobarbat Terms & Conditions',
    'Code Ref used to process'
);

done_testing();

sub code_ref {
    my $text = shift @_;
    return 'foobarbat ' . $text;
}
