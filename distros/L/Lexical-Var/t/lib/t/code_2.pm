use Lexical::Var '&foo' => sub { 2 };
push @main::values, &foo;
1;
