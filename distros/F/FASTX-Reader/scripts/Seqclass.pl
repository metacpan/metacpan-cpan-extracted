#!/usr/bin/env perl
use 5.010;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;

say STDERR $FASTX::Reader::VERSION;

say "-" x 60;


my $valid_seq = FASTX::Seq->new("CAGATA", "Normal");

say $valid_seq->name();
say $valid_seq->seq();

say "-" x 60;
my $empty = FASTX::Seq->new("", "EmptySequence", undef);
say $empty->name();
say $empty->seq();

say "-" x 60;
my $badseq2 = FASTX::Seq->new();
say $badseq2->name();
say $badseq2->seq();


say "-" x 60;
my $badseq2 = FASTX::Seq->new("", "BadQual", undef, "I");
say $badseq2->name();
say $badseq2->seq();
