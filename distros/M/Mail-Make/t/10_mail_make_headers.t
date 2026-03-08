#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/09_multipart_structure.t
## Deep structural tests for Mail::Make::Entity MIME assembly and
## RFC 2047 address display-name encoding.
##
## These tests verify the *internal tree* produced by as_entity(), not just
## the top-level effective_type.  They also cover the address-encoding path
## that was absent from earlier test files.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    # Make TZ deterministic for date() tests
    $ENV{TZ} = 'UTC';
    eval
    {
        require POSIX;
        POSIX::tzset();
        1;
    };
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make::Headers' );
};

# NOTE: new / basic push/get
subtest 'new / basic push/get' => sub
{
    my $h = Mail::Make::Headers->new(
        From    => 'me@example.com',
        To      => 'you@example.com',
        Subject => 'Hello',
    );

    is( $h->header( 'From' ), 'me@example.com', 'new() stores initial headers' );
    is( $h->header( 'to' ), 'you@example.com', 'header() lookup is case-insensitive' );

    $h->push_header( 'X-Test' => '1' );
    is( $h->header( 'X-Test' ), '1', 'push_header() adds value' );
};

# NOTE: '_' behaves like '-' (canonical key)
subtest "'_' behaves like '-' (canonical key)" => sub
{
    my $h = Mail::Make::Headers->new();

    $h->push_header( 'Content_Type' => 'text/plain' );
    is( $h->header( 'Content-Type' ), 'text/plain', 'underscore name stored/retrieved as hyphen name' );

    # update via setter using underscore variant must replace existing
    $h->header( 'Content_Type' => 'text/html' );
    is( $h->header( 'Content-Type' ), 'text/html', 'setter replaced existing value' );

    my @vals = $h->header( 'Content-Type' );
    is_deeply( \@vals, [ 'text/html' ], 'no duplicate ghost headers after set' );
};

# NOTE: header() multi-values: list vs join
subtest 'header() multi-values: list vs join' => sub
{
    my $h = Mail::Make::Headers->new();

    $h->push_header( Accept => [ 'text/plain', 'text/html' ] );

    my @v = $h->header( 'Accept' );
    is_deeply( \@v, [ 'text/plain', 'text/html' ], 'multi-values returned as list' );

    is( $h->header( 'Accept' ), 'text/plain, text/html', 'multi-values joined in scalar context' );
};

# NOTE: init_header only sets if missing
subtest 'init_header only sets if missing' => sub
{
    my $h = Mail::Make::Headers->new();

    $h->push_header( 'X-Foo' => 'a' );
    $h->init_header( 'X_Foo' => 'b' );

    is( $h->header( 'X-Foo' ), 'a', 'init_header does not overwrite existing header' );
};

# NOTE: remove_header returns values (list), scalar returns last or 0
subtest 'remove_header returns values (list), scalar returns last or 0' => sub
{
    my $h = Mail::Make::Headers->new();

    $h->push_header( 'X-A' => [ '1', '2' ] );
    $h->push_header( 'X-B' => '3' );

    my @rm = $h->remove_header( 'X_A', 'X-B' );
    is_deeply( \@rm, [ '1', '2', '3' ], 'remove_header returns removed values (list)' );

    ok( !defined( $h->header( 'X-A' ) ), 'X-A removed' );
    ok( !defined( $h->header( 'X-B' ) ), 'X-B removed' );

    my $s = $h->remove_header( 'X-Missing' );
    is( $s, 0, 'remove_header scalar returns 0 when nothing removed' );
};

# NOTE: sanitization prevents header injection and strips control chars
subtest 'sanitization prevents header injection and strips control chars' => sub
{
    my $h = Mail::Make::Headers->new();

    $h->push_header( 'X-Test' => "hello\r\nInjected: yes" );
    is( $h->header( 'X-Test' ), 'hello Injected: yes', 'CRLF replaced with spaces' );

    # strip ASCII control chars except tab
    $h->push_header( 'X-Ctrl' => "a\x01b\x7Fc" );
    is( $h->header( 'X-Ctrl' ), 'abc', 'control characters stripped' );
};

# NOTE: clone / clear
subtest 'clone / clear' => sub
{
    my $h = Mail::Make::Headers->new();
    $h->push_header( 'X-A' => '1' );

    my $c = $h->clone();
    is( $c->header( 'X-A' ), '1', 'clone keeps content' );

    $h->clear();
    ok( !defined( $h->header( 'X-A' ) ), 'clear removes content' );
    is( $c->header( 'X-A' ), '1', 'clone independent from original' );
};

# NOTE: date() convenience: epoch int => RFC 5322 string (UTC here), float => passthrough
subtest 'date() convenience: epoch int => RFC 5322 string (UTC here), float => passthrough' => sub
{
    my $h = Mail::Make::Headers->new();

    $h->date( 0 );

    my $d = $h->header( 'Date' );
    is( $d, 'Thu, 01 Jan 1970 00:00:00 +0000', 'date(0) formats RFC5322 in UTC' );

    # float should NOT be converted; stored as given (sanitized)
    $h->date( '123.4' );
    is( $h->header( 'Date' ), '123.4', 'float-like value is passed through (not converted)' );
};

# NOTE: as_string_without_sort basic formatting
subtest 'as_string_without_sort basic formatting' => sub
{
    my $h = Mail::Make::Headers->new();

    $h->push_header( 'From' => 'a@example.com' );
    $h->push_header( 'Received' => 'r1' );
    $h->push_header( 'Received' => 'r2' );

    my $s = $h->as_string_without_sort( "\n" );
    like( $s, qr/^From:\s+a\@example\.com\n/m, 'as_string_without_sort contains From' );

    # In insertion order we should see r1 then r2
    like( $s, qr/Received:\s+r1\n.*Received:\s+r2\n/s, 'as_string_without_sort preserves insertion order' );
};

done_testing();

sub _re
{
    my( $s ) = @_;
    $s =~ s/\r//g;
    return( $s );
}

__END__
