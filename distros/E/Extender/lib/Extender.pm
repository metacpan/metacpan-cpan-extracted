#!/usr/bin/perl
################################################################################
#
#   Extender - Reference-Scalar-Object method Extender.
#
#   (C) 2024 OnEhIppY - Domero Software
#
################################################################################
package Extender;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '1.01';
our @EXPORT = qw(Extend Extends GlobExtends Alias AddMethod Decorate ApplyRole InitHook Unload);

################################################################################
=pod

=encoding UTF-8

=head1 NAME

Extender - Dynamically enhance Perl objects with additional methods from other modules or custom subroutines

=head1 SYNOPSIS

    ############################################################################

    use Extender;

    # Example: Extend an object with methods from a module
    my $object = MyClass->new();
    Extend($object, 'Some::Class');
    $object->method_from_some_class();

    # Example: Extend an object with custom methods
    Extends($object,
        greet => sub { my ($self, $name) = @_; print "Hello, $name!\n"; },
        custom_method => sub { return "Custom method executed"; },
    );
    $object->greet('Alice');
    $object->custom_method();

    ############################################################################

=head1 DESCRIPTION

Extender is a Perl module that facilitates the dynamic extension of objects with methods from other modules or custom-defined subroutines. It allows you to enhance Perl objects - whether hash references, array references, or scalar references - with additional functionalities without altering their original definitions.

=head1 EXPORTED FUNCTIONS

=cut

################################################################################

=head2 Extend($object, $module, @methods)

Extends an object with methods from a specified module.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference to which methods will be added.

=item * C<$module> - The name of the module from which methods will be imported.

=item * C<@methods> - Optional list of method names to import. If none are provided, all exported functions from C<$module> will be imported.

=back

=head3 Description:

This function extends the specified C<$object> by importing methods from the module C<$module>. It dynamically loads the module if it's not already loaded, retrieves the list of exported functions, and adds each specified function as a method to the object.

=head3 Example:

    ############################################################################

    use Extender;

    # Create an object and extend $object with methods from 'Hash::Util'
    my $object = Extend({}, 'Hash::Util', 'keys', 'values');

    # Now $object has 'keys' and 'values' methods from 'Hash::Util'

    ############################################################################

=head3 Supported Object Types: Can be applied to HASH, ARRAY, SCALAR, GLOB references, or a complete class object. For example:

    my $hash_ref = Extend({}, 'HashMethods', 'method1', 'method2');
    my $array_ref = Extend([], 'ArrayMethods', 'method1', 'method2');
    my $scalar_ref = Extend(\(my $scalar = 'value'), 'ScalarMethods', 'method1');
    my $glob_ref = Extend(\*GLOB, 'GlobMethods', 'method1');
    my $class_ref = Extend(MyClass->new(), 'ClassMethods', 'method1');

=cut

sub Extend {
    my ($object, $module, @methods) = @_;

    # Check if the module is already loaded
    unless (exists $INC{$module} || defined *{"${module}::"}) {
        eval "require $module";
        return undef if $@;
    }

    # Get list of functions exported by the module
    no strict 'refs';

    # Add each specified function (or all if none specified) as a method to the object
    foreach my $func ($#methods > -1 ? @methods : @{"${module}::EXPORT"}) {
        *{ref($object) . "::$func"} = sub { unshift @_, $object; goto &{"${module}::$func"} };
    }

    return $object;
}

################################################################################

=head2 Extends($object, %extend)

Extends an object with custom methods.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference to which methods will be added.

=item * C<%extend> - A hash where keys are method names and values are references to subroutines (CODE references). Alternatively, values can be references to scalars containing CODE references.

=back

=head3 Description:

This function extends the specified C<$object> by adding custom methods defined in C<%extend>. Each key-value pair in C<%extend> corresponds to a method name and its associated subroutine reference. If the method name already exists in C<$object>, it will override it.

=head3 Example:

    ############################################################################

    use Extender;

    # Create an object and define custom methods to extend $object
    my $object = Extends(
        {},
        custom_method => sub { return "Custom method" },
        dynamic_method => \"sub { return 'Dynamic method' }",
    );

    # Now $object has 'custom_method' and 'dynamic_method'

    ############################################################################

