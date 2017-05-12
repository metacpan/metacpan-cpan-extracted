use strict;
use warnings;

use Test::More tests => 3;

# FILENAME: 01-piecewise-xml.t
# ABSTRACT: Basic Test for decoding XML

use IO::Async::Loop;

open my $fh, '<', 't/data-xml/KENTNL.xml';

my @aelem_stack_name;
my %path_count;

my $seen_start;
my $seen_end;

{

  package Test;
  use parent 'IO::Async::XMLStream::SAXReader';

  sub on_start_document {
    $seen_start       = 1;
    @aelem_stack_name = ( '', );
  }

  sub on_end_document {
    $seen_end = 1;
    $_[0]->{loop}->stop;
  }

  sub on_start_element {
    my ( $self, $args ) = @_;
    push @aelem_stack_name, $args->{Name};
    my $node = join q[/], @aelem_stack_name;
    $path_count{$node}++;
  }

  sub on_end_element {
    my ( $self, $args ) = @_;
    pop @aelem_stack_name;
  }

}

my $loop = IO::Async::Loop->new();

my $stream = Test->new( handle => $fh, );
$stream->{loop} = $loop;

$loop->add($stream);
$loop->run;
ok( $seen_start, 'Document start was seen' );
ok( $seen_end,   'Document end was seen' );
is_deeply(
  \%path_count,
  {
    '/rdf:RDF'                              => 1,
    '/rdf:RDF/channel'                      => 1,
    '/rdf:RDF/channel/description'          => 1,
    '/rdf:RDF/channel/items'                => 1,
    '/rdf:RDF/channel/items/rdf:Seq'        => 1,
    '/rdf:RDF/channel/items/rdf:Seq/rdf:li' => 116,
    '/rdf:RDF/channel/link'                 => 1,
    '/rdf:RDF/channel/title'                => 1,
    '/rdf:RDF/item'                         => 116,
    '/rdf:RDF/item/content:encoded'         => 116,
    '/rdf:RDF/item/dc:creator'              => 116,
    '/rdf:RDF/item/dc:date'                 => 116,
    '/rdf:RDF/item/description'             => 116,
    '/rdf:RDF/item/link'                    => 116,
    '/rdf:RDF/item/title'                   => 116
  },
  "Elements seen match expected count"
);
