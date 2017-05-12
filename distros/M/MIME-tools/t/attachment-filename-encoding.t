#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use utf8;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

plan tests => 7;

main: {
    #-- Load MIME::Parser
    use_ok("MIME::Parser");

    #-- Prepare parser
    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);

    #-- Parse message file with attachment filename in Latin1
    my $msgfile = "testmsgs/attachment-filename-encoding-Latin1.msg";
    my $entity = parse_attachment_msg($parser, $msgfile);

    #-- Check if parsed recommended filename is in UTF-8
    my $filename = find_attachment_filename($entity);
    is(utf8::is_utf8($filename), 1, "Parsed filename should have UTF-8 flag on");

    #-- Check if parsed recommended filename matches the expected string
    is($filename, "attachment.äöü",
       "Parsed filename should match expectation");

    #-- Parse message file with attachment filename in Latin1
    $msgfile = "testmsgs/attachment-filename-encoding-UTF8.msg";
    $entity = parse_attachment_msg($parser, $msgfile);

    #-- Check if parsed recommended filename is in UTF-8
    $filename = find_attachment_filename($entity);
    is(utf8::is_utf8($filename), 1, "Parsed filename should have UTF-8 flag on");

    #-- Check if parsed recommended filename matches the expected string
    is($filename, "attachment.äöü",
       "Parsed filename should match expectation");

    # CPAN ticket #65162
    # We need the default parser to tickle the bug
    my $dir = tempdir(CLEANUP => 1);
    $parser = MIME::Parser->new();
    $parser->output_to_core(0);
    $parser->output_under($dir);
    $entity = $parser->parse_data("From: test\@example.com\nSubject: test\nDate: Tue, 25 Jan 2011 14:35:04 +0100\nMessage-Id: <123\@example.com>\nContent-Type: text/plain; name*=utf-8''%CE%B2CURE%2Etxt\n\ntest\n");
    $filename = $entity->head->recommended_filename;
    is(utf8::is_utf8($filename), 1, "Parsed filename should have UTF-8 flag on");
    is($filename, "\x{3b2}CURE.txt", 'Got expected filename');
}

#-- Parse quoted printable file and return MIME::Entity
sub parse_attachment_msg {
    my $parser = shift;
    my $msgfile = shift;
    open (my $fh, $msgfile)
        or die "can't open $msgfile: $!";
    my $entity = $parser->parse($fh);
    close $fh;
    return $entity;
}

sub find_attachment_filename {
  my $entity = shift;
  return '' unless $entity;
  if ($entity->is_multipart) {
    foreach my $subpart ($entity->parts) {
      my $filename = find_attachment_filename($subpart);
      return $filename if $filename;
    }
  } else {
    my $head = $entity->head;
    my $rfn = $head->recommended_filename;
    return $rfn if $rfn;
  }
  return '';
}

1;
