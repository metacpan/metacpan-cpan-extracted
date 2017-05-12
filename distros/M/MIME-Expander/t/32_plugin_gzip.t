use strict;
use Test::More tests => 10;
#use Test::More qw(no_plan);
use lib './t/lib';
use MyUtils;

use MIME::Expander::Plugin::ApplicationGzip;

sub read_file {
    my $src = shift;
    open IN, "<$src" or die "cannot open $src: $!";
    local $/ = undef;
    my $data = <IN>;
    close IN;
    return \ $data;
}

my $accepts = [qw{
    application/gzip
    }];

is_deeply( MIME::Expander::Plugin::ApplicationGzip->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via class' );

my $plg = MIME::Expander::Plugin::ApplicationGzip->new;
isa_ok( $plg, 'MIME::Expander::Plugin');
can_ok( $plg, 'ACCEPT_TYPES');
is_deeply( $plg->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via instance' );

# is_acceptable
ok(   $plg->is_acceptable('application/gzip'),'is_acceptable application/gzip');
ok( ! $plg->is_acceptable('application/x-gzip'),'application/x-gzip');
ok( ! $plg->is_acceptable('application/zip'),'not is_acceptable');

# expand
my $input   = read_file('t/untitled.tar.gz');
my $expect  = read_file('t/untitled.tar');
my $cb = sub {
    my ($contents, $info) = @_;
    is( $info->{filename}, 'untitled.tar', 'filename' );
    is( $$contents, $$expect, 'exec callback' );
};
my $attr = {
    encoding     => "base64",
    content_type => "application/gzip",
};
is( $plg->expand( MyUtils::create_part($input, $attr), $cb ), 1, 'expand returns' );