=head3 Supported Object Types: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects. For example:

     Extends($hash_object, hash_method => sub { ... });
     Extends($array_object, array_method => sub { ... });
     Extends($scalar_object, scalar_method => sub { ... });
     Extends($glob_object, glob_method => sub { ... });
     Extends($hash_class, hash_method => sub { ... });
     Extends($array_class, array_method => sub { ... });
     Extends($scalar_class, scalar_method => sub { ... });
     Extends($glob_class, glob_method => sub { ... });

=cut

sub Extends {
    my ($object, %extend) = @_;

    for my $name (keys %extend) {
        # Create the method
        no strict 'refs';
        my $package = ref($object) || $object;  # Get the package or class name

        if (ref $extend{$name} eq 'CODE') {
            # If $extend{$name} is a coderef, directly assign it
            *{$package . "::$name"} = sub {
                my $self = shift;
                return $extend{$name}->($self, @_);
            };
        }
        elsif (ref $extend{$name} eq 'SCALAR' && defined ${$extend{$name}} && ref ${$extend{$name}} eq 'CODE') {
            # If $method_ref is a reference to a scalar containing a coderef
            *{$package . "::$name"} = sub {
                my $self = shift;
                return ${$extend{$name}}->($self, @_);
            };
        }
        else {
            die "Invalid method reference provided for $name. Expected CODE or reference to CODEREF but got ".(ref($extend{$name})).".";
        }
    }

    return $object;
}

################################################################################

=head2 Alias($object, $existing_method, $new_name)

Creates an alias for an existing method in the object with a new name.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference in which the alias will be created.

=item * C<$existing_method> - The name of the existing method to alias.

=item * C<$new_name> - The new name for the alias.

=back

=head3 Description:

This function creates an alias for an existing method in the object with a new name. It allows referencing the same method implementation using different names within the same object.

=head3 Example:

    ############################################################################

    use Extender;

    my $object = Extends({}, original_method => sub {
        return "Original method";
    });

    # Create an alias 'new_alias' for 'original_method' in $object
    Alias($object, 'original_method', 'new_alias');

    # Using the alias
    print $object->new_alias(), "\n";  # Outputs: Original method

    ############################################################################

=head3 Supported Object Types: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects.

=cut

sub Alias {
    my ($object, $existing_method, $new_name) = @_;

    # Check if $object is a blessed reference
    die "Not a valid object reference" unless ref $object && ref $object ne 'HASH' && ref $object ne 'ARRAY' && ref $object ne 'SCALAR';

    # Validate $existing_method
    die "Invalid method name. Method name must be a string" unless defined $existing_method && $existing_method =~ /^\w+$/;

    # Validate $new_name
    die "Invalid alias name. Alias name must be a string" unless defined $new_name && $new_name =~ /^\w+$/;

    # Create the alias within the package where $object is blessed into
    {
        no strict 'refs';
        no warnings 'redefine';
        my $pkg = ref($object);
        *{$pkg . "::$new_name"} = \&{$pkg . "::$existing_method"};
    }

    return $object;
}

################################################################################

=head2 AddMethod($object, $method_name, $code_ref)

Adds a new method to the object.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference to which the method will be added.

=item * C<$method_name> - Name of the method to add. Must be a valid Perl subroutine name (word characters only).

=item * C<$code_ref> - Reference to the subroutine (code reference) that defines the method.

=back

=head3 Description:

This function adds a new method to the object's namespace. It validates the method name and code reference before adding it to the object.

=head3 Example:

    ############################################################################

    use Extender;

    my $object = Extends({}, custom_method => sub {
        my ($self, $arg1, $arg2) = @_;
        return "Custom method called with args: $arg1, $arg2";
    })->AddMethod(custom_method2 => sub {
        my ($self, $arg1, $arg2) = @_;
        return "Custom method2 called with args: $arg1, $arg2";
    });

    # Using the added method
    my $result = $object->custom_method2('foo', 'bar');
    print "$result\n";  # Outputs: Custom method2 called with args: foo, bar

    ############################################################################

=head3 Supported Object Types: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects.

=cut

