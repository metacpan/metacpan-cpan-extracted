use Test2::V0 -no_srand => 1;
use FFI::TinyCC;

foreach my $type (qw( memory exe dll obj ))
{
  subtest $type => sub {
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type($type) };
    is $@, '', 'tcc.set_output_type';
  
  };
}

done_testing;
