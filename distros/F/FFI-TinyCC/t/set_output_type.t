use strict;
use warnings;
use Test::More tests => 4;
use FFI::TinyCC;

foreach my $type (qw( memory exe dll obj ))
{
  subtest $type => sub {
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type($type) };
    is $@, '', 'tcc.set_output_type';
  
  };
}
