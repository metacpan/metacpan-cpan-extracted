
# Extender

A Perl module that offers a wide range of functionalities to dynamically extend Perl objects with additional methods. This module is particularly useful when you want to enhance Perl objects without modifying their original definitions directly. Here's a summary and explanation of each function provided by the `Extender` module:

### Summary of Functions in `Extender` Perl Module:

1. **Extend**:
   - **Purpose**: Extends an object with methods from a specified module.
   - **Usage**: `Extend($object, $module, @methods)`
   - **Example**: `Extend($object, 'Some::Module', 'method1', 'method2')`

   - **Supported Object Types**: Can be applied to HASH, ARRAY, SCALAR, GLOB references, or a complete class object. For example:
     ```perl
     my $hash_ref = Extend({}, 'HashMethods', 'method1', 'method2');
     my $array_ref = Extend([], 'ArrayMethods', 'method1', 'method2');
     my $scalar_ref = Extend(\(my $scalar = 'value'), 'ScalarMethods', 'method1');
     my $glob_ref = Extend(\*GLOB, 'GlobMethods', 'method1');
     my $class_ref = Extend(MyClass->new(), 'ClassMethods', 'method1');
     ```

2. **Extends**:
   - **Purpose**: Extends an object with custom methods defined by the user.
   - **Usage**: `Extends($object, %extend)`
   - **Example**: `Extends($object, custom_method => sub { ... }, another_method => \&some_function)`

   - **Supported Object Types**: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects. For example:
     ```perl
     Extends($hash_object, hash_method => sub { ... });
     Extends($array_object, array_method => sub { ... });
     Extends($scalar_object, scalar_method => sub { ... });
     Extends($glob_object, glob_method => sub { ... });
     Extends($hash_class, hash_method => sub { ... });
     Extends($array_class, array_method => sub { ... });
     Extends($scalar_class, scalar_method => sub { ... });
     Extends($glob_class, glob_method => sub { ... });
     ```

3. **Alias**:
   - **Purpose**: Creates an alias for an existing method in the object with a new name.
   - **Usage**: `Alias($object, $existing_method, $new_name)`
   - **Example**: `Alias($object, 'existing_method', 'new_alias')`

   - **Supported Object Types**: Can be applied to HASH, ARRAY, SCALAR, GLOB references, or class objects.

4. **AddMethod**:
   - **Purpose**: Adds a new method to the object.
   - **Usage**: `AddMethod($object, $method_name, $code_ref)`
   - **Example**: `AddMethod($object, 'new_method', sub { ... })`

   - **Supported Object Types**: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects.

5. **Decorate**:
   - **Purpose**: Decorates an existing method with a custom decorator.
   - **Usage**: `Decorate($object, $method_name, $decorator)`
   - **Example**: `Decorate($object, 'method_to_decorate', sub { ... })`

   - **Supported Object Types**: Can be applied to HASH, ARRAY, SCALAR, GLOB references, or class objects.

6. **ApplyRole**:
   - **Purpose**: Applies a role (mixin) to an object.
   - **Usage**: `ApplyRole($object, $role_class)`
   - **Example**: `ApplyRole($object, 'SomeRole')`

   - **Supported Object Types**: Primarily used with class objects. Not directly applicable to raw references like HASH, ARRAY, or SCALAR.

7. **InitHook**:
   - **Purpose**: Adds initialization or destruction hooks to an object.
   - **Usage**: `InitHook($object, $hook_name, $hook_code)`
   - **Example**: `InitHook($object, 'INIT', sub { ... })`

   - **Supported Object Types**: Can be used with HASH, ARRAY, SCALAR, GLOB references, or class objects. For example:
     ```perl
     InitHook($hash_object, 'INIT', sub { print "Hash object initialized\n" });
     InitHook($array_object, 'DESTRUCT', sub { print "Array object destructed\n" });
     ```

8. **Unload**:
   - **Purpose**: Removes specified methods from the object's namespace.
   - **Usage**: `Unload($object, @methods)`
   - **Example**: `Unload($object, 'method1', 'method2')`

   - **Supported Object Types**: Can be applied to HASH, ARRAY, SCALAR, GLOB references, or class objects.

### Explanation and Usage:

- **Extend**: Useful for importing methods from external modules dynamically. It checks if the module is loaded, imports specified methods, and adds them to the object.
  ```perl
  my $object = SomeClass->new();
  Extend($object, 'SomeModule', 'method1', 'method2');
  ```

- **Extends**: Allows adding custom methods directly to an object.
  ```perl
  my $object = SomeClass->new();
  Extends($object, custom_method => sub { ... }, another_method => \&some_function);
  ```

- **Alias**: Creates an alias for an existing method.
  ```perl
  Alias($object, 'existing_method', 'alias_method');
  ```

- **AddMethod**: Adds a new method to the object.
  ```perl
  AddMethod($object, 'new_method_name', sub { ... });
  ```

- **Decorate**: Decorates an existing method with custom behavior.
  ```perl
  my $decorator_sub = sub { ... };
  Decorate($object, 'existing_method', $decorator_sub);
  ```

- **ApplyRole**: Applies a role (mixin) to an object.
  ```perl
  my $object = SomeClass->new();
  ApplyRole($object, 'SomeRole');
  ```

- **InitHook**: Adds hooks that execute during object initialization or destruction.
  ```perl
  package MyClass;

  use Extender;

  sub new {
      my $class = shift;
      my $self = Extend({}, 'Extender')
        ->InitHook('INIT', sub { print "Initializing object\n" })
        ->InitHook('DESTRUCT', sub { print "Destructing object\n" });
      return bless $self, $class;
  }

  package main;

  use MyClass;

  my $object = MyClass->new();  # Outputs: Initializing object

  undef $object;  # Outputs: Destructing object

  ```

- **Unload**: Removes specified methods from the object.
  ```perl
  Unload($object, 'method_to_remove');
  ```

### Installation

To install `Extender`, use CPAN or CPAN Minus:

```bash
cpan Extender
```
or
```bash
cpanm Extender
```

### Installation from GitHub

To install Extender directly from GitHub, you can clone the repository and use the Makefile.PL:

```bash
git clone https://github.com/DomeroSoftware/Extender.git
cd Extender
perl Makefile.PL
make
make test
make install
```

To clean the installation files from your disk after installation:

```bash
make clean
cd ..
rm -rf ./Extender
```

## Author

OnEhIppY @ Domero Software  
Email: domerosoftware@gmail.com  
GitHub: [DomeroSoftware/Extender](https://github.com/DomeroSoftware/Extender)

## License

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See [perlartistic](https://dev.perl.org/licenses/artistic.html) and [perlgpl](https://dev.perl.org/licenses/gpl-1.0.html).

## See Also

- [Exporter](https://metacpan.org/pod/Exporter)
- [perlfunc](https://metacpan.org/pod/perlfunc)
- [perlref](https://metacpan.org/pod/perlref)
- [perlsub](https://metacpan.org/pod/perlsub)
