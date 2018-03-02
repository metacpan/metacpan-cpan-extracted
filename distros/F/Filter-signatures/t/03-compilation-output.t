#!perl -w
use strict;
use Test::More tests => 13;
use Data::Dumper;

require Filter::signatures;

# Anonymous
$_ = <<'SUB';
sub ($name, $value) {
        return "'$name' is '$value'"
    };
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Anonymous subroutines get converted";
sub  { my ($name,$value)=@_;
        return "'$name' is '$value'"
    };
RESULT

$_ = <<'SUB';
sub foo5 () {
        return "We can call a sub without parameters"
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Parameterless subroutines don't get converted";
sub foo5 { @_==0 or warn "Subroutine foo5 called with parameters.";
        return "We can call a sub without parameters"
};
RESULT

# Function default parameters
$_ = <<'SUB';
sub mylog($msg, $when=time) {
    print "[$when] $msg\n";
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Function default parameters get converted";
sub mylog { my ($msg,$when)=@_;$when=time if @_ <= 1;
    print "[$when] $msg\n";
};
RESULT

# Empty parameter list
$_ = <<'SUB';
sub mysub() {
    print "Yey\n";
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Functions without parameters get converted properly";
sub mysub { @_==0 or warn "Subroutine mysub called with parameters.";
    print "Yey\n";
};
RESULT

# Discarding parameters
$_ = <<'SUB';
sub mysub($) {
    print "Yey\n";
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Functions with unnamed parameters get converted properly";
sub mysub { my (undef)=@_;
    print "Yey\n";
};
RESULT

# Discarding parameters
$_ = <<'SUB';
sub mysub($foo, $, $bar) {
    print "Yey, $foo => $bar\n";
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Functions without parameters get converted properly";
sub mysub { my ($foo,undef,$bar)=@_;
    print "Yey, $foo => $bar\n";
};
RESULT

# Signature-less functions remain unchanged
$_ = <<'SUB';
sub mysub {
    print "Yey\n";
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Named functions without signature remain unchanged";
sub mysub {
    print "Yey\n";
};
RESULT

$_ = <<'SUB';
sub {
    print "Yey\n";
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Named functions without signature remain unchanged";
sub {
    print "Yey\n";
};
RESULT

$_ = <<'SUB';
sub foo($bar,$baz) { print "Yey\n"; }
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "RT #xxxxxx Single-line functions work";
sub foo { my ($bar,$baz)=@_; print "Yey\n"; }
RESULT

{ local $TODO = "Recursive parentheses don't work on $]"
  if( $] < 5.010 );

$_ = <<'SUB';
sub staleUploads( $self, $timeout = 3600, $now = time() ) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with parentheses work";
sub staleUploads { my ($self,$timeout,$now)=@_;$timeout = 3600 if @_ <= 1;$now = time() if @_ <= 2;
}
RESULT

$_ = <<'SUB';
sub staleUploads( $self, $timeout = 3600, $now = time((()))) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with multiple parentheses work";
sub staleUploads { my ($self,$timeout,$now)=@_;$timeout = 3600 if @_ <= 1;$now = time((())) if @_ <= 2;
}
RESULT

$_ = <<'SUB';
sub ( $self, $now = localtime(1)) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with parentheses and values work";
sub  { my ($self,$now)=@_;$now = localtime(1) if @_ <= 1;
}
RESULT

}

$_ = <<'SUB';
sub ( $self, $cb = sub {
}) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with parentheses and values work";
sub  { my ($self,$cb)=@_;$cb = sub { } if @_ <= 1;

}
RESULT

if( $Test::More::VERSION > 0.87 ) { # 5.8.x compatibility
    done_testing();
};