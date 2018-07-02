use strict;
use warnings;
use Test::More;

my $class;
{
  package ParserWithLinkMappings;
  $class = __PACKAGE__;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::XHTML::WithLinkMappings';
}

my $parser = $class->new;

$parser->link_mappings({
  'List::Util::PP' => 'release/HAARG/List-Util-MaybeXS-1.50/lib/List/Util/PP.pm',
});
$parser->perldoc_url_prefix('https://metacpan.org/pod/');

$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =pod

  L<List::Util> L<List::Util::PP>

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output, qr{href="https://metacpan\.org/pod/List::Util"};
like $output, qr{href="https://metacpan\.org/pod/release/HAARG/List-Util-MaybeXS-1.50/lib/List/Util/PP\.pm"};

done_testing;