sub AddMethod {
    my ($object, $method_name, $code_ref) = @_;

    # Validate method name
    die "Method name must be a string" unless defined $method_name && $method_name =~ /^\w+$/;

    # Validate code reference
    die "Code reference required" unless ref($code_ref) eq 'CODE';

    no strict 'refs';
    *{ref($object) . "::$method_name"} = $code_ref;

    return $object;
}

################################################################################

=head2 Decorate($object, $method_name, $decorator)

Decorates an existing method of an object with a custom decorator.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference whose method is to be decorated.

=item * C<$method_name> - The name of the method to decorate.

=item * C<$decorator> - A coderef representing the decorator function.

=back

=head3 Description:

This function allows decorating an existing method of an object with a custom decorator function. The original method is replaced with a new subroutine that invokes the decorator function before and/or after invoking the original method.

=head3 Example:

    ############################################################################

    use Extender;

    # Define a decorator function
    sub timing_decorator {
        my ($self, $orig_method, @args) = @_;
        my $start_time = time();
        my $result = $orig_method->($self, @args);
        my $end_time = time();
        my $execution_time = $end_time - $start_time;
        print "Execution time: $execution_time seconds\n";
        return $result;
    }

    my $object = AddMethod({counter => 0}, increment => sub { my ($object)=@_; $object->{counter}++ });

    # Decorate the 'increment' method with timing_decorator
    Decorate($object, 'increment', \&timing_decorator);

    # Invoke the decorated method
    $object->increment();

    # Output the counter value
    print "Counter: ", $object->{counter}, "\n";

    ############################################################################

=head3 Supported Object Types: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects.

=cut

sub Decorate {
    my ($object, $method_name, $decorator) = @_;

    # Check if $object is an object or a class name
    my $is_object = ref($object) ? 1 : 0;

    # Fetch the original method reference
    my $original_method;
    if ($is_object) {
        no strict 'refs';
        my $coderef = $object->can($method_name);
        die "Method $method_name does not exist in the object" unless $coderef;
        $original_method = $coderef;
    } else {
        no strict 'refs';
        $original_method = *{$object . '::' . $method_name}{CODE};
        die "Method $method_name does not exist in the package" unless defined $original_method;
    }

    # Replace the method with a decorated version
    if ($is_object) {
        no strict 'refs';
        my $class = ref $object;
        no warnings 'redefine';
        *{$class . "::$method_name"} = sub {
            my $self = shift;
            return $decorator->($self, $original_method, @_);
        };
    } else {
        no strict 'refs';
        no warnings 'redefine';
        *{$object . "::$method_name"} = sub {
            my $self = shift;
            return $decorator->($self, $original_method, @_);
        };
    }

    return $object
}

################################################################################

=head2 ApplyRole($object, $role_class)

Applies a role (mixin) to an object, importing and applying its methods.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference to which the role will be applied.

=item * C<$role_class> - The name of the role class to be applied.

=back

=head3 Description:

This function loads a role class using C<require>, imports its methods into the current package, and applies them to the object using C<apply>.

=head3 Example

    ############################################################################

    # Define a role (mixin)
    package MyRole;
    
    sub apply {
        my ($class, $object) = @_;
        no strict 'refs';
        for my $method (qw/foo bar/) {
            *{"${object}::$method"} = \&{"${class}::$method"};
        }
    }

    sub foo { print "foo\n" }
    sub bar { print "bar\n" }

    ############################################################################

    package main;

    use Extender;

    # Apply the role to an object
    my $object = {};
    ApplyRole($object, 'MyRole');

    # Call the role methods
    $object->foo();  # Outputs: foo
    $object->bar();  # Outputs: bar

    ############################################################################

=head3 Supported Object Types: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects.

=cut

