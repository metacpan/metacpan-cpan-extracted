#!/usr/bin/env perl
package MOP4Import::Util::CommentedJson;
use strict;
use warnings FATAL => 'all';
use Exporter qw/import/;
use JSON::MaybeXS;
use bytes;

our @EXPORT_OK = qw/strip_json_comments/;

our $re_atom = qr{true|false|null}xs;

our $re_string = qr{
                     "(?: [^\\"]
                     | \\ (?: \\
                         | \"
                         | / | b | f | n | r | t
                         | u [0-9A-F]{4}
                       )
                     )*+"
                 }xs;

our $re_number = qr{
                     -?+
                     (?: 0
                     | [1-9] [0-9]*+
                     )?+
                     (?:
                       \. [0-9]++
                     )?+
                     (?:
                       [eE] [-+]?+ [0-9]*+
                     )?+
                 }xs;

our $re_comment1 = qr{//[^\n]*+}xs;
our $re_comment2 = qr{/\*.*?\*/}xs;

our $re_ALL = qr{ [\[\]\{\},:]
                | (?<comment> $re_comment1 | $re_comment2)
                | $re_atom
                | $re_number
                | $re_string
              }xs;

sub strip_json_comments {
  my ($pack, $bytes) = @_;
  $bytes =~ s/\A\xef\xbb\xbf//; # Strip BOM of utf-8.
  my @region = reverse list_json_comments($pack, $bytes);
  foreach my $region (@region) {
    my ($startPos, $len) = @$region;
    substr($bytes, $startPos, $len, '');
  }
  $bytes;
}

sub list_json_comments {
  my @pos;
  while ($_[1] =~ m{\G(?<ws>\s*+)$re_ALL}g) {
    if (defined $+{comment} and my $len = length($+{comment})) {
      my $startPos = pos($_[1]) - $len;
      push @pos, [$startPos, $len]
    }
  }
  @pos;
}

unless (caller) {
  my $pack = __PACKAGE__;
  my $method = shift;
  my $codec = JSON::MaybeXS->new(allow_nonref => 1);
  my @res = $pack->$method(@ARGV);
  print $codec->encode(\@res), "\n";
}

1;
