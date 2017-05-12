package Test::AnyOf;

use strict;
use warnings;

use Exporter;

use base 'Exporter';

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw( is_any_of );
## use critic

use Test::More;

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub is_any_of ($$;$) {
    my $got    = shift;
    my $expect = shift;
    my $name   = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::More->builder;

    my $match = ( grep { $got eq $_ } @{$expect} ) ? 1 : 0;

    $tb->ok( $match, $name );

    unless ($match) {
        my $diag = <<"EOF";
         got: $got
    expected: any one of ...
EOF
        $diag .= join "\n", map {"             $_"} @{$expect};

        $tb->diag($diag);
    }

    return $match;
}
## use critic

1;
