use strict;
use warnings;

use Test2::V0;
plan tests => 13;

use Test::Requires 'JSON::MaybeXS';

use File::Serialize { canonical => 1};

my %file;
use Path::Tiny;
{
  no warnings 'redefine';
  sub Path::Tiny::spew_utf8 { $file{$_[0]} = $_[1]; }
  sub Path::Tiny::slurp_utf8 { $file{$_[0]} }
}
my $data = [ { alpha => 1 }, { beta => 2 } ];

serialize_file 'foo.json' => $data;

transerialize_file 'foo.json' => sub { $_ = { map { %$_ } @$_ } } => { 'bar.json' => { pretty => 0 } };

is $file{'bar.json'} => '{"alpha":1,"beta":2}', 'bar.json';

is deserialize_file('bar.json') => {
    alpha => 1, beta => 2
}, "basic transerialize";

$data = {
    tshirt => { price => 18 },
    hoodie => { price => 50 },
};

transerialize_file $data => sub {
    my %inventory = %$_;
    +{ map { $_ => $inventory{$_} } grep { $inventory{$_}{price} <= 20 } keys %inventory }
} => 'inexpensive.json';

is deserialize_file('inexpensive.json') =>  {
    tshirt => { price => 18 },
}, 'basic transform';


transerialize_file $data
    => sub {
        my %inventory = %$_;
        +{ map { $_ => $inventory{$_}{price} } keys %inventory } }
    => sub {
        my %inventory = %$_;
        +{ map { $_ => $inventory{$_} } grep { $inventory{$_} <= 20 } keys %inventory }
    } => 'inexpensive.json';

is deserialize_file('inexpensive.json') =>  {
    tshirt => 18,
}, 'basic chained transform';

subtest 'end arguments' => sub {
    my $data = [1..3];
    my @last_args =
        map { [ $_->[0] . ' with args', $_->[1], { pretty => 1 } ], $_ }
        map { [ 'string', $_ ], [ 'path', path($_) ]  }
        'foo.json';
    for ( @last_args ) {
        my( $desc, @args ) = @$_;
        transerialize_file $data => @args;
        is deserialize_file('foo.json') => [1,2,3], $desc;
    }
};

$data = [ 1..10 ];

transerialize_file $data => {
    'beginning.json' => { pretty => 1 },
    'beginning.yml'  => undef
} => sub { [ grep { $_ % 2 } @$_ ] } => {
    'end.json' => { pretty => 1 },
    'end.yml'  => undef
};

is deserialize_file( $_ ) => [ 1..10 ], $_ for qw/ beginning.json beginning.yml /;
is deserialize_file( $_ ) => [ 1,3,5,7,9 ], $_ for qw/ end.json end.yml /;


my @data = 1..10;

transerialize_file \@data
    => { 'all.json' => undef }
    => [
        [ sub { [ grep { $_ % 2 } @$_ ] }     => 'odd.json'  ],
        [ sub { [ grep { not $_ % 2 } @$_ ] } => 'even.json' ],
    ];

is deserialize_file('all.json') => [1..10], 'all.json';
is deserialize_file('even.json') => [2,4,6,8,10], 'even.json';
is deserialize_file('odd.json') => [1,3,5,7,9], 'odd.json';

my $result;
transerialize_file [ 'a', 'b' ] => sub { [ map { uc } @$_ ] } => \$result;

is $result => [ 'A', 'B' ], "to a scalar ref";
