use strict;
use warnings;
use Test::More;

my $class;
{
  package ParserWithAccurateTargets;
  $class = __PACKAGE__;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::StripVerbatimIndent';
}

my $parser = $class->new;
$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =head1 SYNOPSIS

      Foo
        Bar

      Guff

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document("$pod");

like $output, qr{(?:>|^)Foo}m;
like $output, qr{(?:>|^)  Bar}m;
like $output, qr{(?:>|^)Guff}m;

$parser = $class->new;
$parser->output_string( \($output = '') );
$parser->strip_verbatim_indent(sub { undef });
$parser->parse_string_document("$pod");

like $output, qr{(?:>|^)    Foo}m;
like $output, qr{(?:>|^)      Bar}m;
like $output, qr{(?:>|^)    Guff}m;

$parser = $class->new;
$parser->output_string( \($output = '') );
$pod = <<"END_POD";
  =head1 SYNOPSIS

      Foo
      Bar\tBar
      Guff\tGuff

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document("$pod");

like $output, qr{(?:>|^)Foo}m;
like $output, qr{(?:>|^)Bar	Bar}m;
like $output, qr{(?:>|^)Guff	Guff}m;

$parser = $class->new;
$parser->output_string( \($output = '') );
$parser->expand_verbatim_tabs(8);
$pod = <<"END_POD";
  =head1 SYNOPSIS

      Foo
  \tBar\tBar
      Guff\tGuff

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document("$pod");

like $output, qr{(?:>|^)Foo}m;
like $output, qr{(?:>|^)    Bar Bar}m;
like $output, qr{(?:>|^)Guff    Guff}m;

done_testing;
