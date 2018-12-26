#!/usr/bin/perl -w
# (c) 2007-2019 Burak Gursoy <burak[at]cpan[dot]org>
# This sample code needs several other modules.
#
use 5.010;
use strict;
use warnings;
use Data::Dumper;
use I18N::LangTags::List;
use Encode qw(:all);
use Encode::Guess;
use Lingua::Any::Numbers qw(:std);
use Text::Table;
use constant ISONUM  => 1..11,13..16;
use constant TESTNUM => 45;

binmode STDOUT, ':encoding(UTF-8)';

our $VERSION = '0.20';

my   @GUESS = map { 'iso-8859-' . $_ } ISONUM;
push @GUESS , qw(koi8-f koi8-r koi8-u );

my $tb = Text::Table->new( qw( LID LANG SEnc OEnc String Ordinal )   );
   $tb->load([             qw( --- ---- ---- ---- ------ ------- ) ] );

my($s,$o);
foreach my $l ( sort { $a cmp $b } available ) {
   $s = to_string( TESTNUM, $l);
   $o = to_ordinal(TESTNUM, $l);
   $s = '<undefined>' if ! defined $s;
   $o = '<undefined>' if ! defined $o;
   $tb->load(
      [
         $l,
         I18N::LangTags::List::name($l),
         is_utf8($s) ? 'UTF8' : _guess($s),
         is_utf8($o) ? 'UTF8' : _guess($o),
         $s,
         $o,
      ]
   );
}

my $pok = print $tb;

sub _guess {
   my $data = shift;
   my $enc  = guess_encoding($data, @GUESS);
   return ! ref $enc ? q{?} : $enc->name;
}

__END__
