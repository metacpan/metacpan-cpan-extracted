# NAME

Error::Show - Show context around syntax errors and exceptions

# SYNOPSIS

## Command Line Syntax Checking

Consider the following program (at examples/synopsis.pl in this distribution).
It has a syntax error on line 13, and uses an experimental feature on line 7.

```perl
use strict;
use warnings;
use Time::HiRes;

use feature "refaliasing";

\my $a=\"hello";
my $time=time;
for(1..1000){
  print "$_\n";
}

my $crazy-var=2;

use Socket;

print "this will never work";
```

Attempting to run this program with perl normally gives this error output:

```perl
->perl examples/synopsis.pl       
Aliasing via reference is experimental at examples/synopsis.pl line 7.
Can't modify subtraction (-) in scalar assignment at examples/synopsis.pl line 13, near "2;"
BEGIN not safe after errors--compilation aborted at examples/synopsis.pl line 15.
```

With `Error::Show` enabled with the `-M` switch, this instead looks like this:

```perl
->perl -MError::Show=warn  examples/synopsis.pl
examples/synopsis.pl
 3   use Time::HiRes;
 4
 5   use feature "refaliasing";
 6
 7=> \my $a=\"hello";
 8   my $time=time;
 9   for(1..1000){
10    print "$_\n";
11   }
12
Aliasing via reference is experimental at examples/synopsis.pl line 7.
examples/synopsis.pl
 9   for(1..1000){
10    print "$_\n";
11   }
12
13=> my $crazy-var=2;
14
15   use Socket;
16
17   print "this will never work";
Can't modify subtraction (-) in scalar assignment at examples/synopsis.pl line 13, near "2;"
examples/synopsis.pl
11   }
12
13   my $crazy-var=2;
14
15=> use Socket;
16
17   print "this will never work";
BEGIN not safe after errors--compilation aborted at examples/synopsis.pl line 15.
```

## Command Line Exception Call Stack Dump (from v0.4.0)