sub ApplyRole {

    my ($object, $role_class) = @_;

    die "Object must be provided for role application" unless defined $object;
    die "Role class must be specified" unless defined $role_class && $role_class =~ /^\w+$/;

    # Ensure role class is loaded
    unless (exists $INC{$role_class} || defined *{"${role_class}::"}) {
        eval "require $role_class";
        return undef if $@;
    }

    # Apply the role's methods to the object if the apply method exists
    eval {
        no strict 'refs';
        my $apply_method = $role_class->can('apply');
        if ($apply_method) {
            $apply_method->($role_class, $object);
        } else {
            die "Role $role_class does not implement apply method";
        }
    };
    if ($@) {
        if ($@ =~ /Role $role_class does not implement apply method/) {
            return undef;  # Return gracefully if the apply method is missing
        } else {
            die "Failed to apply role $role_class to object: $@";
        }
    }

    return $object
}

################################################################################

=head2 InitHook($object, $hook_name, $hook_code)

Adds initialization or destruction hooks to an object.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference to which the hook will be added.

=item * C<$hook_name> - The type of hook to add. Valid values are 'INIT' for initialization and 'DESTRUCT' for destruction.

=item * C<$hook_code> - A code reference to the hook function to be executed.

=back

=head3 Description:

This function adds a code reference to the specified hook array (`_init_hooks` or `_destruct_hooks`) in the object. Hooks can be executed during object initialization or destruction phases.

=head3 Example:

    ############################################################################

    package MyClass;

    sub new {
        my $self = bless {}, shift;
        return $self;
    }

    sub DESTROY {
        my $self = shift;
        # Implement destruction logic if needed
    }

    ############################################################################

    package main;

    use Extender;
    use MyClass;

    InitHook('MyClass', 'INIT', sub {
        print "Initializing object\n";
    });

    InitHook('MyClass', 'DESTRUCT', sub {
        print "Destructing object\n";
    });

    my $object = MyClass->new(); # Output: Initializing object
    undef $object; # Output: Destructing object

    ############################################################################

=head3 Supported Object Types: Can only be used on class names. For example:

    use ClassName;

    InitHook('ClassName', 'INIT', sub { print "Hash object initialized\n" });
    InitHook('ClassName', 'DESTRUCT', sub { print "Array object destructed\n" });

=cut

sub InitHook {
    my ($class, $hook_name, $hook_code) = @_;

    # Validate arguments
    die "Class name must be specified" unless defined $class && $class =~ /^\w+$/;
    die "Unsupported hook name '$hook_name'" unless $hook_name =~ /^(INIT|DESTRUCT)$/;

    no strict 'refs';
    
    # Initialize hooks array if not already present
    $class->{"_${hook_name}_hooks"} ||= [];
    
    # Register the hook code
    push @{$class->{"_${hook_name}_hooks"}}, $hook_code;
    
    # If INIT hook, wrap the new method to execute hooks
    if ($hook_name eq 'INIT') {
        my $original_new = $class->can('new');
        no warnings 'redefine';
        *{$class . "::new"} = sub {
            my $self = $original_new->(@_);
            for my $hook (@{$class->{"_INIT_hooks"} || []}) {
                $hook->($self);
            }
            return $self;
        };
    }
            
    # If DESTRUCT hook, wrap the DESTROY method to execute hooks
    elsif ($hook_name eq 'DESTRUCT') {
        my $original_destroy = $class->can('DESTROY');
        no warnings 'redefine';
        *{$class . "::DESTROY"} = sub {
            my $self = shift;
            for my $hook (@{$class->{"_DESTRUCT_hooks"} || []}) {
                $hook->($self);
            }
            $original_destroy->($self) if $original_destroy && ref($self);
        };
    }

    return $class;
}

################################################################################

=head2 Unload($object, @methods)

Removes specified methods from the object's namespace.

=head3 Arguments:

=over 4

=item * C<$object> - The object reference from which methods will be removed.

=item * C<@methods> - List of method names to be removed from the object.

=back

=head3 Description:

This function removes specified methods from the object's namespace.
It effectively unloads or deletes methods that were previously added or defined within the object.

=head3 Example:

    ############################################################################

    use Extender;

    my $object = Extends({}, example_method => sub {
        return "Example method";
    });

    # Unload the method from $object
    Unload($object, 'example_method');

    # Attempting to use the unloaded method will fail
    eval {
        $object->example_method();  # This will throw an error
    };
    if ($@) {
        print "Error: $@\n";
    }

    ############################################################################

=head3 Supported Object Types: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects.

=cut

