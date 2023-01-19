use Exception::Class;
use Error::Show;
use v5.36;
use feature "try";
sub my_func {
  try{
    Exception::Class::Base->throw("An error occured");
  }
  catch($e){

    my @frames=$e->trace->frames;
    say Error::Show::context message=>$e, frames=>[@frames[0]];#{line=>$e->line, file=>$e->file, message=>"$e"};

  }


  my $string='"Hello
    and something eler
   to look at"';
  eval  $string;
  if($@){
    say Error::Show::context program=>$string, error=>$@;
  }
}

sub my_func2{
  my_func;
}

my_func2;
