#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use IPC::Run 'run';
use List::Util 'sum';
use Test::More;

plan skip_all => "Works only on linux (using strace)" if $^O ne 'linux';

my %impl2opts =
    (
     'Image::Info::SVG::XMLSimple' =>
     [
      {XML_SAX_Parser => 'XML::Parser'},
      {XML_SAX_Parser => 'XML::SAX::Expat'},
      {XML_SAX_Parser => 'XML::SAX::ExpatXS'},
      {XML_SAX_Parser => 'XML::SAX::PurePerl'},
      {XML_SAX_Parser => 'XML::LibXML::SAX::Parser'},
      {XML_SAX_Parser => 'XML::LibXML::SAX'},
     ],
     'Image::Info::SVG::XMLLibXMLReader' => [{}],
    );

plan tests => 2 * sum map { scalar @$_ } values(%impl2opts);

for my $impl (keys %impl2opts) {
    my $testname = $impl;
    my @opts = @{ $impl2opts{$impl} };
    for my $opt (@opts) {
	my $testname = $testname . (%$opt ? ", " . join(", ", map { "$_ => $opt->{$_}" } keys %$opt) : '');
	my @cmd =
	    (
	     $^X, "-I$FindBin::RealBin/../lib", '-MImage::Info=image_info', '-e',
	     ($opt->{XML_SAX_Parser} ? 'require XML::Simple; $XML::Simple::PREFERRED_PARSER = shift; ' : '') .
	     '@Image::Info::SVG::PREFER_MODULE=shift; my $info = image_info(shift); die $info->{error} if $info->{error};',
	     ($opt->{XML_SAX_Parser} ? $opt->{XML_SAX_Parser} : ()),
	     $impl, "$FindBin::RealBin/../img/xxe.svg",
	    );
	{
	    my $stderr;
	    ok run(\@cmd, '2>', \$stderr), "Run @cmd"
		or diag $stderr;
	}
	{
	    my $success = run(["strace", "-eopen,stat", @cmd], '2>', \my $strace);
	    if (!$success) {
		if (($opt->{XML_SAX_Parser}||'') eq 'XML::SAX::ExpatXS') {
		    # ignore error
		} else {
		    die "Error running @cmd with strace";
		}
	    }
	    my @matching_lines = $strace =~ m{.*/etc/passwd.*}g;
	    is scalar(@matching_lines), 0, "No XXE with $testname"
		or diag explain \@matching_lines;
	}
    }
}

done_testing;


__END__