sub Unload {
    my ($object, @methods) = @_;

    # Check if $object is a valid reference and not a CODE reference
    my $ref_type = ref $object;
    die "Not a valid object reference" unless $ref_type && $ref_type ne 'CODE';

    # Validate @methods
    die "No methods specified for unloading" unless @methods;

    # Determine the package or type of the reference
    my $pkg = ref $object;
    if ($ref_type eq 'GLOB') {
        # Use the GLOB reference directly as the package
        $pkg = *{$object}{PACKAGE};
    }
    die "Cannot determine package for object reference" unless $pkg;

    no strict 'refs';

    foreach my $method (@methods) {
        next unless defined $method;  # Skip if method is undefined

        # Check if the method exists in the package's symbol table
        if (exists ${$pkg."::"}{$method}) {
            # Remove the method from the package's symbol table
            delete ${$pkg."::"}{$method};
        }
    }

    return $object;
}

################################################################################

=head1 USAGE

=head2 Extend an Object with Methods from a Module

    ############################################################################

    use Extender;

    # Extend an object with methods from a module
    my $object = Extend(MyClass->new(), 'Some::Class');

    # Now $object can use any method from Some::Class
    $object->method1(1, 2, 3, 4);

    ############################################################################

=head2 Extend an Object with Custom Methods

    ############################################################################

    use Extender;

    # Extend an object with custom methods
    my $object = Extends(
        MyClass->new(),
        greet => sub { my ($self, $name) = @_; print "Hello, $name!\n"; },
        custom_method => \&some_function,
    );

    # Using the added methods
    $object->greet('Alice');               # Output: Hello, Alice!
    $object->custom_method('Hello');       # Assuming some_function prints something

    ############################################################################

=head2 Adding Methods to Raw Reference Variables

    ############################################################################

    package HashMethods;

    use strict;
    use warnings;
    use Exporter 'import';
    our @EXPORT = qw(set get);

    sub set {
        my ($self, $key, $value) = @_;
        $self->{$key} = $value;
    }

    sub get {
        my ($self, $key) = @_;
        return $self->{$key};
    }

    1;

    ############################################################################

    package ArrayMethods;

    use strict;
    use warnings;
    use Exporter 'import';
    our @EXPORT = qw(add get);

    sub add {
        my ($self, $item) = @_;
        push @$self, $item;
    }

    sub get {
        my ($self, $index) = @_;
        return $self->[$index];
    }

    1;

    ############################################################################

    package ScalarMethods;

    use strict;
    use warnings;
    use Exporter 'import';
    our @EXPORT = qw(set get substr length);

    sub set {
        my ($self, $value) = @_;
        $$self = $value;
    }

    sub get {
        my ($self) = @_;
        return $$self;
    }

    sub substr {
        my $self = shift;
        return substr($$self, @_);
    }

    sub length {
        my ($self) = @_;
        return length $$self;
    }

    1;

    ############################################################################

    package main;

    use strict;
    use warnings;
    use Extender;
    use HashMethods;
    use ArrayMethods;
    use ScalarMethods;

    my $hash_object = {};
    my $array_object = [];
    my $scalar_object = \"";

    # Extend $hash_object with methods from HashMethods
    Extend($hash_object, 'HashMethods', 'set', 'get');

    # Extend $array_object with methods from ArrayMethods
    Extend($array_object, 'ArrayMethods', 'add', 'get');

    # Extend $scalar_object with methods from ScalarMethods
    Extend($scalar_object, 'ScalarMethods', 'set', 'get', 'substr', 'length');

    # Using extended methods for hash object
    $hash_object->set('key', 'value');
    print $hash_object->get('key'), "\n";  # Outputs: value

    # Using extended methods for array object
    $array_object->add('item1');
    $array_object->add('item2');
    print $array_object->get(0), "\n";  # Outputs: item1

    # Using extended methods for scalar object
    $scalar_object->set('John');
    print $scalar_object->get(), "\n";  # Outputs: John
    print $scalar_object->length(), "\n";  # Outputs: 4
    print $scalar_object->substr(1, 2), "\n";  # Outputs: oh
    $scalar_object->substr(1, 2, "ane");
    print $scalar_object->get(), "\n";  # Outputs: Jane

    1;

    ############################################################################

