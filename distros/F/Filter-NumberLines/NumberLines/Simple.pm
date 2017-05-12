package Filter::NumberLines::Simple;

use Filter::Simple;

FILTER { s/^\d+\:\t//gm; };

open(F,"<$0") || die $!;
open(OUTFILE,">$0.bak") || die $!;
$line = 0;
my $no_go = 0;
my $past_use = 0;
$|++;
while(<F>)
{ $line++;
  if ($past_use && /^\d+\:\t/) { $no_go++;last; }
  if ($past_use)
  { $_ = sprintf ("%03d",$line).":\t".$_; }
  if (/use Filter\:\:NumberLines::Simple;/)
  { $past_use++; }
  print OUTFILE $_;
}
close(OUTFILE);
if (!$no_go)
{ unlink($0) || die $!;
  rename ("$0.bak",$0);
  close(F);
  exit;
} else { unlink("$0.bak") || die $!; }
1;
__END__
=pod

=head1 NAME

Filter::NumberLines::Simple - Source filter for Numbering lines (using Filter::Simple).

=head1 SYNOPSIS

Just put use Filter::NumberLines::Simple; at the top of your source file (below the shebang).
It will automagically number your lines starting from the line after the use statement.

  use Filter::NumberLines::Simple;

=head1 DESCRIPTION

Filter::NumberLines::Simple - Source filter for Numbering lines (using Filter::Simple).

=head1 NOTE

This module is used in the Source Filters in Perl talk I'm planning for YAPC::Eu 2.00.2 in Munich.

=head1 REQUIREMENTS

Filter::NumberLines::Simple requires Filter::Simple (which requires Filter::Util::Call)

=head1 TODO

Make number of digits in line number configurable.

=head1 DISCLAIMER

This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Filter::NumberLines::Simple 0.02.

=head1 AUTHOR

Hendrik Van Belleghem (beatnik -at- quickndirty -dot- org)

=head1 SEE ALSO

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

Filter::Simple - http://search.cpan.org/search?dist=Filter-Simple

Filter::Util::Call - http://search.cpan.org/search?dist=Filter

Paul Marquess' article
on Source Filters - http://www.samag.com/documents/s=1287/sam03030004/

=cut
