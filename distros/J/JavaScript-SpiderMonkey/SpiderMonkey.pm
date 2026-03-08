######################################################################
package JavaScript::SpiderMonkey;
######################################################################
# Authors: Mike Schilli  m@perlmeister.com, 2002-2005
#          Thomas Busch  tbusch@cpan.org, 2006-2026
######################################################################

=head1 NAME

JavaScript::SpiderMonkey - Perl interface to the JavaScript Engine

=head1 SYNOPSIS

    use JavaScript::SpiderMonkey;

    my $js = JavaScript::SpiderMonkey->new();

    $js->init();  # Initialize engine

                  # Define a perl callback for a new JavaScript function
    $js->function_set("print_to_perl", sub { print "@_\n"; });

                  # Create a new (nested) object and a property
    $js->property_by_path("document.location.href");

                  # Execute some code
    my $rc = $js->eval(q!
        document.location.href = append("http://", "www.aol.com");

        print_to_perl("URL is ", document.location.href);

        function append(first, second) {
             return first + second;
        }
    !);

        # Get the value of a property set in JS
    my $url = $js->property_get("document.location.href");

    $js->destroy();

=head1 INSTALL

JavaScript::SpiderMonkey requires the mozjs60 (SpiderMonkey 60) library.
On RPM-based systems such as Rocky Linux, CentOS, or Fedora, install
the development package:

    sudo dnf install mozjs60-devel

Then build in the standard way:

    perl Makefile.PL
    make
    make test
    make install

The build system uses C<pkg-config> to locate the mozjs-60 headers and
libraries automatically.

=head1 DESCRIPTION

JavaScript::SpiderMonkey is a Perl interface to the Mozilla
SpiderMonkey JavaScript engine (mozjs60). It offers two levels of
access:

=over 4

=item [1]

A 1:1 mapping of the SpiderMonkey API to Perl

=item [2]

A more Perl-like API

=back

This document describes [2], for [1], please check C<SpiderMonkey.xs>.

=cut

use 5.006;
use strict;
use warnings;
use bytes ();


require Exporter;
require DynaLoader;

our $VERSION     = '0.27';
our @ISA         = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

bootstrap JavaScript::SpiderMonkey $VERSION;

our $GLOBAL;

##################################################

=head2 new()

C<$js = JavaScript::SpiderMonkey-E<gt>new()> creates a new object to work with.
To initialize the JS engine, call C<$js-E<gt>init()> afterwards.

=cut

##################################################
sub new {
##################################################
    my ($class) = @_;

    my $self = {
        'context'       => undef,
        'global_object' => undef,
        'global_class'  => undef,
        'objects'       => { },
               };

        # The function dispatcher is called from C and
        # doesn't have 'self'. Store it in a class var.
        # This means we can only have one instance of this
        # JavaScript::SpiderMonkey object. Ouch.
    our $GLOBAL = $self;

    bless $self, $class;
}

##################################################

=head2 $js-E<gt>destroy()

C<$js-E<gt>destroy()> destroys the current JS context and frees up all
associated memory. This is called automatically when the object goes out
of scope, but can be called explicitly if desired.

=cut

##################################################
sub destroy {
##################################################
    my ($self) = @_;
    if ($self->{context}) {
        JavaScript::SpiderMonkey::JS_DestroyContext($self->{context});
        $self->{context} = undef;
    }
    $self->{global_object} = undef;
    $self->{global_class}  = undef;
    $self->{objects}       = {};
    $self->{functions}     = {};
    $self->{properties}    = {};
}

##################################################
sub DESTROY {
##################################################
    my ($self) = @_;
    $self->destroy() if $self->{context};
}

##################################################

=head2 $js-E<gt>init()

C<$js-E<gt>init()> initializes the SpiderMonkey engine by creating a JS
context, the global object, standard classes, and an error reporter.

B<Note:> mozjs60 supports only one active JS context at a time. Calling
C<init()> on a new object will automatically destroy any previously
active context.

=cut

##################################################
sub init {
##################################################
    my ($self) = @_;

    $self->{context} =
        JavaScript::SpiderMonkey::JS_Init(1000000);
    $self->{global_class} =
        JavaScript::SpiderMonkey::JS_GlobalClass();
    $self->{global_object} =
        JavaScript::SpiderMonkey::JS_NewGlobalObject(
            $self->{context}, $self->{global_class});

    JavaScript::SpiderMonkey::JS_InitStandardClasses($self->{context},
                                                     $self->{global_object});
    JavaScript::SpiderMonkey::JS_SetErrorReporter($self->{context});
}

##################################################

=head2 $js-E<gt>array_by_path($name)

Creates an object of type I<Array>
in the JS engine:

    $js->array_by_path("document.form");

will first create an object with the name C<document> (unless
it exists already) and then define a property named C<form> to it,
which is an object of type I<Array>. Therefore, in the JS code,
you're going to be able define things like

    document.form[0] = "value";

=cut

##################################################
sub array_by_path {
##################################################
    my ($self, $path) = @_;

    my $array = JavaScript::SpiderMonkey::JS_NewArrayObject($self->{context});
    return $self->object_by_path($path, $array);
}

