#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;

plan tests => 5;

main: {
    my ($fh, $mail_text, $entity, $parser);

    #-- Check whether Digest::MD5 is available
    my $has_md5 = eval "require Digest::MD5";

    #-- Load MIME::Parser
    use_ok("MIME::Parser");

    #-- Prepare parser
    $parser = MIME::Parser->new();
    $parser->output_to_core(1);

    #-- Switch parser to encoded mode
    $parser->decode_bodies(0);

    #-- Parse quoted-printable encoded file
    $entity = parse_qp_file($parser);

    #-- Check if body is stored encoded
    ok($entity->bodyhandle->is_encoded, "Entity stored encoded");

    #-- Check if MD5 resp. length match as expected
    $mail_text = $entity->as_string;
    if ( $has_md5 ) {
        my $md5 = Digest::MD5::md5_hex($mail_text);
        ok($md5 eq "a00f9b070d3153bbdc43d09a849730df", "Encoded MD5 match");
    } else {
        my $len = length($mail_text);
        ok($len == 665, "Encoded length match");
    }

    #-- Switch parser to decoded mode
    $parser->decode_bodies(1);

    #-- Parse quoted-printable encoded file
    $entity = parse_qp_file($parser);

    #-- Check if body is now stored decoded
    ok(!$entity->bodyhandle->is_encoded, "Entity stored decoded");

    #-- Check if MD5 resp. length match as expected
    $mail_text = $entity->as_string;
    if ( $has_md5 ) {
        my $md5 = Digest::MD5::md5_hex($mail_text);
        ok($md5 eq "54a4ccb3a16f83e851581ffa5178f68a", "Decoded MD5 match");
    } else {
        my $len = length($mail_text);
        ok($len == 609, "Decoded length match");
    }
}

#-- Parse quoted printable file and return MIME::Entity
sub parse_qp_file {
    my ($parser) = @_;
    open (my $fh, "testmsgs/german-qp.msg")
        or die "can't open testmsgs/german-qp.msg: $!";
    my $entity = $parser->parse($fh);
    close $fh;
    return $entity;
}

1;
