package JavaScript::Shell;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Spec;
use Carp;
use JSON::XS;
use IPC::Open2;
our $VERSION = '0.02';
#===============================================================================
# Global Methods
#===============================================================================
my $MethodsCounter = 0;
my $METHODS = {
    ##pre defined methods
    __stopLoop => \&stop,
    _deleteTempFile => sub {
        shift;
        my $args = shift;
        unlink $args;
    }
};

#===============================================================================
# stop
#===============================================================================
sub stop {
    my $self = shift;
    my $args = shift;
    $self->{_return_value} = $args;
    $self->{running} = 0;
}

sub new {
    my $class = shift;
    my $opt = shift;
    
    if ($opt->{onError} && ref $opt->{onError} ne 'CODE'){
        croak "onError options accepts a code ref only";
    } else {
        $opt->{onError} = sub {
            my $js = shift;
            my $error = shift;
            #$js->destroy();
            
            print STDERR $error->{type}
            . ' : '
            . $error->{message}
            . ' at '
            . $error->{file}
            . ' line ' . $error->{line} . "\n";
            exit(1);
        }
    }
    
    ( my $path = $INC{'JavaScript/Shell.pm'} ) =~ s/\.pm$//;
    
    my $js = "$path/bin/js";
    $js = File::Spec->canonpath( $js );
    
    local $ENV{LD_LIBRARY_PATH} = "$path/bin";
    
    my $self = bless({
        running => 0,
        _path => $path,
        _json => JSON::XS->new,
        _ErrorHandle => $opt->{onError},
        _js => $js,
        pid => $$
    },$class);
    
    $self->_run();
    return $self;
}

#===============================================================================
# createContext
#===============================================================================
sub createContext {
    my $self = shift;
    my $sandbox = shift;
    if (defined $sandbox && ref $sandbox ne 'HASH'){
        croak "createContext accepts HASH Ref Only";
    }
    return JavaScript::Shell::Context->new($self,$sandbox);
}

#===============================================================================
# helpers
#===============================================================================
sub path        {   shift->{_path}                  }
sub json        {   shift->{_json}                  }
sub toJson      {   shift->{_json}->encode(@_)   }
sub toObject    {   shift->{_json}->decode(@_)   }
sub context     {   shift->{context}                }
sub watcher     {   shift->{FROM_JSHELL}            }

#===============================================================================
# IPC - listen
#===============================================================================
sub isRunning { shift->{running} == 1 }

sub _run {
    my $self = shift;
    my $file = shift;
    
    my @cmd = ($self->{_js},'-f', $self->{_path} . '/builtin.js');
    my $pid = open2($self->{FROM_JSHELL},$self->{TO_JSHELL}, @cmd);
    $self->{jshell_pid} = $pid;
    
    binmode $self->{TO_JSHELL},":utf8";
    binmode $self->{FROM_JSHELL},":crlf :utf8";
    
    ## set error handler
    $self->Set('jshell.onError' => sub {
        my $js = shift;
        my $args = shift;
        $self->{_ErrorHandle}->($js,$args->[0]);
    });
    
    return $self;
}
#===============================================================================
# Running Loop
#===============================================================================
sub run {
    my $self = shift;
    my $once = shift;
    
    return if $self->isRunning;
    $self->{running} = 1;
    
    if ($once){
        $self->call('jshell.endLoop');
    }
    
    my $WATCHER = $self->watcher;
    
    while(my $catch = <$WATCHER>){
        $self->processData($catch);
        last if !$self->isRunning;
    }
    return $self;
}

#===============================================================================
# run once is run twice actually - the second one to make sure there is no
# actions left
#===============================================================================
sub run_once {
    my $self = shift;
    $self->run(1);
    $self->run(1);
    return $self;
}

#===============================================================================
# handle errors
#===============================================================================
sub onError {
    my $self = shift;
    my $handle = shift;
    
    if (ref $handle ne 'CODE'){
        croak "onError method requires a code ref";
    }
    
    $self->{_ErrorHandle} = $handle;
    return $self;
}


#===============================================================================
# send code to shell
#===============================================================================
sub send {
    my $ret = {};
    my $self = shift;
    local $ret->{code} = shift;
    my $to = $self->{TO_JSHELL};
    print $to ($ret->{code} . "\n");
}

