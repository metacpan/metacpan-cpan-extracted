package JavaScript::Writer;

use warnings;
use strict;

use 5.008;
use self;

use overload
    '<<' => sub {
        no warnings;
        push @{ self->{statements} }, { code => args };
        return self;
    },
    '""' => \&as_string;

use JSON::Syck;

our $VERSION = '0.3.1';

use Sub::Exporter -setup => {
    exports => ['js'],
    groups  => {
        default =>  [ -all ],
    }
};

my $base;

sub _js {
    # Return the top-most $_[0] JavaScript::Writer object in stack.
    my $level = 2;
    my @c = ();
    my $js;
    while ( $level < 10 && (!defined($c[3]) || $c[3] eq '(eval)') ) {
        @c = do {
            package DB;
            @DB::args = ();
            caller($level);
        };
        $level++;

        if (ref($DB::args[0]) eq 'JavaScript::Writer') {
            $js = $DB::args[0] ;
            last;
        }
    }
    return $js;
}

sub js {
    my $js = _js();

    my ($obj) = @_;
    if (defined $js) {
        $js->{object} = $obj if defined $obj;
        return $js;
    }

    $base = JavaScript::Writer->new() unless defined $base;
    $base->{object} = $obj if defined $obj;
    return $base;
}

sub new {
    if (ref(self)) {
        if (defined $base) {
            self->{statements} = [];
            return self;
        }
        return __PACKAGE__->new;
    }

    $self = bless { args }, $self;
    $self->{statements} = [];
    return $self;
}

sub call {
    my ($function, @function_args) = @args;
    my $eoc = !defined wantarray;
    push @{self->{statements}},{
        object => delete self->{object} || undef,
        call => $function,
        args => \@function_args,
        end_of_call_chain => $eoc
    };
    return self;
}

sub __in_jsw_packages__ {
    my $level = 0;
    my @c = caller(++$level);
    while ( @c > 0 ) {
        return 1 if defined $c[0] && index($c[0], __PACKAGE__) == 0;
        @c = caller(++$level);
    }
    return 0;
}

sub append {
    if ( __in_jsw_packages__ ) {
        push @{ self->{statements} }, { code => args };
        return self;
    }

    return self->call("append", args);
}

sub object {
    self->{object} = args[0];
    return self;
}

sub latter {
    my ($cb) = args;

    my $timeout = delete self->{object};
    $timeout =~ s/ms$//;
    $timeout =~ s/s$/000/;

    my $jsf = JavaScript::Writer::Function->new;
    $jsf->body($cb);

    self->append("setTimeout($jsf, $timeout)");
    return self;
}

use JavaScript::Writer::Var;

sub let {
    my %vars = args;
    my $code = "";
    while (my ($var, $value) = each %vars) {
        self->var($var, $value);
    }
    return self;
}

sub var {
    my ($var, $value) = @args;
    my $s = "";

    if (!defined $value) {
        $s = "var $var;";
    }
    elsif (ref($value) eq 'ARRAY' || ref($value) eq 'HASH' || !ref($value) ) {
        $s = "var $var = " . $self->obj_as_string($value) . ";"
    }
    elsif (ref($value) eq 'CODE') {
        $s = "var $var = " . $self->function($value);
    }
    elsif (ref($value) =~ /^JavaScript::Writer/) {
        $s = "var $var = " . $value->as_string();
    }
    elsif (ref($value) eq 'REF') {
        my $j = $self->new;
        $j->var($var => $$value);
        $s = $j->as_string;
    }
    elsif (ref($value) eq 'SCALAR') {
        if (defined $$value) {
            my $v = $self->obj_as_string($value);

            $s = "var $var = $v;";
        }
        else {
            $s = "var $var;";
        }

        eval {
            JavaScript::Writer::Var->new(
                $value,
                {
                    name => $var,
                    jsw  => $self
                }
            );
        };

    }

    $self->append($s);
    return $self;
}

use JavaScript::Writer::Block;

sub do {
    my ($block) = args;
    my $condition = delete self->{object};
    my $b = JavaScript::Writer::Block->new;
    $b->body($block);
    self->append("if($condition)${b}", delimiter => "" );
}

sub while {
    my ($condition, $block) = @args;
    my $b = JavaScript::Writer::Block->new;
    $b->body($block);
    $self->append("while(${condition})${b}", , delimiter => "" );
}

use JavaScript::Writer::Function;

sub function {
    return JavaScript::Writer::Function->new(args);
}

