package Evo::Class;
use Evo '-Export export_proxy; Evo::Class::Meta; Evo::Class::Base';

export_proxy '::Syntax', qw(lazy rw ro optional check inject no_method);

sub import ($me, @list) {
  my $caller = caller;
  my $meta   = Evo::Class::Meta->register($caller);
  no strict 'refs';    ## no critic
  push @{"${caller}::ISA"}, 'Evo::Class::Base' unless $caller->isa('Evo::Class::Base');
  Evo::Export->install_in($caller, $me, @list ? @list : '*');
}

sub META ($me, $dest) : ExportGen {
  sub { Evo::Class::Meta->find_or_croak($dest); };
}

sub requires ($me, $dest) : ExportGen {

  sub (@names) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    $meta->reg_requirement($_) for @names;
  };
}


sub Over ($dest, $code, $name) : Attr {
  Evo::Class::Meta->find_or_croak($dest)->mark_as_overridden($name);
}

sub Private ($dest, $code, $name) : Attr {
  Evo::Class::Meta->find_or_croak($dest)->mark_as_private($name);
}

sub has ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    Evo::Class::Meta->find_or_croak($dest)->reg_attr($name, @opts);
  };
}

sub has_over ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    Evo::Class::Meta->find_or_croak($dest)->reg_attr_over($name, @opts);
  };
}

sub extends ($me, $dest) : ExportGen {
  sub(@parents) {
    Evo::Class::Meta->find_or_croak($dest)->extend_with($_) for @parents;
  };
}

sub implements ($me, $dest) : ExportGen {
  sub(@parents) {
    Evo::Class::Meta->find_or_croak($dest)->check_implementation($_) for @parents;
  };
}


sub with ($me, $dest) : ExportGen {

  sub (@parents) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    foreach my $parent (@parents) {
      $meta->extend_with($parent);
      $meta->check_implementation($parent);
    }
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class

=head1 VERSION

version 0.0403

=head1 DESCRIPTION

Fast full featured post-modern Object oriented programming. Available both in PP and C. See L<https://github.com/alexbyk/perl-evo/tree/master/bench>

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    package My::Human;
    use Evo -Class, -Loaded;

    has 'name' => 'unnamed';
    has 'gender', ro;
    has age => optional, check sub($v) { $v >= 18 };
    sub greet($self) { say "I'm " . $self->name }
  }

  my $alex = My::Human->new(gender => 'male');

  # default value "unnamed"
  say $alex->name;

  # fluent design
  $alex->name('Alex')->age(18);
  say $alex->name, ': ', $alex->age;

  # method
  $alex->greet;

  ## ------------ protecting you from errors, uncomment to test
  ## will die, gender is required
  #My::Human->new();

  ## will die, age must be >= 18
  #My::Human->new(age => 17, gender => 'male');
  #My::Human->new(gender => 'male')->age(17);

  # --------- code reuse
  {

    package My::Developer;
    use Evo -Class;
    with 'My::Human';    # extends 'My::Human'; implements 'My::Human';

    has lang => 'Perl';

    sub show($self) {
      $self->greet();
      say "I like ", $self->lang;
    }


  }

  my $dev = My::Developer->new(gender => 'male');
  $dev->show;

=head1 SYNTAX

=head2 DIFFERENCES WITH SIMILAR MODULES

You will find thet syntax differs from other modules, such C<Moose>, C<Moo>. That's because I decided not to copy and made it to be as short/safe/obvious/common as possible. Give it a try

Also multiple inheritance is considered a good development pattern, because a composition (mixing) is used for code reuse.

A note about C<@ISA>. Evo classes don't require it, all methods and attributes are copied from parents to children. But C<@ISA> is still in use to work fine with external modules and to be able to call C<isa>.

Also every class is a subclass of C<Evo::Class::Base>

=head2 EXPORTING SYNTAX

By default this module exports some keywords, like C<has>, C<check>, C<rw> and so on. If your code conflicts with them, don't worry, perl will notify you and you can either rename conflicting methods, or exclude them from exporting/rename them this way:

  use Evo '-Class * -check -has has:attr';
  attr foo => 'FOO';

  sub check { }
  sub has   { }

  say __PACKAGE__->new->foo;

We skipped C<check> and C<has>, because they conflict with our methods, and export C<has> under C<attr> name, because we need it.

=head1 Usage

=head2 creating an object

  package My::Class;
  use Evo -Class;
  has 'simple';

=head2 new

  my $foo = My::Class->new(simple => 1);
  my $foo2 = My::Class->new();

We're protected from common mistakes, because constructor won't accept unknown attributes. Also, if attributes aren't optional and have additional flags, they will be checked too.

=head2 Attributes

  has 'foo', ro;
  has 'bar' => 'BAR', check sub {1};
  has 'baz' => 'BAZ';

Without options attributes are required and read-only. You can pass extra flags/options + a default value in any order. If you make a mistake, smart syntax parser will notify you. In the example above default values are C<BAR> and C<BAZ>. Pay attention, C<ro> and C<check> are not strings, so C<'ro'> or C<check =E<gt>> is a mistake.

=head3 Flags and Options

=head4 ro

Make attribute read-only. You can set it only once via C<new>. You still will be able to change it as a normal
hash key like 

  $obj->{ro_attr} = 33;

=head4 default value

Default value can be a scalar or a code reference, which will be called with a class as the first argument, unless C<lazy> flag is passed

  has 'def_code' => sub($class) { uc "$class" };
  say __PACKAGE__->new->def_code;

You can't use a reference, except a code reference, as a default value. To return, for example, a hashref, use this:

  has foo => sub($class) { { class => $class } };
  say __PACKAGE__->new->foo->{class};

=head4 lazy

