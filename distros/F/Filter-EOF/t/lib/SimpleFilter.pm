package SimpleFilter;
use warnings;
use strict;

use Filter::EOF;
use base 'Exporter';

our @EXPORT = qw(test_export);

sub import {
    my ($class, @args) = @_;
    Filter::EOF->on_eof_call(sub { 

        $SimpleTest::TEST_ON_EOF       = 1;
        $SimpleTest::TEST_ON_EOF_CLASS = $class;
        $SimpleTest::TEST_PHASE = 'run';

        push @{ $SimpleTest::TEST_ORDER }, 'on_eof';

        my $source = shift;
        $$source .= ";\n\$TEST_MODIFICATION = 1;\n1;\n";
    });

    $SimpleTest::TEST_ON_IMPORT       = 1;
    $SimpleTest::TEST_ON_IMPORT_CLASS = $class;
    $SimpleTest::TEST_ON_IMPORT_ARGS  = \@args;
    $SimpleTest::TEST_PHASE = 'compile';

    $SimpleTest::TEST_ORDER = ['on_import'];

    $class->export_to_level(1);
}

sub test_export { 23 }

1;
