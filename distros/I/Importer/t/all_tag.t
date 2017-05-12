use Test::More;
use strict;
use warnings;

BEGIN {
    $INC{'My/Exporter/A.pm'} = __FILE__;
    $INC{'My/Exporter/B.pm'} = __FILE__;

    package My::Exporter::A;

    our @EXPORT = qw/foo bar/;
    our @EXPORT_OK = qw/baz bat/;

    sub foo { 'foo' }
    sub bar { 'bar' }
    sub baz { 'baz' }
    sub bat { 'bat' }

    package My::Exporter::B;

    our @EXPORT = qw/foo bar/;
    our @EXPORT_OK = qw/baz bat/;

    our %EXPORT_TAGS = (
        ALL => [qw/foo/],
    );

    sub foo { 'foo' }
    sub bar { 'bar' }
    sub baz { 'baz' }
    sub bat { 'bat' }
}

subtest "define ALL tag if missing" => sub {
    package Importer::A;
    use Importer 'My::Exporter::A' => ':ALL';
    main::can_ok(__PACKAGE__, qw/foo bar baz bar/);
};

subtest "do not override ALL tag if defined" => sub {
    package Importer::B;
    use Importer 'My::Exporter::B' => ':ALL';
    main::can_ok(__PACKAGE__, qw/foo/);
    main::ok(!__PACKAGE__->can($_), "Did not import $_") for qw/bar baz bat/;
};

done_testing;
