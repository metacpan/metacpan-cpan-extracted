package Test::TestObj ;

sub new {
  my $class = shift;

  bless { _prop => 42 }, $class;
}

sub do_something {
}

1; # Magic true value
# ABSTRACT: this is what the module does
