#!/usr/bin/perl

=head1 NAME

groo-ga.pl - Check the grammar of Irish language OpenOffice.org documents

=head1 SYNOPSIS

B<groo-ga.pl> I<filetocheck[.sxw]> I<errorfile[.sxw]>

=head1 DESCRIPTION

This script checks the grammar of the Irish language OpenOffice.org
document given as the first argument, and creates a new document 
with the errors highlighted and annotated with appropriate messages.

=head1 REQUIRES

Perl 5.8, Lingua::GA::Gramadoir

=head1 SEE ALSO

=over 4

=item *
L<http://borel.slu.edu/gramadoir/>

=item *
L<Lingua::GA::Gramadoir>

=item *
L<perl(1)>

=back

=head1 AUTHOR

Kevin P. Scannell, E<lt>kscanne@gmail.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Kevin P. Scannell

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;
use warnings;
use utf8;

use Archive::Zip qw( :ERROR_CODES);
use Lingua::GA::Gramadoir;
use Encode qw(decode encode);

my $debug = 0;

if (scalar @ARGV != 2) {
	print "Usage: $0 filetocheck[.sxw] errorfile[.sxw]\n";
	exit 1;
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
my $datestr = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);

#  style definition for preamble
#    double-wavy red underline
my $style = '<style:style style:name="gramadoir" style:family="text"><style:properties style:text-underline="double-wave" style:text-underline-color="#800000"/></style:style>';
#    wavy green underline
# my $style = '<style:style style:name="gramadoir" style:family="text"><style:properties style:text-underline="wave" style:text-underline-color="#008000"/></style:style>';
#    yellow highlighter
# my $style = '<style:style style:name="gramadoir" style:family="text"><style:properties style:text-background-color="#ffff00"/></style:style>';


# annotation markup
my $ann = "<office:annotation office:author=\"An Gramadóir\" office:create-date=\"$datestr\"><text:p>";
my $closeann = '</text:p></office:annotation>';


# markup to insert before each error
my $markup = '<text:span text:style-name="gramadoir">';
my $closemarkup = $markup;
$closemarkup =~ s/[ >].*/>/;
$closemarkup =~ s/</<\//;

my $filetocheck = $ARGV[0];
my $errorfile = $ARGV[1];
$filetocheck =~ s/$/.sxw/ unless ($filetocheck =~ m/\.sxw$/);
$errorfile =~ s/$/.sxw/ unless ($errorfile =~ m/\.sxw$/);

my $zip = Archive::Zip->new();
die "error reading $filetocheck" unless $zip->read($filetocheck) == AZ_OK;
my $xml = $zip->contents('content.xml');
$xml =~ s/&quot;/\\"/g;
$xml =~ s/&lt;/\\</g;
$xml =~ s/&gt;/\\>/g;
$xml =~ s/&apos;/'/g;
$xml =~ s/&amp;/\\&/g;

print STDERR "Unpacked contents.xml, converted char entities...\n" if ($debug);

my $gr = new Lingua::GA::Gramadoir(
#	fix_spelling => 1,
	interface_language => 'ga', 
	input_encoding => 'utf-8',
);

print STDERR "Gramadoir object created...\n" if ($debug);

my $errs = $gr->grammatical_errors($xml);
print STDERR "Grammatical errors found...\n" if ($debug);
$xml = decode("utf-8", $xml);
my @xmllines = split /\n/, $xml;
my $xmlans;
my $curr_y = 0;
my $curr_x = 0;
my ($f_y, $f_x, $t_y, $t_x, $errmsg);
foreach (@$errs) {
	($f_y, $f_x, $t_y, $t_x, $errmsg) = m/^<error fromy="([0-9]+)" fromx="([0-9]+)" toy="([0-9]+)" tox="([0-9]+)" .+msg="([^"]+)"/;
	while ($curr_y < $f_y) {
		$xmlans .= substr($xmllines[$curr_y], $curr_x)."\n";
		$curr_y++;
		$curr_x = 0;
	}
	$xmlans .= substr($xmllines[$f_y], $curr_x, $f_x - $curr_x);
	$curr_x = $f_x;
	my $errorspan='';
	while ($curr_y < $t_y) {
		$errorspan .= substr($xmllines[$curr_y], $curr_x)."\n";
		$curr_y++;
		$curr_x = 0;
	}
	$t_x++;  # first char after error
	$errorspan .= substr($xmllines[$t_y], $curr_x, $t_x - $curr_x);
	$errorspan =~ s/((\s*<[^>]+>\s*)+)/$closemarkup$1$markup/g;
	$errorspan =~ s/^/$markup/;
	$errorspan =~ s/$/$closemarkup/;
	$curr_x = $t_x;
	$xmlans .= $errorspan;
	$xmlans .= $ann;
	$errmsg =~ s/\//\\"/g;
	$xmlans .= $errmsg;
	$xmlans .= $closeann;
}
print STDERR "All error markup inserted...\n" if ($debug);
$xmlans .= substr($xmllines[$curr_y], $t_x);
$curr_y++;
while ($curr_y <= scalar @xmllines) {
	$xmlans .= $xmllines[$curr_y]."\n";
	$curr_y++;
}
print STDERR "New XML completed...\n" if ($debug);

$xmlans = encode("utf-8", $xmlans);

$xmlans =~ s/\\&/&amp;/g;
$xmlans =~ s/\\"/&quot;/g;
$xmlans =~ s/\\</&lt;/g;
$xmlans =~ s/\\>/&gt;/g;
$xmlans =~ s/'/&apos;/g;

print STDERR "New XML converted to utf-8 octets...\n" if ($debug);


# insert description of gramadoir style in preamble
$xmlans =~ s/(?<=<office:automatic-styles>)/$style/;
$xmlans =~ s/(?<=<office:automatic-styles)\/>/>$style<\/office:automatic-styles>/;

$zip->contents('content.xml', $xmlans);
print STDERR "New XML replaces old in contents.xml...\n" if ($debug);
die "could not write to $errorfile" unless ($zip->writeToFileNamed( $errorfile ) == AZ_OK);
print STDERR "Zip file written...\n" if ($debug);

exit 0;
