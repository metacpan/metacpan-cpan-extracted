use v5.36;
use Mojo::Exception qw(check raise);
use Error::Show;
use feature "try";
sub my_func {
  try{
    raise 'MyApp::X::Name', 'The name Minion is already taken';
  }
  catch($e){
    say Error::Show::context $e;
  }

  my $string='"Hello
    and something eler
   to look at"';

  local $@;
  eval $string;
  if($@){
    say Error::Show::context $@;
  }
}

sub my_func2{
  my_func;
}

my_func2;
