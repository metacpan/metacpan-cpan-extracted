use strict;
use warnings;
use Test::More;

my $class;
{
  package ParserWithErrata;
  $class = __PACKAGE__;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::XHTML::WithErrata';
}

my $parser = $class->new;

$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =pod

  Queensrÿche

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output, qr{<p>1 POD Error</p>};
like $output, qr{<dt>Around line 3:</dt>};
like $output, qr{<dd><p>Non-ASCII character seen before =encoding in &#39;Queensr&yuml;che&#39;\. Assuming UTF-8</p></dd>};

done_testing;
