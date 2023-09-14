#!/usr/bin/perl -I../lib
#
# Copyright (c) 2005-2007 Messiah College. This program is free software.
# You can redistribute it and/or modify it under the terms of the
# GNU Public License as found at http://www.fsf.org/copyleft/gpl.html.
#
# Written by Jason Long, jlong@messiah.edu.

use strict;
use warnings;

use Mail::DKIM::Signer;
use Mail::DKIM::TextWrap;
use Getopt::Long::Descriptive;
use Pod::Usage;

my ($opt, $usage) = describe_options(
  "%c %o < original_email.txt",
  [ "type=s" => "Determine the desired signature type 'dkim' or 'domainkeys'", {default=>'dkim'} ],
  [ "algorithm=s" => "Algorithm to sign with", {default=>"rsa-sha256"} ],
  [ "method=s" => "Specify the desired canonicalization method, Possible values are simple, simple/simple, simple/relaxed, relaxed, relaxed/relaxed, relaxed/simple", {default=>"simple"} ],
  [ "selector=s" => "Signing selector", {default=>'selector1'} ],
  [ "domain=s" => "Signing domain" ],
  [ "expiration=s" => "Optional signature expiration, as delta from current timestamp" ],
  [ "identity=s" => "Optional identity to use for signing" ],
  [ "key=s" => "File containing private key, without BEGIN or END lines.", {default=>"private.key"} ],
  [ "key-protocol=s" => "Optional key protocol to use" ],
  [ "debug-canonicalization=s" => "Outputs the canonicalized message to the specified file, in addition to computing the DKIM signature. This is helpful for debugging canonicalization methods." ],
  [ "extra-tag=s@" => "Extra tags to use in signing" ],
  [ "timestamp=i" => "Timestamp to sign with, defaults to now", {default=>time} ],
  [ "binary" => "Read input in binary mode" ],
  [ "help|?" => "Show help" ],
  {show_defaults=>1},
);

if ($opt->help) {
  print $usage->text;
  exit 1;
}

my $debugfh;
if (defined $opt->debug_canonicalization)
{
	open $debugfh, ">", $opt->debug_canonicalization
		or die "Error: cannot write ".$opt->debug_canonicalization.": $!\n";
}
if ($opt->binary)
{
	binmode STDIN;
}

my $dkim = new Mail::DKIM::Signer(
		Policy => \&signer_policy,
		Algorithm => $opt->algorithm,
		Method => $opt->method,
		Selector => $opt->selector,
		KeyFile => $opt->key,
		Debug_Canonicalization => $debugfh,
		);

while (<STDIN>)
{
	unless ($opt->binary)
	{
		chomp $_;
		s/\015?$/\015\012/s;
	}
	$dkim->PRINT($_);
}
$dkim->CLOSE;

if ($debugfh)
{
	close $debugfh;
	print STDERR "wrote canonicalized message to ".$opt->debug_canonicalization."\n";
}

print $dkim->signature->as_string . "\n";

sub signer_policy
{
	my $dkim = shift;

	use Mail::DKIM::DkSignature;

	$dkim->domain($opt->domain || $dkim->message_sender->host);

	my $class = $opt->type eq "domainkeys" ? "Mail::DKIM::DkSignature" :
			$opt->type eq "dkim" ? "Mail::DKIM::Signature" :
				die "unknown signature type '".$opt->type."'\n";
        my $timestamp = $opt->timestamp ? $opt->timestamp : time();
	my $sig = $class->new(
			Algorithm => $dkim->algorithm,
			Method => $dkim->method,
			Headers => $dkim->headers,
			Domain => $dkim->domain,
			Selector => $dkim->selector,
			defined($opt->timestamp) ? (Timestamp => $opt->expiration) : (),
			defined($opt->expiration) ? (Expiration => $timestamp + $opt->expiration) : (),
			defined($opt->identity) ? (Identity => $opt->identity) : (),
		);
	$sig->protocol($opt->key_protocol) if defined $opt->key_protocol;
  if ($opt->extra_tag) {
    foreach my $extra ($opt->extra_tag->@*) {
      my ($n, $v) = split /=/, $extra, 2;
     	$sig->set_tag($n, $v);
    }
	}
	$dkim->add_signature($sig);
	return;
}

__END__

=head1 NAME

dkimsign.pl - computes a DKIM signature for an email message

=head1 SYNOPSIS

  dkimsign.pl [options] < original_email.txt
    options:
      --type=TYPE
      --method=METHOD
      --selector=SELECTOR
      --expiration=INTEGER
      --debug-canonicalization=FILE

  dkimsign.pl --help
    to see a full description of the various options

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

Marc Bradshaw, E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Messiah College

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