#===============================================================================
# set variable/object/function
#===============================================================================
sub Set {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $options = shift;
    my $ref = ref $value;
    if ($ref eq 'CODE'){
        $MethodsCounter++;
        $METHODS->{$MethodsCounter} = $value;
        $self->call('jshell.setFunction',$name,$MethodsCounter,$self->{context},$options);
    } else {
        $self->call('jshell.Set',$name,$value,$self->context);
    }
    return $self;
}

#===============================================================================
# get values
#===============================================================================
sub get {
    my $self = shift;
    my $value = shift;
    my $val = JavaScript::Shell::Result->new();
    $METHODS->{setValue} = sub {
        my $self = shift;
        my $args = shift;
        $val->add($args);
        return 1;
    };
    $self->call('jshell.getValue',$value,$self->context,@_);
    $self->run_once();
    return $val;
}


#==============================================================================
# Call Javascript Function
#==============================================================================
sub call {
    my $self = shift;
    my $fun = shift;
    my $args = \@_;
    my $send = {
        fn => $fun,
        args => $args,
        context => $self->context
    };
    
    $send = $self->toJson($send);
    $self->send('jshell.execFunc(' . $send . ')');
    $self->run_once();
}

#==============================================================================
# eval Script string
#==============================================================================
sub load {
    my $self = shift;
    my $file = shift;
    $file = File::Spec->canonpath( $file ) ;
    $file =~ s/\\/\\\\/g;
    $self->call('load' => $file);
}

sub eval {
    my $self = shift;
    my $code = shift;
    $self->call('jshell.evalCode',$code,$self->context);
    
}

sub datavar {
    my $self = shift;
    $self->{buffer} = \$_[0];
}

#===============================================================================
#  Process data from & to js shell
#===============================================================================
sub processData {
    my $self = shift;
    my $obj = $_[0];
    
    #convert recieved data from json to perl hash
    #then translate and process
    my $hash = {};
    my $ret = {};
    
    eval {
        $hash = $self->toObject($obj);
    };
    
    ##
    if ($@){
        
        #read until we get end of buffer;
        my $w = $self->watcher;
        
        $self->{buffer} = $obj;
        $self->{buffer} .= do {
            local $/ = "defdba7883bd47f7a043e0c9680d8b13";
            <$w>;
        };
        
        use bytes;
        my $len = bytes::length($self->{buffer}) - 33;
        $self->{buffer} = unpack "a$len", $self->{buffer};
        no bytes;
        return;
    }
    
    my $callMethod;
    
    local $ret->{args};
    if (my $method = $hash->{method}){
        if (my $sub = $METHODS->{$method}) {
            $callMethod = sub { $self->$sub(shift,shift) };
        } else {
            croak "can't locate method $method";
        }
        
        $ret->{args} = $callMethod->($hash->{args},$hash);
    }
    
    $self->{buffer} = '';
    if (ref $ret->{args} eq 'JavaScript::Shell::Buffer'){
        $hash->{_buffer} = $ret->{args}->{buff};
    } else {
        $hash->{_args} = $ret->{args};
    }
    
    $ret->{args} = $self->toJson($hash);
    $self->send("jshell.setArgs($ret->{args})");
    undef $ret;
    return 1;
}

sub buffer {
    my $self = shift;
    my $ret = {};
    $ret->{args} = shift;
    my $encoding = shift;
    return JavaScript::Shell::Buffer->new($ret->{args},$encoding);
}

sub getBuffer {
    my $self = shift;
    my $ret = {};
    local $ret->{ret} = $self->{buffer};
    ##buffer will get empty once consumed
    undef $self->{buffer};
    return $ret->{ret};
}

#===============================================================================
# destroy
#===============================================================================
sub destroy {
    my $self = shift;
    $self->call('quit');
}

sub DESTROY {
    my $self = shift;
    kill -9,$self->{jshell_pid} if $$ > 0;
}

#===============================================================================
# JavaScript::Shell::Result
#===============================================================================
package JavaScript::Shell::Result;

sub new {
    my $class = shift;
    return bless([],$class);
}

sub add {
    my $self = shift;
    my $values = shift;
    $self->[0] = $values;
}

sub value {
    my $self = shift;
    my $i = shift;
    return $i ? $self->[0]->[$i] : $self->[0];
}

