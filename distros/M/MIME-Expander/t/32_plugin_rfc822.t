use strict;
use Test::More tests => 8;
#use Test::More qw(no_plan);
use lib './t/lib';
use MyUtils;

use MIME::Expander::Plugin::MessageRFC822;

sub read_file {
    my $src = shift;
    open IN, "<$src" or die "cannot open $src: $!";
    local $/ = undef;
    my $data = <IN>;
    close IN;
    return \ $data;
}

my $accepts = [qw{
    message/rfc822
    multipart/mixed
    }];

is_deeply( MIME::Expander::Plugin::MessageRFC822->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via class' );

my $plg = MIME::Expander::Plugin::MessageRFC822->new;
isa_ok( $plg, 'MIME::Expander::Plugin');
can_ok( $plg, 'ACCEPT_TYPES');
is_deeply( $plg->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via instance' );

# is_acceptable
ok(   $plg->is_acceptable('message/rfc822'),'is_acceptable message/rfc822');
ok( ! $plg->is_acceptable('message/http'),'not is_acceptable');

# expand
my $input   = read_file('t/untitled.eml');
my $cb = sub {
    my ($contents, $info) = @_;
    like( $$contents, qr/MIME::Expander/, 'exec callback');
};
is( $plg->expand( Email::MIME->new($input), $cb ), 1, 'expand returns' );
