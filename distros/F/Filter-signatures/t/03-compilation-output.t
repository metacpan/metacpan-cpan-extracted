#!perl -w
use strict;
use Test::More tests => 30;
use Data::Dumper;

require Filter::signatures;

# Mimic parts of the setup of Filter::Simple
my $extractor =
$Filter::Simple::placeholder = $Filter::Simple::placeholder
    = qr/\Q$;\E(.{4})\Q$;\E/s;

# Anonymous
$_ = <<'SUB';
sub ($name, $value) {
        return "'$name' is '$value'"
    };
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Anonymous subroutines get converted";
sub  { my ($name,$value)=@_;();
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
sub foo5 { @_==0 or warn "Subroutine foo5 called with parameters.";();
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
sub mylog { my ($msg,$when)=@_;$when=time if @_ <= 1;();
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
sub mysub { @_==0 or warn "Subroutine mysub called with parameters.";();
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
sub mysub { my (undef)=@_;();
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
sub mysub { my ($foo,undef,$bar)=@_;();
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
sub foo { my ($bar,$baz)=@_;(); print "Yey\n"; }
RESULT

{ local $TODO = "Recursive parentheses don't work on $]"
  if( $] < 5.010 );

$_ = <<'SUB';
sub staleUploads( $self, $timeout = 3600, $now = time() ) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with parentheses work";
sub staleUploads { my ($self,$timeout,$now)=@_;$timeout = 3600 if @_ <= 1;$now = time() if @_ <= 2;();
}
RESULT

$_ = <<'SUB';
sub staleUploads( $self, $timeout = 3600, $now = time((()))) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with multiple parentheses work";
sub staleUploads { my ($self,$timeout,$now)=@_;$timeout = 3600 if @_ <= 1;$now = time((())) if @_ <= 2;();
}
RESULT

$_ = <<'SUB';
sub ( $self, $now = localtime(1)) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments with parentheses and values work";
sub  { my ($self,$now)=@_;$now = localtime(1) if @_ <= 1;();
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
sub  { my ($self,$cb)=@_;$cb = sub { } if @_ <= 1;();

}
RESULT

$_ = <<'SUB';
sub f ($a,@) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Slurpy discard argument works";
sub f { my ($a,undef)=@_;();
...
}
RESULT

$_ = <<'SUB';
my @args;
sub ( $self, $foo = $#args) {
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Default arguments that look like comments";
my @args;
sub  { my ($self,$foo)=@_;$foo = $#args if @_ <= 1;();
}
RESULT

$_ = <<'SUB';
sub f ($a = /\w/ ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Argument lists containing regular expressions work";
sub f { my ($a)=@_;$a = /\w/ if @_ <= 0;();
...
}
RESULT

$_ = <<'SUB';
sub f ($a = \$b, $c=\@d, $e=\%f, $g=\&h, $i=\*j ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Argument lists containing scalar references";
sub f { my ($a,$c,$e,$g,$i)=@_;$a = \$b if @_ <= 0;$c=\@d if @_ <= 1;$e=\%f if @_ <= 2;$g=\&h if @_ <= 3;$i=\*j if @_ <= 4;();
...
}
RESULT

$_ = <<'SUB';
sub f ($a = /\(/ ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Argument lists containing unmatched parentheses work";
sub f { my ($a)=@_;$a = /\(/ if @_ <= 0;();
...
}
RESULT

$_ = <<'SUB';
sub f ($a = /[\(]/ ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Characterclasses with unmatched quoted parentheses work";
sub f { my ($a)=@_;$a = /[\(]/ if @_ <= 0;();
...
}
RESULT

{ local $TODO = "Recursive parentheses don't work on $]"
  if( $] < 5.010 );

$_ = <<'SUB';
sub f ($a = /[\)]/ ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Characterclasses with unmatched quoted parentheses work";
sub f { my ($a)=@_;$a = /[\)]/ if @_ <= 0;();
...
}
RESULT
}

{ local $TODO = 'More robust regexp parsing needed';
$_ = <<'SUB';
sub f ($a = /[(]/ ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Regular expressions containing characterclasses with unmatched parentheses work";
sub f { my ($a)=@_;$a = /\(/ if @_ <= 0;();
...
}
RESULT

$_ = <<'SUB';
sub f ($a = /[)]/ ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Regular expressions containing characterclasses with unmatched parentheses work";
sub f { my ($a)=@_;$a = /[)]/ if @_ <= 0;();
...
}
RESULT

}

{ local $TODO = "Recursive parentheses don't work on $]"
  if( $] < 5.010 );

$_ = <<'SUB';
sub f ($a = qr(\() ) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Argument lists containing unmatched parentheses within qr-strings work";
sub f { my ($a)=@_;$a = qr(\() if @_ <= 0;();
...
}
RESULT
}

$_ = <<'SUB';
sub f ($a = do { }) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "do-blocks work";
sub f { my ($a)=@_;$a = do { } if @_ <= 0;();
...
}
RESULT

{ local $TODO = "Recursive parentheses don't work on $]"
  if( $] < 5.010 );

$_ = <<'SUB';
sub f ($a = substr("abc",0,1)) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Commas within subroutine calls don't split the argument lists";
sub f { my ($a)=@_;$a = substr("abc",0,1) if @_ <= 0;();
...
}
RESULT
}

$_ = <<'SUB';
sub f ($a = /\,/, $b=1) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Commas within regular expression matches don't split the argument lists";
sub f { my ($a,$b)=@_;$a = /\,/ if @_ <= 0;$b=1 if @_ <= 1;();
...
}
RESULT

$_ = <<'SUB';
sub f ($a = /\,/, $b=1) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Commas within regular expression matches don't split the argument lists";
sub f { my ($a,$b)=@_;$a = /\,/ if @_ <= 0;$b=1 if @_ <= 1;();
...
}
RESULT

$_ = <<'SUB';
sub f ($a = do { $x = "abc"; return substr $x,0,1}) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Commas within do-blocks don't split the argument lists";
sub f { my ($a)=@_;$a = do { $x = "abc"; return substr $x,0,1} if @_ <= 0;();
...
}
RESULT

{ local $TODO = "Recursive parentheses don't work on $]"
  if( $] < 5.010 );

$_ = <<'SUB';
sub f ($a = do { $x = "abc"; return substr($x,0,1)}) {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "do-blocks with parentheses work";
sub f { my ($a)=@_;$a = do { $x = "abc"; return substr($x,0,1)} if @_ <= 0;();
...
}
RESULT
}

# This is a test for the placeholders that Filter::Simple supplies - if you
# have enough of them, "interesting" characters pop up within these placeholders
# We have an interesting dependency on the format of these placeholders.
$_ = <<'SUB';
sub f ($a = "...(") {
...
}
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Parentheses in (replaced) string arguments work";
sub f { my ($a)=@_;$a = "...(" if @_ <= 0;();
...
}
RESULT

if( $Test::More::VERSION > 0.87 ) { # 5.8.x compatibility
    done_testing();
};
