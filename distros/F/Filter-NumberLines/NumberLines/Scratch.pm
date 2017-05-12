package Filter::NumberLines::Scratch;

sub scratch { local $_ = pop; s/^\d+\:\t//gm; return $_; } 

sub import { 
open 0 or print "Can't number '$0'\n" and exit;
my $line = 0; my $no_go = 0; my $past_use = 0; my $file;
while(<0>)
{ $line++;
  if ($past_use && /^\d+\:\t/) { $no_go++; $file = join "",$_,<0>; last; }
  if ($past_use) { $_ = sprintf ("%03d",$line).":\t".$_; }
  if (/use Filter\:\:NumberLines::Scratch;/) { $past_use++; }
  $file .= $_;
}

if ($no_go)
{ do {  eval scratch $file; exit; }  }
else { open 0, ">$0" or print "Cannot number '$0'\n" and exit;
       print {0} $file and exit; }
}
1;
=pod

=head1 NAME

Filter::NumberLines::Scratch - Source filter for Numbering lines (written from scratch).

=head1 SYNOPSIS

Just put use Filter::NumberLines::Scratch; at the top of your source file (below the shebang).
It will automagically number your lines starting from the line after the use statement.

  use Filter::NumberLines::Scratch;

=head1 DESCRIPTION

Filter::NumberLines::Scratch - Source filter for Numbering lines (written from scratch).

=head1 NOTE

This module is used in the Source Filters in Perl talk I'm planning for YAPC::Eu 2.00.2 in Munich.

=head1 REQUIREMENTS

Filter::NumberLines::Scratch has no dependencies

=head1 TODO

Make number of digits in line number configurable.

=head1 DISCLAIMER

This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Filter::NumberLines::Scratch 0.02.

=head1 AUTHOR

Hendrik Van Belleghem (beatnik -at- quickndirty -dot- org)

=head1 SEE ALSO

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

Filter::Util::Call - http://search.cpan.org/search?dist=Filter

Paul Marquess' article
on Source Filters - http://www.samag.com/documents/s=1287/sam03030004/

=cut