sub obj_as_string {
    my ($obj) = @args;

    if (ref($obj) eq 'CODE') {
        return self->function($obj);
    }
    elsif (ref($obj) =~ /^JavaScript::Writer/) {
        return $obj->as_string
    }
    elsif (ref($obj) eq "SCALAR") {
        return $$obj
    }
    elsif (ref($obj) eq 'ARRAY') {
        my @ret = map {
            self->obj_as_string($_)
        } @$obj;

        return "[" . join(",", @ret) . "]";
    }
    elsif (ref($obj) eq 'HASH') {
        my %ret;
        while (my ($k, $v) = each %$obj) {
            $ret{$k} = self->obj_as_string($v)
        }
        return "{" . join (",", map { JSON::Syck::Dump($_) . ":" . $ret{$_} } sort keys %ret) . "}";
    }
    else {
        return JSON::Syck::Dump($obj)
    }
}

sub as_string {
    my $ret = "";

    for (@{self->{statements}}) {
        my $delimiter =
            defined($_->{delimiter}) ? $_->{delimiter} : ($_->{end_of_call_chain} ? ";" : ".");
        if (my $f = $_->{call}) {

            my $args = $_->{args};
            $ret .= ($_->{object} ? "$_->{object}." : "" ) .
                "$f(" .
                    join(",",
                         map {
                             self->obj_as_string( $_ );
                         } @$args
                     ) . ")" . $delimiter
        }
        elsif (my $c = $_->{code}) {
            $delimiter = defined $_->{delimiter}  ? $_->{delimiter} : ";";
            $c .= $delimiter unless $c =~ /$delimiter\s*$/s;
            $ret .= $c;
        }
    }
    return $ret;
}

require JavaScript::Writer::BasicHelpers;

{
    my $sn = 0;
    sub as_html {
        my (%param) = @args;
        $sn++;

        my $id = "javascript-writer-$$-$sn";

        if ($param{closure}) {
            my $j = JavaScript::Writer->new;
            my $self_code = $self->as_string;
            $j->closure(
                this => \ "document.getElementById('$id')",
                body => sub {
                    js->append( $self_code );
                }
            );
            return qq{<script id="$id" type="text/javascript">$j</script>}
        }
        return qq{<script type="text/javascript">$self</script>};
    }
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $function = $AUTOLOAD;
    $function =~ s/.*:://;

    return self->call($function, args);
}

1; # Magic true value required at end of module

__END__

=head1 NAME

JavaScript::Writer - JavaScript code generation from Perl.

=head1 SYNOPSIS

    use JavaScript::Writer;

    # Call alert("Nihao").
    js->call("alert", "Nihao");

    # Similar, but display Perl-localized message of "Nihao".
    js->call("alert", _("Nihao") );

    # Output
    js->as_string

=head1 DESCRIPTION

As you can see, this module is trying to simulate what RJS does. It's
meant to be used in some web app framework, or for those who are
generate javascript code from perl data.

It requires you loaded several javascript librarys in advance, then
use its C<call> method to call a certain functions from your library.

=head1 INTERFACE

=over

=item js( [ $object ] )

This function is exported by default to your namespace. Is the spiffy
ultimate entry point for generating all kinds of javascripts.

C<js> represents a singleton object of all namespace. Unless used in a
subroutine passed to construct a JavaScript function, it always refers
to the same C<JavaScript::Writer> object.

It optionally takes a C<$object> parameter that represents something
on which you can perform some action. For example, here's the sweet
way to do C<setTimeout>:

    js("3s")->latter(sub{
        js->say('something');
    });

Or usually it can just be a normal object:

    js("Widget.Lightbox")->show( $content );

    # Widget.Lightbox.show( ... )

=item new()

Object constructor. Takes nothing, gives you an javascript writer
object. It can be called as a class method, or an object method.
Calling it on objects does not imply cloning the original object, but
just a shorthand to construct a new one. Typing package name is always
longer.

One special usage is to say:

    js->new;

This just flush the stored statements in the C<js> object, without
creating a new object.

=item call( $function, $arg1, $arg2, $arg3, ...)

Call an javascript function with arguments. Arguments are given in
perl's native form, you don't need to use L<JSON> module to serialized
it first.  (Unless, of course, that's your purpose: to get a JSON
string in JavaScript.)

=item var( $name, [ $value ] )

Declare a value named $name with a optional default value $value.
$value could be an arrayref, hashref, or scalar.


