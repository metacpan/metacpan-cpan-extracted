#!/usr/bin/perl -w
#
# Check that comments in PO files are correctly parsed
#

use strict;
use Test::More tests => 11;

use_ok('Locale::Maketext::Extract');

my %msgids = ( comment => 'A random string to check that comments work',
               fuzzy   => 'Fuzzy flag',
               marker  => 'Fuzzy plus marker %1'
);
my $lex = Locale::Maketext::Extract->new();
ok( $lex, 'Locale::Maketext::Extract object created' );

$lex->read_po('t/comments.po');

# Here '#' and newlines are kept together with the comment
# Don't know if it's correct or elegant
is( $lex->msg_comment( $msgids{comment} ), 'Some user comment' . "\n" );

ok( $lex->msg_fuzzy( $msgids{fuzzy} ),  'Read fuzzy' );
ok( $lex->msg_fuzzy( $msgids{marker} ), 'Read marker' );
$lex->write_po( 't/comments_out.po', 1 );

$lex->clear();

is( $lex->msg_comment( $msgids{comment} ),
    undef, 'Comment should be gone with clear()' );

ok( !$lex->msg_fuzzy( $msgids{fuzzy} ), 'Fuzzy cleared' );

# Read back the new po file and check that
# the comment is readable again
$lex->read_po('t/comments_out.po');

is( $lex->msg_comment( $msgids{comment} ), 'Some user comment' . "\n" );
ok( $lex->msg_fuzzy( $msgids{fuzzy} ), 'Read fuzzy' );
my $po;
{
    local ( *INPUT, $/ );
    open( INPUT, 't/comments_out.po' )
        || die "can't open 't/comments_out.po': $!";
    $po = <INPUT>;
}
ok( $po =~ m/#, fuzzy, perl-maketext-format\nmsgid "Fuzzy plus marker %1"/,
    'Marker added' );
ok( unlink('t/comments_out.po') );
