# JSV::Compiler - Translates JSON-Schema validation rules (draft-06) into perl code
 
## SYNOPSIS

```perl
  use JSV::Compiler;
 
  my $jsv = JSV::Compiler->new;
  $jsv->load_schema({
    type => "object",
    properties => {
      foo => { type => "integer" },
      bar => { type => "string" }
    },
    required => [ "foo" ]
  });
  my $vcode = $jsv->compile();
  my $test_sub_txt = <<"SUB";
  sub { 
      my \$errors = []; 
      $vcode; 
      print "\@\$errors\\n" if \@\$errors;
      print "valid\n" if \@\$errors == 0;
      \@\$errors == 0;
  }
  SUB
  my $test_sub = eval $test_sub_txt;

  $test_sub->({}); # foo is required
  $test_sub->({ foo => 1 }); # valid
  $test_sub->({ foo => 10, bar => "xyz" }); # valid
  $test_sub->({ foo => 1.2, bar => "xyz" }); # foo does not look like integer number
```
