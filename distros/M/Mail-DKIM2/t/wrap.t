#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Mail::DKIM2::Wrap qw(wrap_single_part);

my $EOL = "\015\012";
sub msg { join($EOL, @_) }
my $B = 'BOUNDARY';
my @fixed = (Boundary => sub { $B });

# 1. Plain text/plain post: inner part keeps the Content-* fields verbatim,
#    in order, with their folding; body copied byte for byte.
{
    my $in = msg('From: a@example.org', 'Content-Type: text/plain;', "\tcharset=utf-8",
                 'Subject: hi', 'Content-Transfer-Encoding: 8bit', '', "h\xc3\xa9llo", '');
    my $w = wrap_single_part($in, @fixed);
    ok($w, 'single part is wrapped');
    is($w->{boundary}, $B, 'uses the boundary given');
    is($w->{body},
       "--$B$EOL" . "Content-Type: text/plain;$EOL\tcharset=utf-8$EOL"
       . "Content-Transfer-Encoding: 8bit$EOL$EOL" . "h\xc3\xa9llo$EOL" . "$EOL--$B--$EOL",
       'inner part: Content-* verbatim and in order, then the body, then the close');
    is($w->{message},
       msg('From: a@example.org', qq{Content-Type: multipart/mixed; boundary="$B"},
           'Subject: hi', 'MIME-Version: 1.0', '', '') . $w->{body},
       'outer: Content-Type changed in place, CTE removed, MIME-Version appended');
    is_deeply($w->{edits}, [
        { op => 'delete', name => 'Content-Transfer-Encoding', index => 1 },
        { op => 'change', name => 'Content-Type', index => 1, value => qq{multipart/mixed; boundary="$B"} },
        { op => 'add', name => 'MIME-Version', value => '1.0' },
    ], 'edits for the milter');
}

# 2. Body without a trailing CRLF, and an empty body: the part content is
#    exactly the original body (the CRLF before the close delimiter belongs
#    to the delimiter).
{
    my $w = wrap_single_part(msg('MIME-Version: 1.0', 'Content-Type: text/plain', '', 'no newline'), @fixed);
    like($w->{body}, qr/\r\n\r\nno newline\r\n--$B--\r\n\z/, 'no trailing CRLF: none invented in the content');
    my $e = wrap_single_part(msg('Content-Type: text/plain', '', ''), @fixed);
    is($e->{body}, "--$B$EOL" . "Content-Type: text/plain$EOL$EOL$EOL--$B--$EOL", 'empty body');
}

# 3. No Content-* fields at all: an inner part with no headers (MIME's
#    default text/plain), Content-Type and MIME-Version appended outside.
{
    my $w = wrap_single_part(msg('From: a@example.org', '', 'x', ''), @fixed);
    is($w->{body}, "--$B$EOL$EOL" . "x$EOL$EOL--$B--$EOL", 'inner part with no headers');
    is_deeply($w->{edits}, [
        { op => 'add', name => 'Content-Type', value => qq{multipart/mixed; boundary="$B"} },
        { op => 'add', name => 'MIME-Version', value => '1.0' },
    ], 'both added, nothing changed or deleted');
}

# 4. Duplicate Content-Type, plus Content-Disposition: second one deleted
#    before the first is changed; deletes last-first.
{
    my $w = wrap_single_part(msg('Content-Type: text/plain', 'Content-Disposition: inline',
        'Content-Type: text/html', 'MIME-Version: 1.0', '', 'x', ''), @fixed);
    is_deeply($w->{edits}, [
        { op => 'delete', name => 'Content-Type', index => 2 },
        { op => 'delete', name => 'Content-Disposition', index => 1 },
        { op => 'change', name => 'Content-Type', index => 1, value => qq{multipart/mixed; boundary="$B"} },
    ], 'duplicate Content-Type deleted, first changed, MIME-Version kept');
    like($w->{body}, qr/^--$B\r\nContent-Type: text\/plain\r\nContent-Disposition: inline\r\nContent-Type: text\/html\r\n\r\n/,
         'all three Content-* fields carried into the part, in order');
}

# 5. Multipart is left alone, however it is spelled; so is a message with no
#    blank line between header and body.
is(wrap_single_part(msg('Content-Type: Multipart/Alternative; boundary=x', '', '--x--', '')), undef,
   'multipart/alternative left alone');
is(wrap_single_part(msg('Content-Type: multipart/mixed', '', 'x', '')), undef,
   'multipart without a boundary parameter left alone');
is(wrap_single_part("From: a\@example.org$EOL"), undef, 'no header/body separator: left alone');

# 6. A boundary that occurs in the body is not used.
{
    my @c = ('clash', 'clean');
    my $w = wrap_single_part(msg('Content-Type: text/plain', '', '--clash in the body', ''),
                             Boundary => sub { shift @c });
    is($w->{boundary}, 'clean', 'a boundary found in the body is skipped');
}

# 7. Default boundaries are random and distinct.
{
    my $m = msg('Content-Type: text/plain', '', 'x', '');
    isnt(wrap_single_part($m)->{boundary}, wrap_single_part($m)->{boundary}, 'random boundaries differ');
}

done_testing;
