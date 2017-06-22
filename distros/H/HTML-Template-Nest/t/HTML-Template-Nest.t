# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl HTML-Template-Nest.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use lib '../lib';

use Test::More tests=> 31;
BEGIN { use_ok('HTML::Template::Nest') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $nest = new_ok( 'HTML::Template::Nest' );
can_ok( $nest, qw(new template_dir comment_tokens show_labels template_ext name_label to_html) );


my $tokens = $nest->comment_tokens;
test_tokens($tokens,'default');
$tokens = $nest->comment_tokens("(",")");
test_tokens($tokens,'set');
is( $tokens->[0], "(", "first set comment_token correct" );
is( $tokens->[1], ")", "second set comment_token correct" );


$nest->show_labels(1);
is( $nest->show_labels, 1, "set show_labels correct" );




foreach( qw(name_label template_ext template_dir) ){
    my $default_value = $nest->$_;
    test_scalar( $_,'default',$default_value );
    my $set_value = $nest->$_('HELLO');
    test_scalar( $_,'set',$set_value );
    is($set_value,'HELLO',"set $_ is correct");
}



sub test_tokens{
    my ($tokens,$type) = @_;

    ok( $tokens, "$type comment_tokens is defined");
    like( ref($tokens), qr/^array/i, "$type comment_tokens is an arrayref" );
    is( scalar(@$tokens), 2, "$type comment_tokens has 2 values" );
    is( ref( $tokens->[0] ), '', "first $type comment_token is a scalar" );
    is( ref( $tokens->[1] ), '', "second $type comment_token is a scalar" );

}

sub test_scalar{
    my ($name,$type,$value) = @_;

    ok( defined $value, "$type $name is defined" );
    is( ref($value), '', "$type $name is a scalar");

}
