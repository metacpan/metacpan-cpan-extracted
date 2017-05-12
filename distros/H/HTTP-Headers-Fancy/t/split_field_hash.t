#!perl

use Test::More tests => 18;

use HTTP::Headers::Fancy qw(split_field_hash);

is_deeply { split_field_hash() }      => {};
is_deeply { split_field_hash(undef) } => {};
is_deeply { split_field_hash('') }    => {};
is_deeply { split_field_hash('xxx') }        => { Xxx => undef };
is_deeply { split_field_hash('xxx ,yyy') }   => { Xxx => undef, Yyy => undef };
is_deeply { split_field_hash('xxx=yyy') }    => { Xxx => 'yyy' };
is_deeply { split_field_hash('xxx= , zzz') } => { Xxx => '', Zzz => undef };
is_deeply { split_field_hash('xxx, zzz=') }  => { Xxx => undef, Zzz => '' };
is_deeply { split_field_hash('xxx=yyy, zzz') } =>
  { Xxx => 'yyy', Zzz => undef };
is_deeply { split_field_hash('xxx=yyy, zzz=aaa') } =>
  { Xxx => 'yyy', Zzz => 'aaa' };
is_deeply { split_field_hash('xxx="yy,yy"') } => { Xxx => 'yy,yy' };
is_deeply { split_field_hash('xxx="yy=yy"') } => { Xxx => 'yy=yy' };
is_deeply { split_field_hash('xxx="yy,yy", yyy="zz=zz"') } =>
  { Xxx => 'yy,yy', Yyy => 'zz=zz' };
is_deeply { split_field_hash('xxx="yy=yy", yyy="zz,zz"') } =>
  { Xxx => 'yy=yy', Yyy => 'zz,zz' };
is_deeply { split_field_hash(' a , b , c ') } =>
  { A => undef, B => undef, C => undef };

my $hash1 = {
    foo => 'xxx=yyy, zzz',
    bar => 'xxx, zzz=',
};

my $hash2 = split_field_hash( $hash1, qw(foo bar) );

my $hash3 = {
    foo => {
        Xxx => 'yyy',
        Zzz => undef,
    },
    bar => {
        Xxx => undef,
        Zzz => '',
    }
};

is_deeply $hash1, $hash2;
is_deeply $hash2, $hash3;
is_deeply $hash3, $hash1;

done_testing;
