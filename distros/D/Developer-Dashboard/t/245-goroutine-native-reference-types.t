use strict;
use warnings;

use Test::More;
use Scalar::Util qw(reftype);
use File::Temp qw(tempfile);
use Developer::Dashboard::GoRoutine qw(go share wait_all);

# A shared value is the plain Perl value in the one interpreter, so a
# compiled regexp, an IO reference, a typeglob and a format are shared
# exactly as they are: no marshalling, no worker interpreter in between.

my $regexp = eval {
    share my $value = qr/^foo+$/i;
    $value;
};
ok( $regexp, 'share accepts a compiled regular expression' )
    or diag "sharing regular expression failed: $@";
is( reftype($regexp), 'REGEXP', 'regular expression remains a native REGEXP' );
share my $regexp_worker_ok = 0;
go sub {
    $regexp_worker_ok = reftype($regexp) eq 'REGEXP' && 'fOoO' =~ $regexp;
};
wait_all();
ok( $regexp_worker_ok, 'shared regular expression works in a routine' );

my ($io_fh) = tempfile();
select( ( select($io_fh), $| = 1 )[0] );
my $io = *{$io_fh}{IO};
my $shared_io = eval {
    share my $value = $io;
    $value;
};
ok( $shared_io, 'share accepts an fd-backed IO reference' )
    or diag "sharing IO reference failed: $@";
is( reftype($shared_io), 'IO', 'file handle IO remains a native IO reference' );
share my $io_worker_ok = 0;
share my $io_worker_error = '';
go sub {
    my $worked = eval {
        $shared_io->print("shared-io\n") or die "print failed: $!";
        1;
    };
    $io_worker_error = "$@" if !$worked;
    $io_worker_ok = $worked ? 1 : 0;
};
wait_all();
ok( $io_worker_ok, 'routine can use a shared fd-backed IO reference' )
    or diag "shared IO routine error: $io_worker_error";
seek( $io_fh, 0, 0 ) or die "cannot rewind shared-IO fixture: $!";
is( scalar(<$io_fh>), "shared-io\n", 'routine output reaches the original IO handle' );

our $GOROUTINE_NATIVE_GLOB = 5;
our @GOROUTINE_NATIVE_GLOB = (1, 2);
our %GOROUTINE_NATIVE_GLOB = (a => 3);
sub GOROUTINE_NATIVE_GLOB { 7 }
my $whole_glob = eval {
    share my $value = \*GOROUTINE_NATIVE_GLOB;
    $value;
};
ok( $whole_glob, 'share accepts a typeglob reference' )
    or diag "sharing typeglob failed: $@";
if ($whole_glob) {
    share my $glob_slot_worker_ok = 0;
    share my $glob_slot_worker_error = '';
    go sub {
        my $worked = eval {
            my $scalar = *{$whole_glob}{SCALAR};
            my $array  = *{$whole_glob}{ARRAY};
            my $hash   = *{$whole_glob}{HASH};
            my $code   = *{$whole_glob}{CODE};
            $$scalar++;
            push @$array, 3;
            $$hash{b} = 4;
            $glob_slot_worker_ok = $code->() == 7 ? 1 : 0;
            1;
        };
        $glob_slot_worker_error = "$@" if !$worked;
    };
    wait_all();
    diag "typeglob routine error: $glob_slot_worker_error" if length $glob_slot_worker_error;
    is( ${ *{$whole_glob}{SCALAR} }, 6, 'typeglob scalar slot remains shared' );
    is_deeply( [ @{ *{$whole_glob}{ARRAY} } ], [1, 2, 3], 'typeglob array slot remains shared' );
    is( 0 + ${ *{$whole_glob}{HASH} }{b}, 4, 'typeglob hash slot remains shared' );
    ok( $glob_slot_worker_ok, 'typeglob code slot is callable in a routine' );
}
else {
    fail 'typeglob scalar slot remains shared';
    fail 'typeglob array slot remains shared';
    fail 'typeglob hash slot remains shared';
    fail 'typeglob code slot is callable in a routine';
}

my $memory = '';
my $memory_fh;
my $memory_opened = open $memory_fh, '+>', \$memory;
ok( $memory_opened, 'open non-fd-backed PerlIO fixture' )
    or diag "opening scalar-backed handle failed: $!";
my $shared_memory_fh = eval {
    share my $value = $memory_fh;
    $value;
};
ok( $shared_memory_fh, 'share accepts a non-fd-backed PerlIO handle' )
    or diag "sharing scalar-backed handle failed: $@";