##################################################

=head2 $js-E<gt>function_set($name, $funcref, [$obj])

Binds a Perl function provided as a coderef (C<$funcref>) 
to a newly created JS function
named C<$name> in JS land. 
It's a real function (therefore bound to the global object) if C<$obj>
is omitted. However, if C<$obj> is ref to
a JS object (retrieved via C<$js-E<gt>object_by_path($path)> or the like),
the function will be a I<method> of the specified object.

    $js->function_set("write", sub { print @_ });
        # write("hello"); // In JS land

    $obj = $j->object_by_path("navigator");
    $js->function_set("write", sub { print @_ }, $obj);
        # navigator.write("hello"); // In JS land

=cut

##################################################
sub function_set {
##################################################
    my ($self, $name, $func, $obj) = @_;

    $obj ||= $self->{global_object}; # Defaults to global object

    $self->{functions}->{${$obj}}->{$name} = $func;

    return JavaScript::SpiderMonkey::JS_DefineFunction(
        $self->{context}, $obj, $name, 0, 0);
}

##################################################
sub function_dispatcher {
##################################################
    my ($obj, $name, @args) = @_;

    our $GLOBAL;

       ## Find the path for this object.
       my $found = 0;
       foreach( keys( %{$GLOBAL->{objects}} ) ){
           if( ${$GLOBAL->{objects}->{$_}} eq $obj &&
                   exists( $GLOBAL->{functions}->{$obj}->{$name}  ) ){
                   $found = 1;
               }
       }
       $obj = ${$GLOBAL->{global_object}} unless $found;

    if(! exists $GLOBAL->{functions}->{$obj}->{$name}) {
        die "Dispatcher: Can't find mapping for function $obj" .
            ${$GLOBAL->{global_object}} . " '$name'";
    }

    return $GLOBAL->{functions}->{$obj}->{$name}->(@args);
}

##################################################
sub getsetter_dispatcher {
##################################################
    my ($obj, $propname, $what, $value) = @_;

    our $GLOBAL;

    if(exists $GLOBAL->{properties}->{$obj}->{$propname}->{$what}) {
        my $entry = $GLOBAL->{properties}->{$obj}->{$propname}->{$what};
        my $path = $entry->{path};
        $entry->{callback}->($path, $value);
    }
}

##################################################

=head2 $js-E<gt>array_set_element($obj, $idx, $val)

Sets the element of the array C<$obj>
at index position C<$idx> to the value C<$val>.
C<$obj> is a reference to an object of type array
(retrieved via C<$js-E<gt>object_by_path($path)> or the like).

=cut

##################################################
sub array_set_element {
##################################################
    my ($self, $obj, $idx, $val) = @_;

    JavaScript::SpiderMonkey::JS_SetElement(
                    $self->{context}, $obj, $idx, $val);
}

##################################################

=head2 $js-E<gt>array_set_element_as_object($obj, $idx, $elobj)

Sets the element of the array C<$obj>
at index position C<$idx> to the object C<$elobj>
(both C<$obj> and C<$elobj> have been retrieved 
via C<$js-E<gt>object_by_path($path)> or the like).

=cut

##################################################
sub array_set_element_as_object {
##################################################
    my ($self, $obj, $idx, $elobj) = @_;

    JavaScript::SpiderMonkey::JS_SetElementAsObject(
                    $self->{context}, $obj, $idx, $elobj);
}

##################################################

=head2 $js-E<gt>array_get_element($obj, $idx)

Gets the value of of the element at index C<$idx>
of the object of type Array C<$obj>.

=cut

##################################################
sub array_get_element {
##################################################
    my ($self, $obj, $idx) = @_;

    return JavaScript::SpiderMonkey::JS_GetElement(
                    $self->{context}, $obj, $idx);
}

##################################################

=head2 $js-E<gt>property_by_path($path, $value, [$getter], [$setter])

Sets the specified property of an object in C<$path> to the 
value C<$value>. C<$path> is the full name of the property,
including the object(s) in JS land it belongs to:

    $js-E<gt>property_by_path("document.location.href", "abc");

