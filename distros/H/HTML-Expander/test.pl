use Test;
BEGIN { plan tests => 1 };
use HTML::Expander;
use strict;

my $ex = new HTML::Expander;

$ex->{ 'WARNINGS' }++;

$ex->define_tag( 'main', '<name>',  '<h1><font color=%c>' );
$ex->define_tag( 'main', '</name>', '</font></h1>' );
$ex->mode_copy( 'new', 'main' );
$ex->define_tag( 'new', '<h1>',  '<p><h1>' );
$ex->define_tag( 'new', '<box>',  '<pre>' );
$ex->define_tag( 'new', '</box>',  '</pre>' );

$ex->define_var( 'main', 'LLL' => 'low level var' );
$ex->define_var( 'main', 'XXX' => 'this XXX is <var name=LLL><p>' );
$ex->define_var( 'main', 'ZZZ' => 'this ZZZ is <var name=LLL><p>' );

print $ex->expand( "<mode name=new>
                      <box>(current mode is '<var name=!mode>')</box>
                      <name c=#fff>This is me</name>
                    </mode>
                      <box>(cyrrent mode is '<var name=!mode>')</box>
                      <name>empty</name>
                    1.<var name=TEST>
                    2.<var name=TEST set=opala! echo>
                    3.<var name=TEST>
                    
                    <p>
                    <var name=XXX>
                    <p>
                    <var name=ZZZ>
                    
                    \n" );
$ex->{ 'EXEC_TAG_ALLOWED' } = 1;
print $ex->expand( '<exec cmd=date>(%HOME)' ), "\n";

$ex->add_inc_paths( '.' );

print $ex->expand( '<inc file=test.pl>' ), "\n";

print "done.";

use Data::Dumper;
print Dumper( $ex );

ok(1); # there is no bad condition check yet

