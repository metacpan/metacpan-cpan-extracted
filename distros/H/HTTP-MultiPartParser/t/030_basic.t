#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use HTTP::MultiPartParser qw[];
use PAML                   qw[];
use Cwd                    qw[getcwd];
use File::Spec::Functions  qw[catdir catfile];

use Test::More;
use Test::Deep;

my $base = catdir(getcwd(), 't', 'data');

foreach my $number ('001'..'012') {
    my $test = PAML::LoadFile(catfile($base, "$number-test.pml"));
    my $exp  = PAML::LoadFile(catfile($base, "$number-exp.pml"));
    my $path = catfile($base, "$number-content.dat");

    my @got;
    my %part;

    my $on_header = sub {
        my ($header) = @_;
        $part{header} = $header;
    };

    my $on_body = sub {
        my ($chunk, $final) = @_;

        $part{body} .= $chunk;
        if ($final) {
            push @got, { %part };
            %part = ();
        }
    };
    
    my $parser = HTTP::MultiPartParser->new(
        boundary  => $test->{boundary},
        on_header => $on_header,
        on_body   => $on_body,
    );

    open(my $fh, '<:raw', $path)
      or die qq/Could not open: '$path': '$!'/;

    while () {
        my $n = read($fh, my $buffer, 1024);
        unless ($n) {
            die qq/Could not read from fh: '$!'/
              unless defined $n;
            last;
        }
        $parser->parse($buffer);
    }
    $parser->finish;
    cmp_deeply(\@got, $exp, "$number-content.dat");
}

done_testing();

