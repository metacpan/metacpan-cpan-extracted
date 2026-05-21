use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent           ();
use Log::Dispatch            ();
use Log::Dispatch::Array     ();
use Path::Tiny               qw( path );
use Test::More import => [qw( done_testing is ok )];
use Test::Needs 'Unicode::GCString';
use Test::Warnings;

require Unicode::GCString;

# The captured table rows contain CJK glyphs and get interpolated into
# is() test names below; without UTF-8 binmode on the TAP filehandles,
# Test2::Formatter::TAP emits "Wide character in print" warnings.
for my $fh (
    Test::More->builder->output,
    Test::More->builder->failure_output,
    Test::More->builder->todo_output,
) {
    binmode $fh, ':encoding(UTF-8)';
}

my $ua = LWP::UserAgent->new;

# Force a CJK glyph into the headers table. CJK characters reliably have
# length() == 1 but Unicode::GCString columns == 2 across every release of
# Unicode::GCString, so a row containing CJK in a multi-row table (where
# the column width is set by a longer ASCII row) is exactly the case the
# old length()-based table layout gets wrong.
$ua->default_header( 'X-Wide-Test' => "\x{4E2D}\x{6587}" );

my $logger = debug_ua($ua);

my $messages = [];
my $ld       = Log::Dispatch->new(
    outputs =>
        [ [ 'Screen', min_level => 'debug', newline => 1, utf8 => 1 ] ],
);
$ld->add(
    Log::Dispatch::Array->new(
        name      => 'capture',
        min_level => 'debug',
        array     => $messages,
    ),
);
$logger->logger($ld);

$ua->get( 'file://' . path('t/test-data/wide-cjk.html')->absolute );

# A "table message" is any captured log entry that looks like a box-drawn
# table: at least one horizontal border (a run of '-' or '+' between '|'
# or corner characters) and at least one row pipe.
my @table_msgs;
for my $item ( @{$messages} ) {
    next unless defined $item->{message};
    next unless $item->{message} =~ /-{3,}/;
    next unless $item->{message} =~ /\|/;
    push @table_msgs, $item->{message};
}

ok( scalar(@table_msgs) >= 1, 'captured at least one box-drawn table' );

for my $msg (@table_msgs) {
    my @lines = grep { length } split /\n/, $msg;
    next unless @lines >= 3;
    my $expected = Unicode::GCString->new( $lines[0] )->columns;
    for my $i ( 0 .. $#lines ) {
        my $w = Unicode::GCString->new( $lines[$i] )->columns;
        is(
            $w, $expected,
            "line $i display width $expected: '$lines[$i]'"
        );
    }
}

done_testing;
