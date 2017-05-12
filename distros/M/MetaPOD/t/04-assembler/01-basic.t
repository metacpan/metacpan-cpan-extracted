use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MetaPOD::Assembler;

use FindBin;
use Path::Tiny qw(path);

my $corpus = path($FindBin::Bin)->parent->parent->child('corpus')->child('basic');

sub lives {
  my ( $exception, $reason ) = @_;
  return is( $exception, undef, $reason );
}

lives exception {
  my $assembler = MetaPOD::Assembler->new();
},
  'construct';

lives exception {
  MetaPOD::Assembler->new()->result;
}, 'load result';

lives exception {
  MetaPOD::Assembler->new()->extractor;
}, 'load extractor';

{

  package t::basic;
  use Moo;
  with 'MetaPOD::Role::Format';

  sub add_segment {
    my ( $self, $segment, $result ) = @_;
    $result->set_namespace( $segment->{data} );
  }
  $INC{'t/basic.pm'} = 1;
}
my $result;
lives exception {
  $result = MetaPOD::Assembler->new( format_map => { 'Test::Basic' => 't::basic' } )
    ->assemble_file( $corpus->child('01_format_basic.pm') );
}, 'try parse a file';

isa_ok( $result, "MetaPOD::Result" );
done_testing;

