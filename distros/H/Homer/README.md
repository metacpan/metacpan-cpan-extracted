# NAME

Homer - Simple prototype-based object system

# SYNOPSIS

        use Homer;

        # create a prototype object
        my $person = Homer->new(
                first_name => 'Generic',
                last_name => 'Person',
                say_hi => sub {
                        my $self = shift;
                        print "Hi, my name is ", $self->first_name, ' ', $self->last_name, "\n";
                }
        );

        # create a new object based on it
        my $homer = $person->extend(
                first_name => 'Homer',
                last_name => 'Simpson'
        );

        $homer->say_hi; # prints 'Hi, my name is Homer Simpson'

        # let's extend even more
        my $bart = $homer->extend(
                first_name => 'Bart',
                father => sub { print "My father's name is ", $_[0]->prot->first_name, "\n" }
        );

        $bart->say_hi; # prints 'Hi, my name is Bart Simpson'
        $bart->father; # prints "My father's name is Homer"

# DESCRIPTION

`Homer` is a very simple **prototype-based object system**, similar to JavaScript.
In a prototype based object system there are no classes. Objects are either directly created
with some attributes and methods, or cloned from existing objects, in which case the object
being cloned becomes the prototype of the new object. The new object inherits all attributes
and methods from the prototype. Attributes and methods can be overridden, and new ones can be
added. The new object can be cloned as well, becoming the prototype of yet another new object,
thus creating a possibly endless chain of prototypes.

Prototype-based objects can be very powerful and useful in certain cases. They can provide a
quick way of solving problems. Plus, sometimes you just really need an object, but don't need
a class. I like to think of prototype-based OO versus class-based OO as being similar to
schema-less database systems versus relational database systems.

`Homer` is a quick and dirty implementation of such a system in Perl. As Perl is a class-based
language, this is merely a hack. When an object is created, `Homer` creates a specific class just
for it behind the scenes. When an object is cloned, a new class is created for the clone, with the
parent object's class pushed to the new one's `@ISA` variable, thus providing inheritance.

I can't say this implementation is particularly smart or efficient, but it gives me what I need
and is very lightweight (`Homer` has no non-core dependencies). If you need a more robust
solution, [Class::Prototyped](https://metacpan.org/pod/Class::Prototyped) might fit your need.

# HOMER AT A GLANCE

- Prototypes are created by calling `new()` on the `Homer` class with a hash, holding
attributes and methods:

            my $prototype = Homer->new(
                    attr1 => 'value1',
                    attr2 => 'value2',
                    meth1 => sub { print "meth1" }
            );

            $prototype->attr1; # value1
            $prototype->attr2; # value2
            $prototype->meth1; # prints "meth1"

- A list of all pure-attributes of an object (i.e. not methods) can be received by
calling `attributes()` on the object.

            $prototype->attributes; # ('attr1', 'attr2')

- Every object created by Homer can be cloned using `extend( %attrs )`. The hash can
contain new attributes and methods, and can override existing ones.

            my $clone = $prototype->extend(
                    attr2 => 'value3',
                    meth2 => sub { print "meth2" }
            );

            $clone->attr1; # value1
            $clone->attr2; # value3
            $clone->meth1; # prints "meth1"
            $clone->meth2; # prints "meth2"

- Objects based on a prototype can refer to their prototype using the `prot()` method:

            $clone->prot->attr2; # value2

- All attributes are read-write:

            $clone->attr1('value4');
            $clone->attr1; # value4
            $clone->prot->attr1; # still value1

- New methods can be added to an object after its construction. If the object is a
prototype of other objects, they will immediately receive the new methods too.

            $prototype->add_method('meth3' => sub { print "meth3" });
            $clone->can('meth3'); # true

- New attributes can't be added after construction (for now).
- Cloned objects can be cloned too, creating a chain of prototypes:

            my $clone2 = $clone->extend;
            my $clone3 = $clone2->extend;
            $clone3->prot->prot->prot; # the original $prototype

# CONSTRUCTOR

## new( \[ %attrs \] )

Creates a new prototype object with the provided attributes and methods (if any).

# CONFIGURATION AND ENVIRONMENT

`Homer` requires no configuration files or environment variables.

# DEPENDENCIES

None other than [Carp](https://metacpan.org/pod/Carp).

# BUGS AND LIMITATIONS

Please report any bugs or feature requests to
`bug-Homer@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Homer](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Homer).

# SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc Homer

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Homer](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Homer)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Homer](http://annocpan.org/dist/Homer)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Homer](http://cpanratings.perl.org/d/Homer)

- Search CPAN

    [http://search.cpan.org/dist/Homer/](http://search.cpan.org/dist/Homer/)

# AUTHOR

Ido Perlmuter <ido@ido50.net>

# LICENSE AND COPYRIGHT

Copyright 2017 Ido Perlmuter

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
