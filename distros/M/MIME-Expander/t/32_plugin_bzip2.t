use strict;
use Test::More tests => 10;
#use Test::More qw(no_plan);
use lib './t/lib';
use MyUtils;

use MIME::Expander::Plugin::ApplicationBzip2;

sub read_file {
    my $src = shift;
    open IN, "<$src" or die "cannot open $src: $!";
    local $/ = undef;
    my $data = <IN>;
    close IN;
    return \ $data;
}

my $accepts = [qw{
    application/bzip2
    }];

is_deeply( MIME::Expander::Plugin::ApplicationBzip2->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via class' );

my $plg = MIME::Expander::Plugin::ApplicationBzip2->new;
isa_ok( $plg, 'MIME::Expander::Plugin');
can_ok( $plg, 'ACCEPT_TYPES');
is_deeply( $plg->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via instance' );

# is_acceptable
ok(   $plg->is_acceptable('application/bzip2'),'is_acceptable application/bzip2');
ok( ! $plg->is_acceptable('application/x-bzip2'),'application/x-bzip2');
ok( ! $plg->is_acceptable('application/zip'),'not is_acceptable');

# expand
my $input   = read_file('t/untitled.tar.bz2');
my $expect  = read_file('t/untitled.tar');
my $cb = sub {
    my ($buf, $info) = @_;
    is( $info->{filename}, undef, 'filename' );
    is( $$buf, $$expect, 'exec callback' );
};
my $attr = {
    encoding     => "base64",
    content_type => "application/x-bzip",
    };
is( $plg->expand( MyUtils::create_part($input, $attr), $cb ), 1, 'expand returns' );
