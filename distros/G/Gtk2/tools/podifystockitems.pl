#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::PkgConfig;
use Gtk2;

# depending on the locale, we may be writing wide characters (translations
# of strings from gtk+).  according to perldiag, we need to set an encoding
# on our filehandles to avoid the "Wide character in %s" warnings.  since
# we're printing stuff directly from gtk+, which is in utf8...
binmode STDOUT, ':utf8';

my @path = map { s/^-I//; $_ } grep /-I/, split /\s+/, 
	{ExtUtils::PkgConfig->find ('gtk+-2.0')}->{cflags};
print "\n";

while ($_ = shift (@path))
{
	last if (-e "$_/gtk/gtkstock.h");
}

my @ids;
open HDR, "<$_/gtk/gtkstock.h" or die "unable to open ($_) for input";
while (<HDR>)
{
	push @ids, $1 if (/#define\s+\w+\s+"(.*)"/);
}
close HDR;
@ids = sort @ids;

my @widths = (0, 0, 0);
my @data;
foreach (@ids)
{
	my $info = Gtk2::Stock->lookup ($_);
	next unless ($info);
	
	my $mask = undef;
	if ($info->{modifier})
	{
		$mask = join (',', @{$info->{modifier}});
		$mask =~ s/-mask//g;
		$mask =~ s/(\w+)/<$1>-/g;
		$mask .= uc(chr($info->{keyval}));
	}

	push @data, [ $_, $info->{label} || '', $mask || '' ];

	$widths[0] = length($data[$#data][0])
		if (length($data[$#data][0]) > $widths[0]);
	$widths[1] = length($data[$#data][1])
		if (length($data[$#data][1]) > $widths[1]);
	$widths[2] = length($data[$#data][2])
		if (length($data[$#data][2]) > $widths[2]);
}

my $end = '  +-'.'-'x$widths[0].'-+-'.'-'x$widths[1].'-+-'
     .'-'x$widths[2]."-+\n";

my $fmt = "  | %-$widths[0]s | %-$widths[1]s | %-$widths[2]s |\n";
print "=head1 Stock Items\n\n";
print $end;
printf $fmt, 'Stock-Id', 'Label', 'Mod-Key';
print $end;
foreach (@data)
{
	printf $fmt, @$_;
}
print $end."\n";
