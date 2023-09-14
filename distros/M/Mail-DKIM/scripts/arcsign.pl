#!/usr/bin/perl -I../lib
#
# Copyright (c) 2005-2007 Messiah College. This program is free software.
# Copyright (c) 2017 Standcore LLC. This program is free software.
# You can redistribute it and/or modify it under the terms of the
# GNU Public License as found at http://www.fsf.org/copyleft/gpl.html.
#
# Written by Jason Long, jlong@messiah.edu.

use strict;
use warnings;

use Mail::DKIM::ARC::Signer;
use Getopt::Long::Descriptive;
use Pod::Usage;

my ($opt, $usage) = describe_options(
  "%c %o < original_email.txt",
  [ "selector=s" => "Signing selector", {default=>'selector1'} ],
  [ "domain=s" => "Signing domain" ],
  [ "algorithm=s" => "Algorithm to sign with", {default=>"rsa-sha256"} ],
  [ "srvid=s" => "Authentication-Results server domain, defaults to signing domain" ],
  [ "chain=s" => "Chain value. 'ar' means pick it up from Authentication-Results header", {default=>"ar"} ],
  [ "key=s" => "File containing private key, without BEGIN or END lines.", {default=>"private.key"} ],
  [ "debug-canonicalization=s" => "Outputs the canonicalized message to the specified file in addition to computing the DKIM signature. This is helpful for debugging canonicalization methods." ],
 	[ "extra-tag=s@" => "Extra tags to use in signing" ],
  [ "extra-seal-tag=s@" => "Extra tags to use in sealing" ],
  [ "timestamp=i" => "Timestamp to sign with, default to now", {default=>time} ],
  [ "binary" => "Read input in binary mode" ],
  [ "wrap" => "Wrap original email" ],
  [ "help|?" => "Show help" ],
  {show_defaults=>1},
);

if ($opt->help) {
  print $usage->text;
  exit 1;
}

eval "use Mail::DKIM::TextWrap;" if($opt->wrap);

my $debugfh;
if (defined $opt->debug_canonicalization)  {
  open $debugfh, ">", $opt->debug_canonicalization
    or die "Error: cannot write ".$opt->debug_canonicalization.": $!\n";
}
if ($opt->binary)  {
  binmode STDIN;
}

my %arc_opt;
if ($opt->extra_tag) {
  $arc_opt{Tags} = {};
  for my $extra ($opt->extra_tag->@*) {
    my ($n, $v) = split /=/, $extra, 2;
    $arc_opt{Tags}->{$n} = $v;
  }
}
if ($opt->extra_seal_tag) {
  $arc_opt{SealTags} = {};
  for my $extra ($opt->extra_seal_tag->@*) {
    my ($n, $v) = split /=/, $extra, 2;
    $arc_opt{SealTags}->{$n} = $v;
  }
}

my $arc = new Mail::DKIM::ARC::Signer(
  Domain => $opt->domain,
  SrvId => $opt->srvid,
  Chain => $opt->chain,
  Algorithm => $opt->algorithm,
  Selector => $opt->selector,
  KeyFile => $opt->key,
  Debug_Canonicalization => $debugfh,
  Timestamp => $opt->timestamp,
  %arc_opt,
);



while (<STDIN>)
{
  unless ($opt->binary) {
    chomp $_;
    s/\015?$/\015\012/s;
  }
  $arc->PRINT($_);
}
$arc->CLOSE;

if ($debugfh)
{
  close $debugfh;
  print STDERR "wrote canonicalized message to ".$opt->debug_canonicalization."\n";
}

print "RESULT IS " . $arc->result() . "\n";

if( $arc->result eq "sealed") {
  print join("\n",$arc->as_strings) . "\n";
} else {
  print "REASON IS " . $arc->{details} . "\n";
}

__END__

=head1 NAME

arcsign.pl - computes ARC signatures for an email message

=head1 SYNOPSIS

  arcsign.pl --help
    to see a full description of the various options

=head1 AUTHORS

Jason Long, E<lt>jlong@messiah.eduE<gt>

John Levine, E<lt>john.levine@standcore.comE<gt>

Marc Bradshaw, E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Messiah College
Copyright 2017 by Standcore LLC

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
