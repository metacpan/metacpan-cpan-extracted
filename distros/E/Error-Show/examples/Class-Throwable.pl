use v5.36;
my @a=qw<a b c>;
use Class::Throwable;# VERBOSE=>1;
Class::Throwable->setVerbosity(2);
#use Exception::Class;
use Error::Show;
use feature "try";
sub my_func {
  try{
    Class::Throwable->throw("Something has gone wrong");

  }
  catch($e){
    #Show the top of the stack, the latest exception
    say Error::Show::context $e;

  }
}

sub my_func2{
  my_func;
}
warn "some warning";
my_func2;