=head2 Adding methods using anonymous subroutines and existing functions

    ############################################################################

    package MyClass;
    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    ############################################################################

    package main;

    use Extender;

    my $object = MyClass->new();

    Extends($object,
        greet => sub { my ($self, $name) = @_; print "Hello, $name!\n"; },
        custom_method => \&some_function,
    );

    # Using the added methods
    $object->greet('Alice'); # Output: Hello, Alice!
    $object->custom_method('Hello'); # Assuming some_function prints something

    ############################################################################

=head2 Using Shared Object for Shared Variable functionality

    ############################################################################

    package main;

    use strict;
    use warnings;
    use threads;
    use threads::shared;
    use Extender;

    ############################################################################

    # Example methods to manipulate shared data

    # Method to set data in a shared hash
    sub set_hash_data {
        my ($self, $key, $value) = @_;
        lock(%{$self});
        $self->{$key} = $value;
    }

    # Method to get data from a shared hash
    sub get_hash_data {
        my ($self, $key) = @_;
        lock(%{$self});
        return $self->{$key};
    }

    # Method to add item to a shared array
    sub add_array_item {
        my ($self, $item) = @_;
        lock(@{$self});
        push @{$self}, $item;
    }

    # Method to get item from a shared array
    sub get_array_item {
        my ($self, $index) = @_;
        lock(@{$self});
        return $self->[$index];
    }

    # Method to set data in a shared scalar
    sub set_scalar_data {
        my ($self, $value) = @_;
        lock(${$self});
        ${$self} = $value;
    }

    # Method to get data from a shared scalar
    sub get_scalar_data {
        my ($self) = @_;
        lock(${$self});
        return ${$self};
    }

    ############################################################################

    # Create shared data structures
    my %shared_hash :shared;
    my @shared_array :shared;
    my $shared_scalar :shared;

    # Create shared objects
    my $shared_hash_object = \%shared_hash;
    my $shared_array_object = \@shared_array;
    my $shared_scalar_object = \$shared_scalar;

    ############################################################################

    # Extend the shared hash object with custom methods
    Extends($shared_hash_object,
        set_hash_data => \&set_hash_data,
        get_hash_data => \&get_hash_data,
    );

    # Extend the shared array object with custom methods
    Extends($shared_array_object,
        add_array_item => \&add_array_item,
        get_array_item => \&get_array_item,
    );

    # Extend the shared scalar object with custom methods
    Extends($shared_scalar_object,
        set_scalar_data => \&set_scalar_data,
        get_scalar_data => \&get_scalar_data,
    );

    ############################################################################

    # Create threads to manipulate shared objects concurrently

    # Thread for shared hash object
    my $hash_thread = threads->create(sub {
        $shared_hash_object->set_hash_data('key1', 'value1');
        print "Hash thread: key1 = " . $shared_hash_object->get_hash_data('key1') . "\n";
    });

    # Thread for shared array object
    my $array_thread = threads->create(sub {
        $shared_array_object->add_array_item('item1');
        print "Array thread: item at index 0 = " . $shared_array_object->get_array_item(0) . "\n";
    });

    # Thread for shared scalar object
    my $scalar_thread = threads->create(sub {
        $shared_scalar_object->set_scalar_data('shared_value');
        print "Scalar thread: value = " . $shared_scalar_object->get_scalar_data() . "\n";
    });

    ############################################################################

    # Wait for all threads to finish
    $hash_thread->join();
    $array_thread->join();
    $scalar_thread->join();

    1;

    ############################################################################

=head2 Updating existing methods on an object class

    ############################################################################

    package MyClass;

    sub new {
        my $class = shift;
        my $self = bless {}, $class;
        return $self;
    }

    sub original_method {
        return "Original method";
    }

    ############################################################################

    package main;

    use Extender;

    my $object = MyClass->new();

    # Define a method with the same name as an existing method
    Extends($object,
        original_method => sub { return "New method"; },
    );

    # Using the extended method
    print $object->original_method(), "\n";  # Outputs: New method

    1;

    ############################################################################

