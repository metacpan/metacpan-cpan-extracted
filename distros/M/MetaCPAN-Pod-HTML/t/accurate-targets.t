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
  =head1 NAME

  Pod::Document - With an abstract

  =head1 SYNOPSIS

    welp();

  =head1 METHODS

  =head2 $self->some_method( \%options );

  =head2 $<digit>

  L<< /$<digit> >>

  =head2 The "Unicode Bug"

  L<< /The "Unicode Bug" >>

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output, qr/Pod::Document/;
like $output, qr/<h2 id="\$self-&gt;some_method\(-\\%options-\);">/;
like $output, qr/<h2 id="\$&lt;digit&gt;">/;
like $output, qr/<a href="#%24%3Cdigit%3E">/;
like $output, qr/<h2 id="The-&quot;Unicode-Bug&quot;">/;
like $output, qr/<a href="#The-%22Unicode-Bug%22">/;
done_testing;
