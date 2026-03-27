use strict;
use warnings;
use Test::More;

my $class;
{
  package ParserWithAccurateTargets;
  $class = __PACKAGE__;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::XHTML::WithAccurateTargets';
}

my $parser = $class->new;

$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =encoding UTF-8

  =head1 NAME

  Pod::Document - With an abstract

  =head1 SYNOPSIS

    welp();

  =head1 METHODS

  =head2 $self->some_method( \%options );

  =head2 $<digit>

  L<< /$<digit> >>

  =head2 The "Unicöde Bug"

  L<< /The "Unicöde Bug" >>

  =head2 Outside ISO-8859-1 range 🐈

  L<< /Outside ISO-8859-1 range 🐈 >>

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output, qr/Pod::Document/;
like $output, qr/<h2 id="\$self-&gt;some_method\(-\\%options-\);">/;
like $output, qr/<h2 id="\$&lt;digit&gt;">/;
like $output, qr/<a href="#%24%3Cdigit%3E">/;
like $output, qr/<h2 id="The-&quot;Unic&ouml;de-Bug&quot;">/;
like $output, qr/<a href="#The-%22Unic%C3%B6de-Bug%22">/;
like $output, qr/<h2 id="Outside-ISO-8859-1-range-&#x1F408;">/;
like $output, qr/<a href="#Outside-ISO-8859-1-range-%F0%9F%90%88">/;

done_testing;
