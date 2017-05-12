#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More;
my $DEBUG = 2;

BEGIN {

    # Make sure we've got Unicode support:
    eval "use v5.8.0;  utf8::is_utf8('x');";
    if ($@) {
        plan skip_all => "Perl 5.8.0 or newer required for Unicode tests";
        exit;
    }

    plan tests => 11;
    binmode STDOUT, ":utf8";
}    # end BEGIN

use Encode;
use HTML::TreeBuilder;

print "#Using Encode version v", $Encode::VERSION || "?", "\n";
print "#Using HTML::TreeBuilder version v$HTML::TreeBuilder::VERSION\n";
print "#Using HTML::Element version v$HTML::Element::VERSION\n";
print "#Using HTML::Parser version v", $HTML::Parser::VERSION || "?", "\n";
print "#Using HTML::Entities version v", $HTML::Entities::VERSION || "?",
    "\n";
print "#Using HTML::Tagset version v", $HTML::Tagset::VERSION || "?", "\n";
print "# Running under perl version $] for $^O",
    ( chr(65) eq 'A' ) ? "\n" : " in a non-ASCII world\n";
print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
    if defined(&Win32::BuildNumber)
        and defined &Win32::BuildNumber();
print "# MacPerl verison $MacPerl::Version\n"
    if defined $MacPerl::Version;
printf
    "# Current time local: %s\n# Current time GMT:   %s\n",
    scalar( localtime($^T) ), scalar( gmtime($^T) );

ok 1;

ok same( '<p>&nbsp;</p>', decode( 'latin1', "<p>\xA0</p>" ) );

ok !same( '<p></p>',  decode( 'latin1', "<p>\xA0</p>" ), 1 );
ok !same( '<p> </p>', decode( 'latin1', "<p>\xA0</p>" ), 1 );

ok same( '<p>&nbsp;&nbsp;&nbsp;</p>',
    decode( 'latin1', "<p>\xA0\xA0\xA0</p>" ) );
ok same( "<p>\xA0\xA0\xA0</p>", decode( 'latin1', "<p>\xA0\xA0\xA0</p>" ) );

ok !same( '<p></p>',  decode( 'latin1', "<p>\xA0\xA0\xA0</p>" ), 1 );
ok !same( '<p> </p>', decode( 'latin1', "<p>\xA0\xA0\xA0</p>" ), 1 );

ok same(
    '<p>&nbsp;&nbsp;&mdash;&nbsp;&nbsp;</p>',
    "<p>\xA0\xA0\x{2014}\xA0\xA0</p>"
);

ok same(
    '<p>&nbsp;&nbsp;XXmdashXX&nbsp;&nbsp;</p>',
    "<p>\xA0\xA0\x{2014}\xA0\xA0</p>",
    0, sub { $_[0] =~ s/XXmdashXX/\x{2014}/ }
);

ok same( '<p>&nbsp;<b>bold</b>&nbsp;&nbsp;</p>',
    decode( 'latin1', "<p>\xA0<b>bold</b>\xA0\xA0</p>" ) );

sub same {
    my ( $code1, $code2, $flip, $fixup ) = @_;
    my $t1 = HTML::TreeBuilder->new;
    my $t2 = HTML::TreeBuilder->new;

    if ( ref $code1 ) { $t1->implicit_tags(0); $code1 = $$code1 }
    if ( ref $code2 ) { $t2->implicit_tags(0); $code2 = $$code2 }

    $t1->parse($code1);
    $t1->eof;
    $t2->parse($code2);
    $t2->eof;

    my $out1 = $t1->as_XML;
    my $out2 = $t2->as_XML;

    $fixup->( $out1, $out2 ) if $fixup;

    my $rv = ( $out1 eq $out2 );

    #print $rv? "RV TRUE\n" : "RV FALSE\n";
    #print $flip? "FLIP TRUE\n" : "FLIP FALSE\n";

    if ( $flip ? ( !$rv ) : $rv ) {
        if ( $DEBUG > 2 ) {
            print
                "In1 $code1\n",
                "In2 $code2\n",
                "Out1 $out1\n",
                "Out2 $out2\n",
                "\n\n";
        }
    }
    else {
        local $_;
        foreach my $line (
            '',
            "The following failure is at " . join( ' : ', caller ),
            "Explanation of failure: "
            . ( $flip ? 'same' : 'different' )
            . " parse trees!",
            sprintf( "Input code 1 (utf8=%d):", utf8::is_utf8($code1) ),
            $code1,
            sprintf( "Input code 2 (utf8=%d):", utf8::is_utf8($code2) ),
            $code2,
            "Output tree (as XML) 1:",
            $out1,
            "Output tree (as XML) 2:",
            $out2,
            )
        {
            $_ = $line;
            s/\n/\n# /g;
            print "# $_\n";
        }
    }

    $t1->delete;
    $t2->delete;

    return $rv;
}    # end same
