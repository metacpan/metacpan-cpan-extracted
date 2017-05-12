use warnings;
use strict;
use Test::More tests => 52;

BEGIN
{
   use_ok 'Devel::EnforceEncapsulation';
}

# Sanity checks: invalid arguments

{
   eval { Devel::EnforceEncapsulation->apply_to('000'); };
   ok $@, 'Try to apply_to invalid package';
   eval { Devel::EnforceEncapsulation->apply_to('Foo', {policy => 'blarg'}); };
   ok $@, 'Try to use invalid failure policy';
   eval { Devel::EnforceEncapsulation->remove_from('000'); };
   ok $@, 'Try to remove_from invalid package';
}

# Test hashes

{
   my $o = Hash_class->new;
   $o->foo(1);
   is $o->{secret}, 1, 'Unencapsulated classes are not affected';

   Devel::EnforceEncapsulation->apply_to('Hash_class');
   if ( $] >= 5.017 ) {
      eval { my $val = $o->{secret}; };
      ok $@, 'Previously-unencapsulated instances are now encapsulated';
   } else {
      is $o->{secret}, 1, 'Unencapsulated instances are still not affected';
   }

   $o = Hash_class->new;
   $o->foo(2);
   is $o->foo(), 2, 'hash accessor';
   eval { my $val = $o->{secret}; };
   ok $@, 'Cannot reach into objects';
   eval { my @keys = keys %$o; };
   ok $@, 'Cannot reach into objects';
   eval { my @vals = values %$o; };
   ok $@, 'Cannot reach into objects';
   eval { my @vals = each %$o; };
   ok $@, 'Cannot reach into objects';
   eval { my @vals = @{$o}{qw(secret)}; };
   ok $@, 'Cannot reach into objects';
   eval { my $str = "$o->{secret}"; };
   ok $@, 'Cannot reach into objects';

   my $s = Hash_subclass->new;
   $s->foo('s');
   is $s->foo(), 's', 'subclass accessor';
   eval { my $val = $s->{secret}; };
   ok $@, 'Cannot reach into objects';

   Devel::EnforceEncapsulation->remove_from('Hash_class');
   if ( $] >= 5.017 ) {
      is $o->{secret}, 2, 'Encapsulated instances now unencapsulated';
   } else {
      eval { my $val = $o->{secret};  $val = $s->{secret}; };
      ok $@, 'Still cannot reach into runtime injected objects';
   }

   $o = Hash_class->new;
   $o->foo(3);
   is $o->{secret}, 3, 'Unencapsulated classes are once again not affected';
}

# Test super/sub classes

# Create an instance of each class and try every combination of
# setting and accessing properties.  Only the middle class gets
# encapsulation protection, so the superclass should be unaffected and
# the class and subclass should be affected.

{
   Devel::EnforceEncapsulation->apply_to('A_class');
   my $a = A_superclass->new;
   my $b = A_class->new;
   my $c = A_subclass->new;

   $a->a(1);
   $b->a(2);
   $c->a(3);
   is $a->a(), 1, 'superclass';
   is $b->a(), 2, 'class';
   is $b->b(), 2, 'class';
   is $c->a(), 3, 'subclass';
   is $c->b(), 3, 'subclass';
   is $c->c(), 3, 'subclass';
   is $a->{secret}, 1, 'Can reach into superclass objects';
   eval { my $val = $b->{secret}; };
   ok $@, 'Cannot reach into objects';
   eval { my $val = $c->{secret}; };
   ok $@, 'Cannot reach into objects';

   $b->b(4);
   $c->b(5);
   is $a->a(), 1, 'superclass';
   is $b->a(), 4, 'class';
   is $b->b(), 4, 'class';
   is $c->a(), 5, 'subclass';
   is $c->b(), 5, 'subclass';
   is $c->c(), 5, 'subclass';
   is $a->{secret}, 1, 'Can reach into superclass objects';
   eval { my $val = $b->{secret}; };
   ok $@, 'Cannot reach into objects';
   eval { my $val = $c->{secret}; };
   ok $@, 'Cannot reach into objects';

   $c->c(6);
   is $a->a(), 1, 'superclass';
   is $b->a(), 4, 'class';
   is $b->b(), 4, 'class';
   is $c->a(), 6, 'subclass';
   is $c->b(), 6, 'subclass';
   is $c->c(), 6, 'subclass';
   is $a->{secret}, 1, 'Can reach into superclass objects';
   eval { my $val = $b->{secret}; };
   ok $@, 'Cannot reach into objects';
   eval { my $val = $c->{secret}; };
   ok $@, 'Cannot reach into objects';
}

# Test other types besides hashrefs

{
   Devel::EnforceEncapsulation->apply_to('Array_class');
   Devel::EnforceEncapsulation->apply_to('Scalar_class');

   my $a = Array_class->new();
   $a->foo(4);
   is $a->foo(), 4, 'array accessor';
   eval { my $val = $a->[ 0 ]; };
   ok $@, 'Array direct access';

   my $s = Scalar_class->new();
   $s->foo(5);
   is $s->foo(), 5, 'scalar accessor';
   eval { my $val = $$s; };
   ok $@, 'Scalar direct access';

   {
      my $warned = 0;
      local $SIG{__WARN__} = sub { $warned++; };

      Devel::EnforceEncapsulation->remove_from('Hash_class');
      my $h = Hash_class->new;
      $h->foo(3);
      is $h->{secret}, 3, 'Unencapsulated classes are once again not affected';
      is $warned, 0, 'no warning on unencapsulated class';

      Devel::EnforceEncapsulation->apply_to('Hash_class', { policy => 'carp' });
      $h = Hash_class->new;
      $h->foo(3);
      is $h->{secret}, 3, 'encapsulation with carp does not prevent access...';
      is $warned, 1, '...but it does raise a warning';
   }
}

exit;

{   package Hash_class;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub foo {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}
{   package Hash_subclass;
    use base 'Hash_class';
}


{   package A_superclass;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    sub a {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}
{   package A_class;
    use base 'A_superclass';
    sub b {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}
{   package A_subclass;
    use base 'A_class';

    sub c {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}

{   package Array_class;

    sub new {
        my $class = shift;
        return bless [], $class;
    }

    sub foo {
        my $self = shift;
        $self->[ 0 ] = shift if @_;
        return $self->[ 0 ];
    }
}

{   package Scalar_class;

    sub new {
        my $class = shift;
        return bless \( my $obj ), $class;
    }

    sub foo {
        my $self = shift;
        ${$self} = shift if @_;
        return ${$self};
    }
}