Consder the following short program (examples/synopsis2.pl

```perl
use v5.36;

sub test {

  my $a=1/0;
}


test;
```

Running this program with perl normally gives this error output:

```
perl examples/synopsis2.pl  
Illegal division by zero at examples/synopsis2.pl line 5.
```

With `Error::Show` enabled with the `-M` switch, this instead looks like this:

```perl
perl -MError::Show examples/synopsis2.pl
examples/synopsis2.pl
1   use v5.36;
2
3   sub test {
4
5=>   my $a=1/0;
6   }
7
8
9   test;
Illegal division by zero at examples/synopsis2.pl 5

    examples/synopsis2.pl
    4
    5     my $a=1/0;
    6   }
    7
    8
    9=> test;
Illegal division by zero at examples/synopsis2.pl 5
```

## In Program

Use at runtime to supplement exception handling without signal handler modification:

```perl
use Error::Show;

#an die caught in a try/eval triggers an exception

# No argument uses $@ as error
#
eval { exceptional_code };
say STDERR context if $@;


# or a single exception argument of your choosing
#
use v5.36;
try { 
  exceptional_code
}
catch($e) {
  say STDERR context $e;
}

# Show context down a stack

try {

  Some_execption_class->throw("Bad things");

}
catch($e){
  say STDERR context message=>$e, frames=>$e->frames
}

```

# DESCRIPTION

From the command line this module transparently executes your syntactically
correct program. However in the case of syntax errors (or warnings if desired),
it extracts context (lines of code) surrounding them. The lines are prefixed
with numbers  and the nicely formatted context is dumped on STDERR for you to
see the error or your ways.

The resulting output is optionally filtered seamlessly through the **splain**
program (see [diagnostics](https://metacpan.org/pod/diagnostics)), giving more information on why the reported
syntax errors and warnings might have occurred. 

From within a program at runtime, this module can be used to give the same
formatted code context around the source of an exception and iterate through
any associated stack frames if provided.

It supports perl string exceptions and warnings directly and also provides the
ability to integrate third party CPAN exception objects and traces with minimal
effort. Please see examples in this document or in the examples directory of
the distribution showing use with [Mojo::Exception](https://metacpan.org/pod/Mojo%3A%3AException), [Exception::Base](https://metacpan.org/pod/Exception%3A%3ABase),
[Exception::Class::Base](https://metacpan.org/pod/Exception%3A%3AClass%3A%3ABase) and [Class::Throwable](https://metacpan.org/pod/Class%3A%3AThrowable).

A handful of options are available for basic configuration of how many lines of
code to print before and after the error line, indenting of stack trace
context, etc.

**From v0.3.0:** `context` subroutine is now exported by default. To prevent
this, import with an empty list, ie `use Error::Show ()`.

`From v0.2.0:`, Added 'advanced string eval' support has been added for better
context reporting of dynamically generated code.

# USAGE

## Command Line Usage (Syntax check and Exception Catching)

```
    perl -MError::Show  [options] file.pl 
```

When included in a command line switch to perl, `-MError::Show` syntax checks
the input program. If the syntax is OK, normal execution continues in a
transparent fashion.  Otherwise, detailed code context surrounding the source
of the error is generated and printed on STDERR.

**From v0.4.0** a global \_\_DIE\_\_ handler is also installed, which will catch any
stray execptions during execution and present a line numbered summary stack
trace. Programs a free to overload this handler. However the features of this
moudle will be lost.

**NOTE:** It is important that it's the first `-M` switch for this module to
operate correctly and to prevent any incompatibilites withe global signal
handlers.

If the **-c** flag is specified, only a syntax check will be performed,
mimicking normal perl behaviour.

Additional `@INC` directories using the **-I** switch are supported as are
additional modules via the **-M** switch.

### CLI Usage Options

The following options can be used in isolation or together:

#### clean

If you prefer just the code context without the perl error, add the clean
option:

```
perl -MError::Show=clean file.pl
```

#### warn

This options enables processing of warnings as well as errors.

```
perl -MError::Show=warn file.pl
```

#### splain

Runs the output through the splain program (see [diagnostics](https://metacpan.org/pod/diagnostics)), giving
probable reasons behind the error or warning

```
perl -MError::Show=splain file.pl
```

#### no\_handler (from v0.4.0)

```
perl -MError::Show=no_handler file.pl
```

Prevents the global DIE handler from being installed.

### Return code

When in check only mode (-c), the main process is exited, just has perl
normally would have done. The return code is a replica of what perl would have
reported for success/failure of a syntax check.

## In Program (Exception) Usage

Simply bring [Error::Show](https://metacpan.org/pod/Error%3A%3AShow) into your program with a use statement:

```perl
use Error::Show;
```

It provides a single subroutine for processing errors and exceptions.

### Error::Show::context

```perl
my $context=Error::Show::context;                     (1)
my $context=Error::Show::context $error;              (2)
my $context=Error::Show::context option_pairs, message=>$error_as_string, frames=>$stack frames (3)

my $context=Error::Show::context undef;               (4)
my $context=context undef;                            (5)

my $context=Error::Show->context(...);                (6)

      
```

Takes an error string, or exception object and extracts the code surrounding
the source of the error. The code lines are prefixed with line numbers and the
error line marked with a fat arrow.

The return value is the formatted context, followed by the original perl error
strings, or stringified exception objects/messages:

```perl
filename.pl 
10  #code before 
11  #code before 
12=>#this line caused the error
13  #code after
14  #code after

... error... at filename.pl line 12 ...
```

In the first form (1), the `$@` variable is implicitly used as the error. No
processing options can be supplied in this form. This is stringified for
processing.

In the second form (2), a single argument is supplied, which becomes the error
to process. No processing options can be supplied in this form. This is
stringified for processing.

In the third for (3), all options are provided as key value pairs. 

**From v0.3.0:** In the forth form (4), an explicit single argument of `undef`,
will generate call stack/frames internally and generate context information
from it.

The `context` subroutine (5) is exported by default, so does not need a fully
qualified name

`context` Can also be called with package arrow notation (6) ie
`Error::Show->context(...)` if prefered, with the same arguemtn handling
as the other forms.

The expected types of data are as follows:

- 1. String Errors (perl errors)

    Error string, as per `die` and `warn`, containing file and line number. These
    are extracted from the string error to locate context.

    The output message after the context is this string, 

- 2. An reference to an array containing results from `caller`

    The filename, and line elements are used to process. No error message is output
    unless the **message** option is also specified. 

- 3. An Devel::StackTrace::Frame object

    This is converted internally to a array of `caller()` output. As above.

- 4. or, an array of 2. or  3.

    An reference to an array of call frames in `caller()` or
    `Devel::StackTrace::Frame` format can also be supplied as the error or frames.
    Again the `message` option needs to be provided if error string is required in
    the output.

**Options include:**

#### limit 

```perl
limit=>$int
```

**From v0.2.0:** Limits the number of errors to extract and generate context
for. Default is 100. If <=0,  no limiting is applied all all errors are
processed.

#### reverse

```perl
reverse=>$bool
```

**From v0.2.0:** Reverses the order of error processing. 

Perl type string errors are sorted and processing in ascending line number
order. When this option is used, the lines are processed by descending line
number first. Does not change order of files processed.

If frames are used instead, they are processed in reverse order to how they
where supplied when this option is in effect.

#### pre\_lines

```perl
pre_lines=>value
```

Specific the maximum lines of code to display before the error line. Default is
5.

#### post\_lines

```perl
post_lines=>value
```

Specific the maximum lines of code to display after the error line. Default is
5.

#### clean

```perl
clean=>bool
```

When true, the normal perl error string is not included in the context
information, for a cleaner look.

#### indent

```perl
indent=>string
```

The string to use for each level of indent when printing multiple stack frames.
Defaults to 4 spaces.

#### splain

```perl
splain=>1
```

The resulting output will be filtered through the [splain](https://metacpan.org/pod/splain) program.  

#### program

```perl
program=>$prog
```

The **program** option is used to specify the program text to process when
there is no actual file. This is needed when to show syntax errors in a string
`eval`:

```perl
my $prog='my $a="This will Fail"+b';
eval $prog;
if($@){
  say Error::Show::context error=>$@, program=>prog;
}
```

For advanced string eval processing options please see the **ADVANCED STRING
EVAL** section in this document.

# EXAMPLES

## Integrating with Exception classes

The following are a cheat sheet / example code to interoperate this module with
exception objects.

The most reliable way is usually to explicitly set the **message** and **frames**
options explicitly. This works with a single frame (for the latest exception)
or ref to array, for a complete trace

### Mojo::Exception

**FYI:** [Mojo::Exception](https://metacpan.org/pod/Mojo%3A%3AException) does provide it's own facility to show the code
context around an exception.

```perl
use v5.36;
use feature "try";
use Error::Show;
use Mojo::Exception qw<check raise>;

try{
  raise 'MyApp::X::Name', 'The name Minion is already taken';
}
catch($e){

  # Message is the stringified $e object. Print the first frame
  #
  say Error::Show::context message=>$e, error=> $e->frames->[0];


  # Message is the stringified $e object. Print all frames
  #
  say Error::Show::context message=>$e, error=>$e->frames;

}
```

### Class::Throwable

```perl
use v5.36;
my @a=qw<a,b,c>;
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
    say Error::Show::context message=>$e, frames=>$e->getStackTrace->[0];

    #Show the whole stack
    say Error::Show::context message=>"$e", frames=>[$e->getStackTrace];
  }
}

sub my_func2{
  my_func;
}
warn "some warning";
my_func2;
```

### Exception::Base

```perl
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
```

### Exception::Class::Base

```perl
use v5.36;
use Exception::Class;
use Error::Show;
use feature "try";
try{
  Exception::Class::Base->throw("An error occured");
}
catch($e){

  my @frames=$e->trace->frames;
  
  # Message is the stringified $e object. Print the first frame
  #
  say Error::Show::context message=>$e, frames=>$frames[0];

  # Message is the stringified $e object. Print all frames
  #
  say Error::Show::context message=>$e, frames=>\@frames;

}
```

### Syntax Checking String `eval`, Without Execution

A block eval will have it's syntax checked during normal compilation time. A
string eval is checked at run time and it uses the same variable `$@` to
report syntax errors and run time errors. 

Together these limitation make it impossible to distinguish between syntax
errors and runtime errors (without some kind of heavy error lookup). The code
is also executed immediately.

To work around these limitations, and have `Error::Show` still provide context
information, start by wrapping your eval string with "sub { ... }.  The eval
result will be code ref if syntactically correct. Otherwise the error in `$@`
is the syntax error string, which can be feed directly into `Error::Show`.
The code ref is executed in a block eval, which if dies from an exception will
place the runtime error in `$@`, which again can be used in `Error::Show`.
As an example:

```perl
Example: Separate compiling/syntax checking from eval execution
=======

use strict;
use warnings;
use feature "say";

use Error::Show;


# Orginal string to eval
my $prog='say "hello there";
$a+1/0;
';

# Wrap string in a sub

$prog="sub { $prog }";


# Do an eval to retun an actual code ref

my $code =eval $prog; 


# Check for syntax errors here. No run time error as the code ref has not been executed.
# Use the program option in Error::Show to specifiy the text of the program

if($@){
  say "ERROR is".Error::Show::context error=>$@, program=>$prog;
}

# Execute the code reference. Any errors here are run time

eval {$code->()};

# Again use the program option in Error::Show to specifiy the text of the program

if($@){
  say "ERROR is".Error::Show::context error=>$@, program=>$prog;
}
```

Please see the examples directory in this distribution

# ADVANCED STRING EVAL

**From v0.2.0** features to support advanced string evaluation are available.
This was added to support the error reporting needs of the [Template::Plex](https://metacpan.org/pod/Template%3A%3APlex)
module.

Consider the following example. The 'meat' is the sub  in the middle of the
string. Any errors/context reported should be relative to this, not the start
of the overall eval string. With some help from comment markers "##\_PREAMBLE"
and "##\_POSTAMBLE",  when can search for the middle and rebase the error line
numbering.

```perl
eval {
  "my $some_prep_work=1;
  call_somthing();
  #comments...
  
  ##_PREAMBLE

  sub {
     #code generated from user input...
     say "My really cool dynamically created code"
  }

  ##_POSTAMBLE

  #More code 
  #Cleanup stuff.
  "
}
```

Additional configuration options can be provided  to search for the relevant
code lines and offset the error line numbers.

**NOTE** if these options are used, the **message** field is modified with
updated line numbers if its in the form of a normal perl errors ie 'error line
123 at file'.

### start\_mark

```perl
start_mark=>$regexp
```

If specified, is a used as a regexp to match against source code lines. The line
after a successful match is now the first line.

This allows inserting a special marker to indicate the start of 'code of
interest' with out knowing the exact line number in the resulting code.

This is undefined and unused by default.

### end\_mark

```perl
end_mark=>$regexp
```

If specified, is used as a regexp to match against source lines, in reverse
order. The line after a successful match is now the last line

This allows inserting a special marker to indicate the end of 'code of
interest'.

This is undefined unused by default.

### start\_offset

```perl
start_offset=>$int
```

A static offset to add to the start line (which may have been modified by the
**start\_mark** option). The result will be classed as the minimum line number of
the file/string.

This is useful to prevent any preamble after the start\_mark line in your string
eval showing up in the user program context.

### end\_offset

A static offset to subtract to the end line (which may have been modified by
the **end\_mark** option). The result will be classed as the maximum line number
of the file.

This is useful to prevent any postamble before the end\_mark in your string eval
showing up in the user program context.

# FUTURE WORK/TODO

- Possible just use the DIE and WARN signal handler instead of forking processes
- Make usable from a Language Server?
- Colour terminal output
- JSON output?

# KNOWN ISSUES/GOTCHAS

Checking/running  programs via STDIN, -e and -E switches is not supported and
will die with an error message.

More data then needed is pushed through the splain program when splain option
is used, which isn't ideal.

# SEE ALSO

[Perl::Syntax](https://metacpan.org/pod/Perl%3A%3ASyntax) provides syntax checking from the command line. However it
doesn't show any errors by design (only interested in process return code)

[Syntax::Check](https://metacpan.org/pod/Syntax%3A%3ACheck) provides programmatic syntax checking of files.

[Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) gives actual perl linting, but not great for syntax errors.

[diagnostics](https://metacpan.org/pod/diagnostics)  and the `splain` program give some very useful explanations
about the otherwise terse error strings normally output. It is part of the perl
distribution

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# REPOSITORTY and BUGS

Please report any bugs via git hub:
[http://github.com/drclaw1394/perl-error-show](http://github.com/drclaw1394/perl-error-show)

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl or the MIT license.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.
