package Mic::Implementation;

use strict;
use Mic::_Guts;
use Package::Stash;
use Readonly;

sub import {
    my ($class, %arg) = @_;

    strict->import();

    $arg{-caller} = (caller)[0];
    $class->define(%arg);
}

sub define {
    my ($class, %arg) = @_;

    my $caller_pkg = delete $arg{-caller} || (caller)[0];
    my $stash = Package::Stash->new($caller_pkg);

    $class->update_args(\%arg);
    $class->add_attribute_syms(\%arg, $stash);

    $stash->add_symbol('%__meta__', \%arg);
    $class->install_subs($stash);
}

sub add_attribute_syms {
    my ($class, $arg, $stash) = @_;

    my @slots = (
        keys %{ $arg->{has} },
        '', # semiprivate pkg
    );
    foreach my $slot ( @slots ) {
        $class->add_obfu_name($arg, $stash, $slot);
    }
}

sub add_obfu_name {
    my ($class, $arg, $stash, $slot) = @_;

    Readonly my $sym_val => sprintf(
        "%s-$slot",
       Mic::_Guts::attribute_sym($arg->{version}),
    );
    $Mic::_Guts::obfu_name{$slot} = $sym_val;

    my $prefix = '';
    if($slot eq '') {
        $prefix = '__';
    }
    else {
        $slot = uc $slot;
    }
    $stash->add_symbol(
        sprintf('$%s%s', $prefix, $slot),
        \ $sym_val
    );
}

sub update_args {}

sub install_subs {}

1;

__END__

=head1 NAME

Mic::Implementation

=head1 SYNOPSIS

    package Example::Construction::Acme::Set_v1;

    use Mic::Implementation
        has => {
            SET => {
                default => sub { {} },
                init_arg => 'items',
            }
        },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->{$SET}{$e};
    }

    1;

=head1 DESCRIPTION

An implementation is a package containing attribute definitions as well as subroutines implementing the
behaviours described by the class interface.

=head1 CONFIGURATION

A implementation package is configured using Mic::Implementation and providing a hash with the following keys:

=head2 has => HASHREF

This declares attributes (or instance variables) of the implementation, mapping the name of an attribute to a hash with keys described in
the following sub sections.

An attribute called "FOO" can be accessed via it's object using the symbol C<$FOO> which is created by Mic::Implementation:

    $self->{$FOO}

=head3 default => SCALAR | CODEREF

The default value assigned to the attribute when the object is created. This can be an anonymous sub,
which will be excecuted to build the the default value (this would be needed if the default value is a reference,
to prevent all objects from sharing the same reference).

=head3 handles => ARRAYREF | HASHREF

This declares that methods can be forwarded from the object to this attribute in one of two ways
described below.

=head3 handles => ARRAYREF

All methods in the given array will be forwarded.

=head3 handles => HASHREF

Method forwarding will be set up such that a method whose name is a key in the given hash will be
forwarded to a method whose name is the corresponding value in the hash.


=head3 init_arg => SCALAR

This causes the attribute to be populated with the value of a similarly named constructor parameter.

=head3 reader => SCALAR

This must be a string which defines the name of a generated reader (or accessor) method.

Readers should only be created if they are needed by end users of the class.

=head3 writer => SCALAR

This must be a string which defines the name of a generated writer (or mutator) method.

Writers should only be created if they are needed by end users of the class.

=head2 classmethod => ARRAYREF

A list of methods that are intended to be called via the class (package), rather than via an object. See L<Mic::Manual::Construction> for an example.

=head1 PRIVATE ROUTINES

An implementation package will typically contain subroutines that are for internal use in the package and therefore ought not to be declared in the interface.
These won't be callable using the C<$object-E<gt>command(...)> syntax.

As an example, suppose we want to print an informational message whenever the Set's C<has> or C<add> methods are called. A first cut may look like:

    sub has {
        my ($self, $e) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), scalar(keys %{ $self->{$SET} });
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), scalar(keys %{ $self->{$SET} });
        ++$self->{$SET}{$e};
    }

But this duplication of code is not good, so we factor it out:

    sub has {
        my ($self, $e) = @_;

        log_info($self);
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;

        log_info($self);
        ++$self->{$SET}{$e};
    }

    sub size {
        my ($self) = @_;
        scalar(keys %{ $self->{$SET} });
    }

    sub log_info {
        my ($self) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
    }

Notice how the C<log_info> routine is called as a regular subroutine rather than as a method.

Here is a transcript of using this object via L<reply|https://metacpan.org/pod/distribution/Reply/bin/reply>

    5:51% reply -I t/lib
    0> use Example::Construction::Set_v1
    1> my $set = Example::Construction::Set_v1::->new
    $res[0] = bless( {
             '9bc09ac8-SET' => {}
           }, 'Example::Construction::Acme::Set_v1::__Assembled' )

    2> $set->can
    $res[1] = [
      'add',
      'has',
      'size'
    ]

    3> $set->add(1)
    [Thu Aug 10 16:16:15 2017] I have 0 element(s)
    $res[2] = 1

    4> $set->add(1)
    [Thu Aug 10 16:16:36 2017] I have 1 element(s)
    $res[3] = 2

    5> $set->log_info()
    Can't locate object method "log_info" via package "Example::Construction::Acme::Set_v1::__Assembled" at reply input line 1.
    6>

=head1 OBJECT COMPOSITION

Composition allows us to create new objects incorporating the functionality of existing ones.

As an example, consider a queue which we would use like this:

    use strict;
    use Test::More;
    use Example::Delegates::Queue;

    my $q = Example::Delegates::Queue->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    $q->pop;
    is $q->size => 1;
    done_testing();

Now suppose we need a queue which maintains a fixed maximum size by evicting the oldest items:

    use strict;
    use Test::More;
    use Example::Delegates::BoundedQueue;

    my $q = Example::Delegates::BoundedQueue::->new({max_size => 3});

    $q->push($_) for 1 .. 3;
    is $q->size => 3;

    $q->push($_) for 4 .. 6;
    is $q->size => 3;
    is $q->pop => 4;
    done_testing();

Here is the interface for this fixed size queue

    package Example::Delegates::BoundedQueue;

    use Mic::Class
        interface => {
            object => {
                push => {},
                pop  => {},
                size => {},
            },
            class => { new => {} }
        },

        implementation => 'Example::Delegates::Acme::BoundedQueue_v1',
    ;

    1;

And it is implemented like this

    package Example::Delegates::Acme::BoundedQueue_v1;

    use Example::Delegates::Queue;

    use Mic::Implementation
        has  => {
            Q => {
                default => sub { Example::Delegates::Queue::->new },
                handles => [qw( size pop )],
            },

            MAX_SIZE => {
                init_arg => 'max_size',
            },
        },
    ;

    sub push {
        my ($self, $val) = @_;

        $self->{$Q}->push($val);

        if ($self->size > $self->{$MAX_SIZE}) {
            $self->pop;
        }
    }

    1;

The bounded queue is composed out of the regular queue, which handles the C<size> and C<pop> methods.
