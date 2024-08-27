use strict;
use warnings;
use Test::More;

my $class;
{
  package ParserWithHTML5;
  $class = __PACKAGE__;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::XHTML::HTML5';
}

my $parser = $class->new;

$parser->index(1);

$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =head1 NAME

  Pod::Document - With an abstract

  =head1 SYNOPSIS

    welp();

  =head1 METHODS

  =over

  =item welp

  Welps.

  =back

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output, qr{\A<!DOCTYPE html>}, 'starts with proper doctype';
unlike $output, qr{/>}, 'no self terminating tags';
like $output, qr{<nav><ul>}, 'index is in a <nav>';
like $output, qr{</ul></nav>}, 'index nav properly terminated';
done_testing;
