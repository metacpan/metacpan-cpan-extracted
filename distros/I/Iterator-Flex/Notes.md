# Solving the Hidden Class Problem

Iterator functions are typically not called as a class method, even
though they are essentially constructors.  For example,

```
use Iterator::Flex -all;
my $iter = imap { CODE } [0..10];
```


creates an iteration object.  What is that object's class?  There's a
default base Iterator class (in this case `Iterator::Flex::Iterator`,
but if the caller wants to use a specialized subclass, there's no
obvious way of instructing `imap` to use it.  Adding extra arguments
to `imap` destroys the fluid interface.  Adding a companion subroutine, e.g.
`imap_with_class`, forces the caller to be explicit with every call, and
requires the module to double the size of the interface.

An alternative is to indicate on a global or per-package basis which
class to use when importing `Iterator::Flex`:

```
use Iterator::Flex { default_class => 'My::Iterator::One'}, '-all';
ref( imap { CODE } [0..10]; ) == 'My::Iterator::One';

package Foo{
  use Iterator::Flex { class => 'My::Iterator::Two'}, '-all';

  ref( imap { CODE } [0..10]; ) == 'My::Iterator::Two';
}

package Bar {
  use Iterator::Flex -all;

  ref( imap { CODE } [0..10]; ) == 'My::Iterator::One';
}

```

`Iterator::Flex` would keep track of a package's requested class via a private hash, and
the iterator subroutines would call `Iterator::Flex::_instance_class` to determine which class to use:

```
   sub imap {

     my $class = Iterator::Flex::_instance_class( caller );
     [...]
     
   }
```

