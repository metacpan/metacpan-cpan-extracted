use strict;
use warnings;
use Test::More;

use lib 'lib';
use Mail::MIMEDefang::OpenSMTPD
    qw( parse_headers header_value parse_results apply_header_ops );

my @msg = (
    'Received: from a',
    ' by b',
    'Received: from c',
    'Subject: hello',
    '  world',
    'X-Foo: 1',
    'From: me@example.org',
    '',
    'body',
);

my ( $h, $body ) = parse_headers( \@msg );
is scalar @{$h}, 5, 'five headers, folded lines belong to their header';
is $body, 7, 'body starts at the blank line';
is_deeply $h->[0]{lines}, [ 'Received: from a', ' by b' ], 'folded header kept whole';
is header_value( $h->[2] ), 'hello world', 'unfolded value';

my ($nohdr) = parse_headers( ['no colon here'] );
is scalar @{$nohdr}, 1, 'garbage is kept as a headerless entry';

# --- results ---------------------------------------------------------------
my $r = parse_results(<<'RES');
Hx-spam-score 5.2
N X-Inserted 0 top%20value
IX-Foo 1 changed
JReceived 2
Mmultipart/mixed;%20boundary=%22abc%22
C
Qreason
Rnew@example.org
RES
is $r->{action}, undef, 'no rejection';
is $r->{newbody}, 1, 'new body';
is_deeply [ map { $_->{type} } @{ $r->{ops} } ], [qw( H N I J M )], 'ops in order';
is $r->{ops}[0]{value}, '5.2', 'H value';
is $r->{ops}[1]{value}, 'top value', 'percent-decoded';
is_deeply [ map { $_->{type} } @{ $r->{unsupported} } ], [qw( Q R )], 'unsupported listed';

$r = parse_results("B554 5.7.1 Virus%20found\nT451 4.7.1 later\nD\n");
is $r->{action}, 'reject', 'first of B/T/D wins';
is $r->{reply}, '554 5.7.1 Virus found', 'bounce reply decoded';

$r = parse_results("T451 4.7.1 Try%20later\n");
is_deeply [ @{$r}{qw( action reply )} ], [ 'tempfail', '451 4.7.1 Try later' ], 'tempfail';

$r = parse_results("B250 2.0.0 oops\n");
is $r->{reply}, '550 5.7.1 oops', 'a bounce cannot use a 2xx code';

is parse_results("D\n")->{action}, 'discard', 'discard';

# --- applying changes ------------------------------------------------------
my @out = apply_header_ops( $h, parse_results("HX-New yes\n")->{ops} );
is $out[-1], 'X-New: yes', 'H appends';
is scalar @out, 8, 'nothing else changed';

@out = apply_header_ops( $h, parse_results("N X-Top 0 t\n")->{ops} );
is $out[0], 'X-Top: t', 'N 0 inserts at the top';
@out = apply_header_ops( $h, parse_results("N X-Mid 2 m\n")->{ops} );
is $out[3], 'X-Mid: m', 'N 2 inserts as third header (after the folded one)';
@out = apply_header_ops( $h, parse_results("N X-End 99 e\n")->{ops} );
is $out[-1], 'X-End: e', 'N beyond the end appends';

@out = apply_header_ops( $h, parse_results("IReceived 2 changed\n")->{ops} );
is_deeply [ grep {/^Received/} @out ], [ 'Received: from a', 'Received: changed' ],
    'I changes only the 2nd Received';
ok( ( grep { $_ eq ' by b' } @out ), 'the 1st Received keeps its folded line' );

@out = apply_header_ops( $h, parse_results("Isubject 1 new\n")->{ops} );
is_deeply [ grep { /^Subject|^  world/ } @out ], ['Subject: new'], 'I is case-insensitive and drops folds';

@out = apply_header_ops( $h, parse_results("IX-Missing 1 v\n")->{ops} );
is $out[-1], 'X-Missing: v', 'I adds the header if it does not exist';

@out = apply_header_ops( $h, parse_results("JReceived 1\n")->{ops} );
is_deeply [ grep {/^Received| by b/} @out ], ['Received: from c'], 'J removes the 1st Received and its fold';
@out = apply_header_ops( $h, parse_results("JX-Nope 1\n")->{ops} );
is scalar @out, 7, 'J of a missing header is a no-op';

@out = apply_header_ops( $h, parse_results("Mtext/plain\n")->{ops} );
is_deeply [ @out[ -2, -1 ] ], [ 'MIME-Version: 1.0', 'Content-Type: text/plain' ],
    'M adds MIME-Version and Content-Type';
my ($h2) = parse_headers( [ 'MIME-Version: 1.0', 'Content-Type: text/html', 'X: y' ] );
@out = apply_header_ops( $h2, parse_results("Mtext/plain\n")->{ops} );
is_deeply \@out, [ 'MIME-Version: 1.0', 'X: y', 'Content-Type: text/plain' ],
    'M replaces an existing Content-Type';

@out = apply_header_ops( $h, parse_results("HX-Multi a%0A%20b\n")->{ops} );
is_deeply [ @out[ -2, -1 ] ], [ 'X-Multi: a', ' b' ], 'multi-line value stays folded';

is scalar @{ $h->[0]{lines} }, 2, 'input headers are not modified';

done_testing;