This first creates the object C<document> (if it doesn't exist already),
then the object C<document.location>, then attaches the property
C<href> to it and sets it to C<"abc">.

C<$getter> and C<$setter> are coderefs that will be called by 
the JavaScript engine when the respective property's value is
requested or set:

    sub getter {
        my($property_path, $value) = @_;
        print "$property_path has value $value\n";
    }

    sub setter {
        my($property_path, $value) = @_;
        print "$property_path set to value $value\n";
    }

    $js->property_by_path("document.location.href", "abc",
                              \&getter, \&setter);

If you leave out C<$getter> and C<$setter>, no callbacks are going to
be triggered while the property is set or queried.  If you just want
to specify a C<$setter>, but no C<$getter>, set the C<$getter> to
C<undef>.

=cut

##################################################
sub property_by_path {
##################################################
    my ($self, $path, $value, $getter, $setter) = @_;

    (my $opath = $path) =~ s/\.[^.]+$//;
    my $obj = $self->object_by_path($opath);
    unless(defined $obj) {
        warn "No object pointer found to $opath";
        return undef;
    }

    $value = 'undef' unless defined $value;

    (my $property = $path) =~ s/.*\.//;

    my $prop;
    if ($getter || $setter) {
        $prop = JavaScript::SpiderMonkey::JS_DefinePropertyWithAccessors(
            $self->{context}, $obj, $property, $value);
    } else {
        $prop = JavaScript::SpiderMonkey::JS_DefineProperty(
            $self->{context}, $obj, $property, $value);
    }

    if($getter) {
            # Store it under the original C pointer's value. We get
            # back a PTRREF from JS_DefineObject, but we need the
            # original value for the callback dispatcher.
        $self->{properties}->{$$obj}->{$property}->{getter}->{callback} 
            = $getter;
        $self->{properties}->{$$obj}->{$property}->{getter}->{path} = $path;
    }

    if($setter) {
        $self->{properties}->{$$obj}->{$property}->{setter}->{callback} 
            = $setter;
        $self->{properties}->{$$obj}->{$property}->{setter}->{path} = $path;
    }

    return $prop;
}

##################################################

=head2 $js-E<gt>object_by_path($path, [$newobj])

Get a pointer to an object with the path
specified. Create it if it's not there yet.
If C<$newobj> is provided, the ref is used to 
bind the existing object to the name in C<$path>.

=cut

##################################################
sub object_by_path {
##################################################
    my ($self, $path, $newobj) = @_;

    my $obj = $self->{global_object};

    my @parts = split /\./, $path;
    my $full  = "";

    return undef unless @parts;

    while(@parts >= 1) {
        my $part = shift @parts;
        $full .= "." if $full;
        $full .= "$part";

        if(exists $self->{objects}->{$full}) {
            $obj = $self->{objects}->{$full};
        } else {
            my $gobj = $self->{global_object};
            if(defined $newobj and $path eq $full) {
                $obj = JavaScript::SpiderMonkey::JS_DefineObject(
                       $self->{context}, $obj, $part,
                       JavaScript::SpiderMonkey::JS_GetClass($newobj),
                       $newobj);
            } else {
                $obj = JavaScript::SpiderMonkey::JS_DefineObject(
                       $self->{context}, $obj, $part, 
                       $self->{global_class}, $self->{global_object});
            }
            $self->{objects}->{$full} = $obj;
        }
    }

    return $obj;
}

##################################################

=head2 $js-E<gt>property_get($path)

Fetch the property specified by the C<$path>.

    my $val = $js->property_get("document.location.href");

=cut

##################################################
sub property_get {
##################################################
    my ($self, $string) = @_;

    my($path, $property) = ($string =~ /(.*)\.([^\.]+)$/);

    if(!exists $self->{objects}->{$path}) {
        warn "Cannot find object $path via SpiderMonkey";
        return;
    }

    return JavaScript::SpiderMonkey::JS_GetProperty(
        $self->{context}, $self->{objects}->{$path}, 
        $property);
}

##################################################

=head2 $js-E<gt>eval($code)

Runs the specified piece of <$code> in the JS engine.
Afterwards, property values of objects previously defined 
will be available via C<$j-E<gt>property_get($path)>
and the like.

    my $rc = $js->eval("write('hello');");

The method returns C<1> on success or C<undef> if there was an error
in JS land. In case of an error, the error text will be available in
C<$@>.

=cut

##################################################
sub eval {
##################################################
    my ($self, $script) = @_;

    return 1 unless defined $script;

    my $ok = 
        JavaScript::SpiderMonkey::JS_EvaluateScript(
            $self->{context},
            $self->{global_object},
            $script, 
            $] > 5.007 ? bytes::length($script) : length($script),
            "Perl",
# Fixed the line number bug:
# https://rt.cpan.org/Public/Bug/Display.html?id=57572
# BKB 2010-05-24 10:06:57
            1);

    return $ok;
}

##################################################

=head2 $js-E<gt>set_max_branch_operations($max_branch_operations)

Set the maximum number of allowed branch operations. This protects
against infinite loops and guarantees that the eval operation
will terminate.

=cut
##################################################
sub set_max_branch_operations {
##################################################
    my ($self, $max_branch_operations) = @_;
    JavaScript::SpiderMonkey::JS_SetMaxBranchOperations($self->{context}, $max_branch_operations);
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item *

B<Single instance only.> mozjs60 supports only one active JS context at
a time. You may create multiple C<JavaScript::SpiderMonkey> objects, but
calling C<init()> on a new one will automatically destroy the previous
context. Design your application around a single active instance.

=item *

B<Not thread-safe.> The module uses global state internally (function
and property dispatch tables) and should only be used from a single
thread.

=back

=head1 AUTHORS

  Mike Schilli, <m at perlmeister dot com>
  Thomas Busch, <tbusch at cpan dot org> (current maintainer)

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2002-2005 Mike Schilli
  Copyright (c) 2006-2026 Thomas Busch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
