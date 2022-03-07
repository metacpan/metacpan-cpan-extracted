use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;

Git::Lint::Test::override(
    package => 'Git::Lint::Config',
    name    => 'user_config',
    subref  => sub { return {} },
);

Git::Lint::Test::override(
    package => 'Module::Loader',
    name    => 'find_modules',
    subref  => sub {
                   my $self      = shift;
                   my $namespace = shift;

                   return ();
    },
);

my $class = 'Git::Lint';
use_ok( $class );

my $object = $class->new();
my $config = $object->config();

subtest 'config return contains expected structure' => sub {
    plan tests => 10;

    ok( exists $config->{profiles}, 'profiles key exists' );
    ok( ref $config->{profiles} eq 'HASH', 'profiles key is hashref' );

    ok( exists $config->{profiles}{commit}, 'profiles commit key exists' );
    ok( ref $config->{profiles}{commit} eq 'HASH', 'profiles commit key is hashref' );

    ok( exists $config->{profiles}{message}, 'profiles message key exists' );
    ok( ref $config->{profiles}{message} eq 'HASH', 'profiles message key is hashref' );

    ok( exists $config->{profiles}{commit}{default}, 'profiles commit default key exists' );
    ok( ref $config->{profiles}{commit}{default} eq 'ARRAY', 'profiles commit default key is arrayref' );

    ok( exists $config->{profiles}{message}{default}, 'profiles message default key exists' );
    ok( ref $config->{profiles}{message}{default} eq 'ARRAY', 'profiles message default key is arrayref' );
};

done_testing;