share my $memory_worker_ok = 0;
share my $memory_worker_error = '';
go sub {
    my $worked = eval {
        print {$shared_memory_fh} "memory-handle\n" or die "print failed: $!";
        1;
    };
    $memory_worker_error = "$@" if !$worked;
    $memory_worker_ok = $worked ? 1 : 0;
};
wait_all();
ok( $memory_worker_ok, 'routine can use a shared non-fd-backed handle' )
    or diag "shared scalar-backed handle routine error: $memory_worker_error";
my $seek_ok = eval { seek($shared_memory_fh, 0, 0) };
ok( $seek_ok, 'shared scalar-backed handle can seek' )
    or diag "shared scalar-backed handle seek failed: $@";
my $read_value = eval { scalar <$shared_memory_fh> };
is( $read_value, "memory-handle\n", 'routine output can be read from shared scalar-backed handle' )
    or diag "shared scalar-backed handle read failed: $@";
close $memory_fh;

my $unicode_regexp = eval {
    share my $value = qr/^茶葉$/;
    $value;
};
ok( $unicode_regexp && '茶葉' =~ $unicode_regexp,
    'shared Unicode regular expression retains character matching semantics' );
share my $unicode_regexp_worker_ok = 0;
go sub {
    $unicode_regexp_worker_ok = $unicode_regexp && '茶葉' =~ $unicode_regexp;
};
wait_all();
ok( $unicode_regexp_worker_ok,
    'shared Unicode regular expression matches in a routine' );

my ($glob_fh) = tempfile();
select( ( select($glob_fh), $| = 1 )[0] );
my $glob = eval {
    share my $value = $glob_fh;
    $value;
};
ok( $glob, 'share accepts an fd-backed file glob' )
    or diag "sharing file glob failed: $@";
is( reftype($glob), 'GLOB', 'file handle materializes as a GLOB' );
share my $glob_worker_ok = 0;
share my $glob_worker_error = '';
go sub {
    my $worked = eval {
        print {$glob} "shared-glob\n" or die "print failed: $!";
        1;
    };
    $glob_worker_error = "$@" if !$worked;
    $glob_worker_ok = $worked ? 1 : 0;
};
wait_all();
ok( $glob_worker_ok, 'routine can use a shared fd-backed glob' )
    or diag "shared glob routine error: $glob_worker_error";
seek( $glob_fh, 0, 0 ) or die "cannot rewind shared-glob fixture: $!";
is( scalar(<$glob_fh>), "shared-glob\n", 'routine output reaches the original file handle' );

my $format;
{
    our $format_value = 'abc';
    format GOROUTINE_NATIVE_REFERENCE_FORMAT =
@<<<<
$format_value
.
    $format = *GOROUTINE_NATIVE_REFERENCE_FORMAT{FORMAT};
}
my $shared_format = eval {
    share my $value = $format;
    $value;
};
ok( $shared_format, 'share accepts a format reference' )
    or diag "sharing format failed: $@";
is( reftype($shared_format), 'FORMAT', 'format materializes as a FORMAT reference' );
share my $format_worker_ok = 0;
go sub { $format_worker_ok = reftype($shared_format) eq 'FORMAT' };
wait_all();
ok( $format_worker_ok, 'format reference materializes in a routine' );

done_testing;

__END__

=head1 NAME

t/245-goroutine-native-reference-types.t - native reference sharing tests

=head1 PURPOSE

Checks the GoRoutine shared graph behavior for compiled regular
expressions, fd-backed file globs, and format references in both the main
interpreter and go routines.

=head1 WHY IT EXISTS

The scalar/hash/array graph tests do not prove that Perl's native reference
types keep their real reference semantics when shared. The GoRoutine
contract includes these types, so this test prevents a partial integration
from silently degrading them to scalar or hash proxies.

=head1 WHEN TO USE

Run after changing share, the routine engine, or native reference handling.

=head1 HOW TO USE

Build the XS bundle and run the test inside the dev Docker service:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/245-goroutine-native-reference-types.t

=head1 WHAT USES IT

The Dashboard GoRoutine shared-data API uses this contract when values are
shared with go routines.

=head1 EXAMPLES

Run only this contract in Docker:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/245-goroutine-native-reference-types.t

Run it with the existing CODE-reference and channel contracts:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/237-goroutine-shared-objects.t t/244-goroutine-channels.t t/245-goroutine-native-reference-types.t

=cut
