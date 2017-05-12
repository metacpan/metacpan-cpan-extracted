use strict;
use Test::More tests => 10;
#use Test::More qw(no_plan);
use lib './t/lib';
use MyUtils;

use MIME::Expander::Plugin;

my ($plg);

is_deeply( MIME::Expander::Plugin->ACCEPT_TYPES, [], 'ACCEPT_TYPES via class' );

$plg = MIME::Expander::Plugin->new;

isa_ok( $plg, 'MIME::Expander::Plugin');

can_ok( $plg, 'ACCEPT_TYPES');

is_deeply( $plg->ACCEPT_TYPES, [], 'ACCEPT_TYPES via instance' );

# is_acceptable
MIME::Expander::Plugin->ACCEPT_TYPES(['foo/bar','a/b']);
$plg = MIME::Expander::Plugin->new;
ok(   $plg->is_acceptable('foo/bar'),'is_acceptable');
ok(   $plg->is_acceptable('a/b'),'is_acceptable');
ok( ! $plg->is_acceptable('x/y'),'not is_acceptable');

# expand
my $input   = \ 'hello world';
my $expect  = \ 'hello world';
my $cb = sub {
    my ($buf, $info) = @_;
    is( $info->{filename}, undef, 'filename' );
    is( $buf, $$expect, 'exec callback' );
};
my $attr = {
    encoding     => "base64",
    content_type => "application/bzip",
    };
is( $plg->expand( MyUtils::create_part($input, $attr), $cb ), 1, 'expand returns' );
