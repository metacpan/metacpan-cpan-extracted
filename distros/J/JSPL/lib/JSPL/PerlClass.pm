package JSPL::PerlClass;
use strict;
use warnings;

use Carp;
JSPL::_boot_(__PACKAGE__);

our %ClassStore = ();

*_resolve_method = \&JSPL::Context::_resolve_method;

sub _extract_methods {
    my ($args, @arg_keys) = @_;

    my $method = {};

    for my $arg (@arg_keys) {
        if (exists $args->{$arg} && defined $args->{$arg}) {
            my $arg = $args->{$arg};
            
            if (ref $arg eq 'HASH') {
                for my $name (keys %$arg) {
                    $method->{$name} = _resolve_method($arg->{$name}, 1);
                }
            }
            elsif(ref $arg eq 'ARRAY') {
                for my $name (@$arg) {
                    $method->{$name} = _resolve_method($name, 1);
                }
            }
            else {
                my @methods = split /\s+/, $arg;
                for my $name (@methods) {
                    $method->{$name} = _resolve_method($name, 1);
                }
            }
        }
    }

    return $method;
}

sub _extract_properties {
    my ($args, @arg_keys) = @_;

    my $property = {};

    for my $arg (@arg_keys) {
        if (exists $args->{$arg} && defined $args->{$arg}) {
            my $arg = $args->{$arg};

            if (ref $arg eq 'HASH') {
                for my $name (keys %{$arg}) {
                    if (ref $arg->{$name} eq 'HASH') {
                        my $getter = _resolve_method($arg->{$name}->{getter}, 1);
                        my $setter = _resolve_method($arg->{$name}->{setter}, 1);
                        $property->{$name} = [ $getter, $setter ];
                    }
                    elsif (ref $arg->{$name} eq 'ARRAY') {
                        my @callbacks = @{$arg->{$name}};
                        my $getter = _resolve_method(shift @callbacks, 1);
                        my $setter = _resolve_method(shift @callbacks, 1);
                        $property->{$name} = [ $getter, $setter ];
                    }
                    elsif (ref $arg->{$name} eq '') {
                        my $getter = sub {
                            return $_[0]->{$name};
                        };

                        my $setter = !($arg->{$name} & JSPL::JS_PROP_READONLY) ? sub {
                            $_[0]->{$name} = $_[1];
                        } :  undef;

                        $property->{$name} = [ $getter, $setter ];
                    }
                }
            }
            elsif (ref $arg eq 'ARRAY') {
                
            }
            else {
                my @properties = split /\s+/, $arg;
                for my $name (@properties) {
                }
            }
        }
    }

    return $property;
}

sub new {
    shift; # Class method
    my %args = @_;
    
    # Check if name argument is valid
    die "Missing argument 'name'\n" unless(exists $args{name});
    die "Argument 'name' must match /^[A-Za-z0-9_]+\$/" unless($args{name} =~ /^[A-Za-z0-9\_]+$/);
    
    # Check if constructor is supplied and it's an coderef
    my $cons; 
    $cons = _resolve_method($args{constructor}, 1) if exists $args{constructor};
    
    if (exists $args{flags}) {
        die "Argument 'flags' is not numeric\n" unless($args{flags} =~ /^\d+$/);
    } else {
        $args{flags} = 0;
    }
    
    unless (exists $args{package}) {
        $args{package} = undef;
    }
    
    my $name = $args{name};
    my $pkg = $args{package} || $name;
    
    # Create a default constructor
    if (!defined $cons) {
        $cons = sub {
            $pkg->new(@_);
        };
    }
    
    # Per-object methods
    my $fs = _extract_methods(\%args, qw(methods fs));

    # Per-class methods
    my $static_fs = _extract_methods(\%args, qw(static_methods static_fs));

    # Per-object properties
    my $ps = _extract_properties(\%args, qw(properties ps));

    # Per-class properties
    my $static_ps = _extract_properties(\%args, qw(static_properties static_ps));

    # Flags
    my $flags = $args{flags};
    
    return create_class($name, $pkg, $cons, $fs, $static_fs, $ps, $static_ps, $flags);
}

1;

__END__

=head1 NAME

JSPL::PerlClass - Create native JavaScript classes in Perl

=head1 INTRODUCTION

If you known what a "native class" is you can jump to L</INTERFACE> now. If
not, let me introduce you to a few important concepts that you need to
understand well if you think that you need the services provided by
JSPL::PerlClass.

JavaScript, the language, doesn't really have I<classes>. It is a I<prototype
based object oriented> language. When somebody talks about a "class", they are
normally talking about a function that is meant to be called as a constructor,
using the C<new> operator.

The result of calling a constructor is a new object. This new object inherits
the I<prototype> property of the constructor as the head of its I<prototype
chain>. This way the new object "inherits" all properties and methods of its
creator's I<prototype>. All objects sharing the same I<prototype chain> can be
said to form a "class".

The SpiderMonkey engine uses the concept of I<native class> to refer to the
mechanism which you can use to install hooks into the normal processing of
JavaScript object operations.

=head1 INTERFACE

=head2 Constructor

=over 4 

=item new ( %args )

Create a new native JavaScript class.

It expects the following arguments

=over 4

=item name

The name of the class in javascript.

  name => "MyPackage",

=item constructor

A reference to a subroutine that returns the Perl object that represents the
javascript object. If omitted a default constructor will be supplied that calls
the method C<new> on the defined I<package> (or I<name> if no package is
defined).

  constructor => sub { MyPackage->new(@_); },

=item package

The name of the Perl package that represents this class. It will be passed as
first argument to any class methods and also used in the default constructor.

  package => "My::Package",

=item methods (fs)

A hash reference of methods that we define for instances of the class. In
javascript this would be C<o = new MyClass(); o.method()>.

The key is used as the name of the function and the value should be either a
reference to a subroutine or the name of the Perl subroutine to call.

  methods => { to_string => \&My::Package::to_string,
               random    => "randomize"
  }

=item static_methods (static_ps)

Like I<fs> but these are called on the class itself. In javascript this would
be C<MyClass.method()>.

=item properties (ps)

A hash reference of properties that we define for instances of the class. In
javascript this would be C<o = new MyClass(); f = o.property;>

The key is used as the name of the property and the value is used to specify
what method to call as a get-operation and as a set-operation.  These can
either be specified using references to subroutines or name of subroutines.  If
the getter is undefined the property will be write-only and if the setter is
undefined the property will be read-only.  You can specify the getter/setter
using either an array reference, C<[\&MyClass::get_property,
\&MyClass::set_property]>, a string, C<"MyClass::set_property
MyClass::get_property"> or a hash reference, C<{ getter =>
"MyClass::get_property", setter => "MyClass::set_property" }>.

  ps => { length => [qw(get_length)],
          parent => { getter => \&MyClass::get_parent, setter => \&MyClass::set_parent },
        }

=item static_properties (static_ps)

Like I<ps> but these are defined on the class itself. In javascript this would
be C<f = MyClass.property>.

=item flags

A bitmask of attributes for the class. Valid attributes are:

=over 4

=item JS_CLASS_NO_INSTANCE

Makes the class throw an exception if JavaScript tries to instantiate the
class.

=back

=back

=begin PRIVATE

=head1 Private Interface

=over 4

=item create_class (char *name, SV *constructor, SV *methods, SV *properties, SV *package, SV *flags )

Low level constructor

=item bind

Install a JSPL::PerlClass in a context

=back

=cut