=head2 Creating Extender Class objects from any (even shared) reference typed variable

    ############################################################################

    package main;

    use Extender;

    ############################################################################

    my $object = Extend({},'Extender');

    # Define a method with the same name as an existing method
    $object->Extends(
        method => sub { return "method"; },
    );

    # Using the method
    print $object->method(), "\n";  # Outputs: method

    ############################################################################

    my $array = Extend([],'Extender');

    # Define a method with the same name as an existing method
    $array->Extends(
        method => sub { return "method"; },
    );

    # Using the method
    print $array->method(), "\n";  # Outputs: method

    ############################################################################

    my $scalar = Extend(\"",'Extender');

    # Define a method with the same name as an existing method
    $scalar->Extends(
        method => sub { return "method"; },
    );

    # Using the method
    print $scalar->method(), "\n";  # Outputs: method

    ############################################################################

    my $glob = Extend(\*GLOB,'Extender');

    # Define a method with the same name as an existing method
    $glob->Extends(
        method => sub { return "method"; },
    );

    # Using the method
    print $glob->method(), "\n";  # Outputs: method

    1;

    ############################################################################

=head2 Creating INIT and DESTRUCT Hooks

    ############################################################################

    package TestObject;

    sub new {
        my $self = bless {}, shift;
        return $self;
    }

    sub DESTROY {
        my $self = shift;
        # Implement destruction logic if needed
    }

    ############################################################################

    package main;

    use Extender;

    InitHook('TestObject', 'INIT', sub {
        print "Initializing object\n";
    });

    InitHook('TestObject', 'DESTRUCT', sub {
        print "Destructing object\n";
    });

    my $object = TestObject->new(); # Output: Initializing object
    undef $object; # Output: Destructing object

    ############################################################################

=head2 Creating an STDERR Logger with decorative functionalities

    use strict;
    use warnings;
    use Time::Piece;

    ############################################################################
    # BaseLogger.pm
    package BaseLogger;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub log {
        my ($self, $message) = @_;
        print STDERR $message;
    }

    1;

    ############################################################################
    # LoggerDecorators.pm
    package LoggerDecorators;

    use strict;
    use warnings;
    use Time::Piece;

    # Timestamp decorator
    sub add_timestamp {
        my ($logger) = @_;
        return sub {
            my ($self, $message) = @_;
            my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
            $logger->($self, "[$timestamp] $message");
        };
    }

    # Log level decorator
    sub add_log_level {
        my ($logger, $level) = @_;
        return sub {
            my ($self, $message) = @_;
            $logger->($self, "[$level] $message");
        };
    }

    1;

    ############################################################################
    # Example.pl

    package main;
    use strict;
    use warnings;
    use BaseLogger;
    use LoggerDecorators;

    # Create an instance of BaseLogger
    my $logger = BaseLogger->new();

    # Create a decorated logger
    my $decorated_logger = sub {
        my ($self, $message) = @_;
        $logger->log($message);
    };

    # Apply decorators to extend logging functionality
    $decorated_logger = add_timestamp($decorated_logger);
    $decorated_logger = add_log_level($decorated_logger, 'INFO');

    # Helper function to capture STDERR output
    sub capture_stderr {
        my ($code) = @_;
        my $output;
        {
            open my $stderr_backup, '>&', STDERR or die "Cannot backup STDERR: $!";
            open STDERR, '>', \$output or die "Cannot redirect STDERR: $!";
            
            $code->();
            
            open STDERR, '>&', $stderr_backup or die "Cannot restore STDERR: $!";
            close $stderr_backup;
        }
        return $output;
    }

    # Capture logging output
    my $stderr_output = capture_stderr(sub {
        $decorated_logger->("This is a test message\n");
    });

    # Output captured log
    print "Captured STDERR output:\n";
    print $stderr_output;

    1;


=cut

################################################################################

=head1 AUTHOR

OnEhIppY @ Domero Software <domerosoftware@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic> and L<perlgpl>.

=head1 SEE ALSO

L<Exporter>, L<perlfunc>, L<perlref>, L<perlsub>

=cut

################################################################################

1;

################################################################################
# EOF Extender.pm (C) 2024 OnEhIppY - Domero Sofware
