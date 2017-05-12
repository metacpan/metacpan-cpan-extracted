use strict;
use Test::More tests => 10;
#use Test::More qw(no_plan);
use lib './t/lib';
use MyUtils;

use MIME::Expander::Plugin::ApplicationZip;

sub read_file {
    my $src = shift;
    open IN, "<$src" or die "cannot open $src: $!";
    local $/ = undef;
    my $data = <IN>;
    close IN;
    return \ $data;
}

my $accepts = [qw{
    application/zip
    }];

is_deeply( MIME::Expander::Plugin::ApplicationZip->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via class' );

my $plg = MIME::Expander::Plugin::ApplicationZip->new;
isa_ok( $plg, 'MIME::Expander::Plugin');
can_ok( $plg, 'ACCEPT_TYPES');
is_deeply( $plg->ACCEPT_TYPES,
    $accepts, 'ACCEPT_TYPES via instance' );

# is_acceptable
ok(   $plg->is_acceptable('application/zip'),'is_acceptable application/zip');
ok( ! $plg->is_acceptable('application/x-zip'),'application/x-zip');
ok( ! $plg->is_acceptable('application/gzip'),'not is_acceptable');

# expand
my $input   = read_file('t/untitled.zip');
my $names   = [];
my $sizes   = [];
my $cb = sub {
    my ($contents, $info) = @_;
    push @$names, $info->{filename};
    push @$sizes, length($$contents);
};
my $attr = {
    encoding     => "base64",
    content_type => "application/zip",
};
is( $plg->expand( MyUtils::create_part($input, $attr), $cb ), 2, 'expand returns' );
is_deeply( [sort @$names], ['untitled/untitled.pdf','untitled/untitled.txt'], 'filenames');
is_deeply( [sort @$sizes], [15,7841], 'sizes');