This flag changes a behaviour of default value. It should be a code that will be called at the first invocation, not in constructor, and an instance will be passed as the argument. The result of this invocation will be stored in attribute

  has foo => lazy, sub($self) { [] };
  say __PACKAGE__->new->foo;

You should know that using this feature is an antipattern in the most of the cases.

=head4 optional

  has 'foo', optional;

By default, attributes are required. You can pass this flag to mark attribute as optional (but in most cases this is antipattern)

=head4 check

You can provide function that will check passed value (via constuctor and changing), and if that function doesn't return true, an exception will be thrown.

  has big => check sub { shift > 10 };

You can also return C<(0, "CustomError")> to provide more expressive explanation

  package main;
  use Evo;

  {

    package My::Foo;
    use Evo '-Class *';

    has big => check sub($val) { $val > 10 ? 1 : (0, "not > 10"); };
  };

  my $foo = My::Foo->new(big => 11);

  $foo->big(9);    # will die
  my $bar = My::Foo->new(big => 9);    # will die

=head4 inject

Used to describe dependencies of a class. We can build C<Foo> that depends on C<Bar> and we don't care how C<Bar> is implemented. L<Evo::Di> will resolve all dependencies

  package Foo;
  use Evo -Class, -Loaded;

  has bar => inject 'Bar';

  package Bar;
  use Evo -Class, -Loaded;
  has host => inject 'HOST';

  package main;
  use Evo '-Di';
  my $di = Evo::Di->new();
  $di->provide(HOST => '127.0.0.1');

  my $foo = $di->single('Foo');
  say $foo->bar->host;

See L<Evo::Di> for more information.

=head4 no_method

Register an attribute but don't install method(accessor) for it.

  package Foo;
  use Evo -Class, -Loaded;
  has foo => no_method;

  package main;
  use Evo;
  my $obj = Foo::->new(foo => 'FOO');
  warn $obj->{foo};    # FOO
  warn $obj->can('foo') ? 'can' : "can't";    # can't

=head1 CODE REUSE

Only public functions will be inherited.

Subroutine will be considered is a private if:
It's imported from other modules
It's monkey patched from other module by C<*Foo::foo = sub {}>
It's exported by L<Evo::Export> functions, (when a package is both a library and a class)

Subroutine will be considered as a public if:
It is defined in a class.
It is inherited by C<extends> or C<with>

All attributes are public.

Methods, generated somehow else, for example by C<*foo = sub {}>, can be marked as public by L<Evo::Class::Meta/reg_method>

=head2 Private methods

If you want to mark a method as private, use new C<lexical_subs> feature

  my sub _private {'private'}

This if preferred way to garantee that no one will be able to use this subroutine.

In some cases you may want to access private method for testing in the parent, but make unaccessible from a child. In this case use the folowing example:

  package Foo;
  use Evo -Class, -Loaded;
  sub _hello($self) : Private { 'hello from ' . $self }
  sub greet($self)            { say _hello($self) }

  package Bar;
  use Evo -Class;
  with 'Foo';


  package main;
  Bar->new->greet;
  say 'Foo can _hello?: ', !!Foo->can('_hello');
  say 'Bar can _hello?: ', !!Bar->can('_hello');

Pay attention. C<_hello> method should be called in this way: C<_hello($self)>, NOT C<$self-E<gt>_hello> - this will break your code.

C<:Private> attribute marks a method as private making an invocation of L<Evo::Class::Meta/mark_as_private> to skip this method from inheritance process

And of course, many developers just name methods like C<_private> (this method is actually private) to show that it can be changed, call them as they want and don't bother about clashing problems at all. Choose your own way.

=head2 Overriding

Evo protects you from method clashing. But if you want to override method or fix clashing, use L</has_over> function or C<:Override> attribute

    package My::Peter;
    use Evo -Class;
    with 'My::Human';

    has_over name => 'peter';
    sub greet : Over { ... }

If you want to call parent's method, call it by full name instead of C<SUPER>

  sub foo($self) : Over {
    say "Child";
    $self->My::Parent::foo();
  }

=head1 FUNCTIONS

This functions will be exported by default even without export list C<use Evo::Class>; You can always export something else like C<use Evo::Class 'has';> or export nothing C<use Evo::Class (); >

=head2 META

Return current L<Evo::Class::Meta> object for the class.

  use Data::Dumper;
  say Dumper __PACKAGE__->META->info;

See what's going on with the help of L<Evo::Class::Meta/info>

=head2 extends

Extends classes or roles. See also L</EXTENDING ALIEN CLASSES>

=head2 implements

Check if all required methods are implemented. Like interfaces

=head2 with

This does "extend + check implementation". Consider this example:

  package main;
  use Evo;

  {

    package My::Role::Happy;
    use Evo -Class, -Loaded;

    requires 'name';

    sub greet($self) {
      say "My name is ", $self->name, " and I'm happy!";
    }

    package My::Class;
    use Evo -Class;

    has name => 'alex';

    #extends 'My::Role::Happy';
    #implements 'My::Role::Happy';
    with 'My::Role::Happy';

  }

  My::Class->new()->greet();

C<My::Role::Happy> requires C<name> in derivered class. We could install shared code with C<extends> and then check implemantation with C<implements>. Or just use C<with> wich does both.

You may want to use C<extends> and C<implements> separately to resolve circular requirements, for example

=head1 CODE ATTRIBUTES

  sub foo : Over { 'OVERRIDEN'; }

Mark name as overridden. Overridden means it will override the "parent's" method with the same name without diying

=head1 INTERNAL

Every class gets C<$EVO_CLASS_META> variable which holds an C<Evo::Class::Meta> instance. See L<Evo::Class::Meta/register>

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
