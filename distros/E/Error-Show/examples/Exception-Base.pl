use v5.36;
use feature qw<try say>;

use Exception::Base verbosity=>4;
use Error::Show;

sub my_func {
  try{
    my $e= Exception::Base->new();
    #$e->verbosity(10);
    $e->throw(message=>"Bad things");

  }
  catch($e){
    
    # Set verbosity to stop duplicate outputs, but provide a file and line number
    # in the stringified version of the error
    #
    $e->verbosity=2;

    # Message normally contatins the file and line numbers. So stringified
    # process will work
    #
    say Error::Show::context $e;

    # Access the frames in the caller stack
    #
    say Error::Show::context message=>$e->message, frames=>$e->caller_stack;
  }
}

sub my_func2{
  my_func;
}

my_func2;