=item var( $name, \$your_var )

Another form of calling var. Please notice that the second argument
must be a scalar reference.

This let you tie a Perl scalar into a javascript variable. Further
assignments on that Perl scalar will directly effect the output of your
javasciprt writer objcet. For example:

    my $a;
    my $js = JavaScript::Writer->new;
    $js->var(ans => \$a);
    $a = 42;

    print $js->as_string;
    # "var a;a = 42;"

Or something like this;

    my $js = JavaScript::Writer->new;
    my $a;
    $js->var(ans => \$a);

    my $a = $js->new->myAjaxGet("/my/foo.json");
    print $js->as_string;
    # var a;a = myAjaxGet("/my/foo.json");

=item let( var1 => value1, var2 => value2, ... )

This let you assign multiple variables at once.

=item latter($timeout, sub { ... } )

This is another way saying setTimeout(sub { ... }, $timeout). With
C<js()> funciton, you can now say:

    js("3s")->latter(sub { ... });

And that gets turned into

    setTimeout(function(){...}, 3000);

You can use "ms" and "s" as the time unit, they means millisecond and
seconds respectively. Number with any units means milliseconds by
default.

More complex time representation like C<"3h5m2s">, are not implement
yet.

=item object( $object )

Give the object name for next function call. The preferred usage is:

    $js->object("Widget.Lightbox")->show("Nihao")

Which will then generated this javascript code snippet:

    Widget.Lightbox.show("Nihao")

=item while( $condition => $code_ref )

C<$condition> is a string (yes, just a string for now) of javascript
code, and a $code_ref is used to generate the block required for this
while block.

The output of 'while' statement look like this:

    while($condition) {
        $code
    }

=item do ( $code_ref )

C<do> method acts like C<if>:

    js("foo")->do(sub {
      ....
    });

That code generate this javascript:

    if(foo) {
        ....
    }

NOTICE: The old if-else-elsif methods are removed due to their stupid looking design.

=item function( $code_ref )

This is a javascript function writer. It'll output something like this:

    function(){...}

The passed $code_ref is a callback to generate the function
body. It'll be passed in a JavaScript::Writer object so you can use it
to write more javascript statements. Here defines a function that
simply slauts to you.

    my $js = JavaScript::Writer->new;
    my $f = $js->function(sub {
        my $js = shift;
        $js->alert("Nihao")
    })

The returned $f is a L<JavaScript::Writer::Function> object that
stringify to this string:

    function(){alert("Nihao")}

=item closure(&block)

Generate a closure with body &block. This means to generate a
construct like this:

    ;(function(){
        // ...
    })();

It's very useful for doing functional programming in javascript.

=item closure(arguments => { name => value }, body => sub {... }, ...)

Another form of the closure function. For example:

  js->closure(
      parameters => {
          el => "document.getElementById('foo')",
          var1 => "var1",
          var2 => \ "var 2 value"
      },
      body => sub {
          ...
      }
  );

This generates something like this:

    ;(function(el, var1, var2){
        ...
    })(document.getElementById('foo'), var1, "var 2 value");

The value to the key "parameters" is a hashref, which means the order
of function arguments is not guarenteed. But that shouldn't matter at
all because they are all named. They have to be named anyway.

The value to the key "this" refers to te value of "this" variable in
the closure. For example:

  js->closure(
      this => "el",
      parameters => { msg => \ "Hello, World" }
      body => sub {
        js->jQuery("this")->html("msg");
      }
  );

This generates

    ;(function(msg){
        jQuery(this).html(msg);
    }).call(el, "Hello, World");

=item delay($n, &block)

Generate a piece of code that delays the execution of &block for $n
seconds.

=item as_string()

Output your statements as a snippet of javascript code.

=item obj_as_string()

This is use internally as a wrapper to JSON::Syck::Dump sub-routine,
in order to allow functions to be dumped as a part of javascript
object.

=item as_html()

Output your javascript statements as a snippet with a <script> tag.

=item append( $statement )

[NOTICE]: This function behaves differently depends when it's called
outside JavaScript::Writer.

Internally it manually append a statement string. Caller needs to
properly serialize everything to JSON, and make sure that $statement
has no syntax error.

If it's called from outside of JavaScript::Writer packages, it'll
render a function call to "append" function.

=back

=head1 CONFIGURATION AND ENVIRONMENT

JavaScript::Writer requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Class::Accessor::Fast>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-javascript-writer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007,2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