#===============================================================================
# JavaScript::Shell::Context
#===============================================================================
package JavaScript::Shell::Context;
use base 'JavaScript::Shell';
no warnings 'redefine';
my $CONTEXT = 0;

sub new {
    my $class = shift;
    my $js = shift;
    my $sandbox = shift;
    $CONTEXT++;
    
    $js->call('jshell.setContext',$CONTEXT,$sandbox);
    
    my $args = {};
    
    %{$args} = %{$js};
    my $self = bless($args,$class);
    $self->{context} = $CONTEXT;
    return $self;
}


package JavaScript::Shell::Buffer;
use File::Temp qw/ tempfile tempdir /;

my $RET = {};
sub new {
    my $class = shift;
    local $RET->{str} = shift;
    my $encoding = shift || 'none';
    
    #create new temp file
    my ($fh, $filename) = tempfile();
    binmode $fh,":encoding(utf-8)";
    print $fh $RET->{str};
    close $fh;
    
    undef $RET->{str};
    return bless({
        buff => $filename
    },$class);
}

1;

=pod

=head1 NAME

JavaScript::Shell - Run Spidermonkey shell from Perl

=head1 SYNOPSIS

    use JavaScript::Shell;
    use strict;
    use warnings;
    
    my $js = JavaScript::Shell->new();
    
    ##create context
    my $ctx = $js->createContext();
    
    $ctx->Set('str' => 'Hello');
    
    $ctx->Set('getName' => sub {
        my $context = shift;
        my $args    = shift;
        my $firstname = $args->[0];
        my $lastname  = $args->[1];
        return $firstname . ' ' . $lastname;
    });
    
    $ctx->eval(qq!
        function message (){
            var name = getName.apply(this,arguments);
            var welcome_message = str;
            return welcome_message + ' ' + name;
        }
    !);
    
    
    my $val = $ctx->get('message' => 'Mamod', 'Mehyar')->value;
    
    print $val . "\n"; ## prints 'Hello Mamod Mehyar'
    
    $js->destroy();

=head1 DESCRIPTION

JavaScript::Shell will turn Spidermonkey shell to an interactive environment
by connecting it to perl

With JavaScript::Shell you can bind functions from perl and call them from
javascript or create functions in javascript then call them from perl

=head1 WHY

While I was working on a project where I needed to connect perl with javascript
I had a lot of problems with existing javascript modules, they were eaither hard
to compile or out of date, so I thought of this approach as an alternative.

Even though this sounds crazy to do, to my surprise it worked as expected - at
least in my usgae cases

=head1 SPEED

JavaScript::Shell connect spidermonkey with perl through IPC bridge using
L<IPC::Open2> so execution speed will never be as fast as using C/C++
bindings ported to perl directly

There is another over head when translating data types to/from perl, since it
converts perl data to JSON & javascript JSON to perl data back again.

Saying that, the over all speed is acceptable and you can take some steps to
improve speed like

=over 4

=item Data Transfer

Try to transfer small data chunks between processes when possible, sending
large data will be very slow

=item Buffer Data

As of version 0.02 JavaScript::shell has a new method for dealing with large
strings passed to/from javascript, use this feature when ever you want to send
large data "strings" -- see C<buffer>

=item Minimize calls

Minimize number of calls to both ends, let each part do it's processing.
for eaxmple:

    ##instead of
    
    $js->eval(qq!
        function East (){}
        function West (){}
        function North (){}
        function South (){}
    !);
    
    $js->call('East');
    $js->call('West');
    $js->call('North');
    $js->call('South');
    
    ##do this
    
    $js->eval(qq!
        function all () {
            
            East();
            West();
            North();
            South();
            
        }
        
        function East (){}
        function west (){}
        function North (){}
        function South (){}
        
    !);
    
    $js->call('all');

=back


=head1 CONTEXT

Once you intiate JavaScript::Shell you can create as many contexts
as you want, each context will has it's own scope and will not overlap
with other created contexts.

    my $js = JavaScript::Shell->new();
    my $ctx = $js->createContext();

You can pass a hash ref with simple data to C<createContext> method as a
sandbox object and will be copied to the context immediately

    my $ctx->createContext({
        Foo => 'Bar',
        Foo2 => 'Bar2'
    });

