#!/usr/bin/env perl
# ABSTRACT: POD examples never show a request builder (->embedding / ->transcription) as returning a result
use strict;
use warnings;
use Test2::Bundle::More;
use Path::Tiny;

# karr k294: ->embedding and ->transcription build an HTTP request, they do
# not send it. SYNOPSIS lines like `my $embedding = $engine->embedding(...)`
# told users they got a vector / transcript; copied code then passed an
# HTTP::Request around as one. The result-returning calls are
# simple_embedding / simple_transcription (and their _f variants). A POD
# example that calls a builder must name what it gets: a $request.

my @offenders;
my $iter = path('lib')->iterator({ recurse => 1 });
while ( my $file = $iter->() ) {
  next unless $file =~ /\.pm\z/;
  my $in_pod = 0;
  my $line_no = 0;
  for my $line ( $file->lines_utf8 ) {
    $line_no++;
    if ( $line =~ /\A=(\w+)/ ) { $in_pod = $1 ne 'cut'; next }
    next unless $in_pod;
    next unless $line =~ /->(?:embedding|transcription)\(/;
    push @offenders, "$file:$line_no: $line"
      unless $line =~ /my \$request\s*=/;
  }
}

is scalar @offenders, 0, 'no POD example assigns a request builder to a result variable'
  or diag join '', @offenders;

done_testing;
