package TestUtils;

use HTML::PrettyPrinter;
use FileHandle;
use File::Slurp;

use Carp qw(carp cluck croak confess);

require Exporter;
@ISA=qw(Exporter);
@EXPORT = qw(ptree html_dir);

sub html_dir {
  't/html/'
}

sub ptree {
  my $tree = shift or confess 'must supply tree';
  my $out = shift or confess 'must supply outfile';
  
  my $hpp = HTML::PrettyPrinter->new
    (tabify => 0, allow_forced_nl => 1, quote_attr => 1);
  my $lines = $hpp->format($tree);
  
  write_file $out, @$lines;
  join '', @$lines;
}



1;