=head1 FUNCTIONS

=head2 new

Initiates SpiderMonkey Shell

=head2 createContext

creates a new context

=head2 run

This will run javascript code in a blocking loop until you call jshell.endLoop()
from your javascript code

    $js->Set('Name' => 'XXX');
    $js->eval(qq!
        for (var i = 0; i < 100; i++){
            
        }
        
        jshell.endLoop();
        
    !);
    
    $js->run();
    
    ##will never reach this point unless we call
    ## jshell.endLoop(); in javascript code as above
    

=head2 Set

Sets/Defines javascript variables, objects and functions from perl
    
    ## set variable 'str' with Hello vales
    $ctx->Set('str' => 'Hello');
    
    ## set 'arr' Array Object [1,2,3,4]
    $ctx->Set('arr' => [1,2,3,4]);
    
    ## set Associated Array Object
    $ctx->Set('obj' => {
        str1 => 'something',
        str2 => 'something ..'
    });
    
    ## set 'test' function
    ## caller will pass 2 arguments
    ## 1- context object
    ## 2- array ref of all passed arguments
    $ctx->Set('test' => sub {
        my $context = shift;
        my $args = shift;
        
        return $args->[0] . ' ' . $args->[1];
    });
    
    ## javascript object creation style
    
    $ctx->Set('obj' => {});
    
    #then
    $ctx->Set('obj.name' => 'XXX');
    $ctx->Set('obj.get' => sub { });
    ...

=head2 get

get values from javascript code, returns a C<JavaScript::Shell::Value> Object
    
    my $ret = $ctx->get('str');
    print $ret->value; ## Hello
    
    ## remember to call value to get the returned string/object
    
get method will search your context for a matched variable/object/function and
return it's value, if the name was detected for a function it will run this
function first and then returns it's return value
    
    $ctx->get('obj.name')->value; ## XXX
    
    ##you can pass variables when trying to get a function
    $ctx->get('test' => 'Hi','Bye')->value; ## Hi Bye
    
    ##get an evaled script values
    
    $ctx->get('eval' => qq!
        var n = 2;
        var x = 3;
        n+x;
    !)->value;  #--> 5
    
    
=head2 call

Calling javascript functions from perl, same as C<get> but doesn't return any
value

    $ctx->call('test');

=head2 eval

eval javascript code

    $ctx->eval(qq!
        
        //javascript code
        var n = 10;
        for(var i = 0; i<100; i++){
            n += 10;
        }
        ...
    !);
    
=head2 buffer

This function should be used only when dealing with passing large strings

    $js->Set('largeStr' => sub{
        
        my $js = shift;
        my $args = shift;
        
        ##we have a very large string we need to pass to
        ##javascript
        
        return $js->buffer('large string');
        
    });
    
    
    ##javascript
    var str = largeStr();
    

The same thing can be done when sending large strings from javascript to perl

    //javascript
    
    var str = 'very large string we need to pass to perl';
    jshell.sendBuffer(str);
    
    ##perl
    ##to consume this string from perl just get it
    my $str = $js->getBuffer();    
    
=head2 onError

set error handler method, this method accepts a code ref only. When an error
raised from javascript this code ref will be called with 2 arguments

=over 4

=item * JavaScript::Shell instance

=item * error object - Hash ref

=back

Error Hash has the folloing keys

=over 4

=item * B<message>  I<error message>

=item * B<type>     I<javascript error type: Error, TypeError, ReferenceError ..>

=item * B<file>     I<file name wich raised this error>

=item * B<line>     I<line number>

=item * B<stack>    I<string of the full stack trace>

=back

Setting error hnadler example

    my $js = JavaScript::Shell->new();
    $js->onError(sub{
        my $self = shift;
        my $error = shift;
        print STDERR $error->{message} . ' at ' . $error->{line}
        exit(0);
    });

=head2 destroy

Destroy javascript shell / clear context

    my $js = JavaScript::Shell->new();
    my $ctx->createContext();
    
    ##clear context;
    $ctx->destroy();
    
    ##close spidermonkey shell
    $js->destroy();

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 COPYRIGHTS

Copyright (C) 2013 by Mamod A. Mehyar <mamod.mehyar@gmail.com>

=cut

