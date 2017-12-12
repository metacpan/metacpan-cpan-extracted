use strict;
use warnings;
use Test::More;

use MetaCPAN::Pod::XHTML;

my $parser = MetaCPAN::Pod::XHTML->new;

$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =head1 NAME

  Pod::Document - With an abstract

  =head1 SYNOPSIS

    welp();

  =head1 METHODS

  =head2 $self->some_method( \%options );

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output, qr/Pod::Document/;
like $output, qr/<h2 id="\$self-&gt;some_method\(-\\%options-\);">/;
like $output, qr/<a id="self--some_method---options">/;

done_testing;
