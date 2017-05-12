use strict;
use warnings;

use Test::More tests => 3;

use Dist::Zilla::Plugin::NextVersion::Semantic;

{
    package MyTest;

    use Moose;

   has format => (
       isa => 'Str',
       is => 'rw',
       default => '%d.%d.%d'
   );

   has previous_version => (
       is => 'rw',
   );

    with 'Dist::Zilla::Plugin::NextVersion::Semantic::Incrementer';
}


sub incr {
    my( $inc, $level ) = @_;
    my $version = $inc->increment_version($level);
    $inc->previous_version($version);
    return $version;
}

my $format = '%d.%3d.%3d';
subtest $format => sub { 
    my $incrementer = MyTest->new(
        previous_version => 0,
        format => $format,
    );

    is incr( $incrementer, 'MAJOR' ) => '1.0.0';
    is incr( $incrementer, 'MAJOR') => '2.0.0';
    is incr( $incrementer, 'MINOR') => '2.1.0';
    is incr( $incrementer, 'PATCH') => '2.1.1';
    is incr( $incrementer ) => '2.1.2';
    is incr( $incrementer, 'MINOR' ) => '2.2.0';

    $incrementer->previous_version( "0.0.999" );
    is incr( $incrementer ) => '0.1.0', 'length exceeded';
};

$format = '%d.%d';
subtest $format => sub {
    my $incrementer = MyTest->new(
        previous_version => 0,
        format => $format,
    );

    is incr( $incrementer, 'MAJOR' ) => '1.0';
    is incr( $incrementer, 'MAJOR') => '2.0';
    is incr( $incrementer, 'MINOR') => '2.1';
    is incr( $incrementer, 'PATCH') => '2.2';
    is incr( $incrementer ) => '2.3';
    is incr( $incrementer, 'MINOR' ) => '2.4';
};

$format = '%d.%03d%03d';
subtest $format => sub {
    my $incrementer = MyTest->new(
        previous_version => 0,
        format => $format,
    );

    is incr( $incrementer, 'MAJOR' ) => '1.000000';
    is incr( $incrementer, 'MAJOR') => '2.000000';
    is incr( $incrementer, 'MINOR') => '2.001000';
    is incr( $incrementer, 'PATCH') => '2.001001';
    is incr( $incrementer ) => '2.001002';
    is incr( $incrementer, 'MINOR' ) => '2.002000';
};
