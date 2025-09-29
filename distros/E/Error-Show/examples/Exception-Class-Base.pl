use Exception::Class;
use Error::Show;
use v5.36;
use feature "try";
sub my_func {
  try{
    Exception::Class::Base->throw("An error occured");
  }
  catch($e){

    say Error::Show::context $e;

  }


  my $string='
  sub inner {
    Exception::Class::Base->throw("An error occured");
    }
    inner();
   ';
   local $@;
  eval  $string;
  my $error=$@;
  if($error){
    say Error::Show::context $error;
  }
}

sub my_func2{
  my_func;
}

my_func2;
