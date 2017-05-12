package KinoSearch1::Util::Class;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;

use KinoSearch1::Util::VerifyArgs qw( verify_args kerror );

sub new {
    my $class = shift;    # leave the rest of @_ intact.

    # find a defaults hash and verify args
    $class = ref($class) || $class;
    my $defaults;
    {
        no strict 'refs';
        $defaults = \%{ $class . '::instance_vars' };
    }
    if ( !verify_args( $defaults, @_ ) ) {
        # if a user-based subclass, find KinoSearch1 parent class and verify.
        my $kinoclass = _traverse_at_isa($class);
        confess kerror() unless $kinoclass;
        {
            no strict 'refs';
            $defaults = \%{ $kinoclass . '::instance_vars' };
        }
        confess kerror() unless verify_args( $defaults, @_ );
    }

    # merge var => val pairs into new object, call customizable init routine
    my $self = bless { %$defaults, @_ }, $class;
    $self->init_instance;

    return $self;
}

# Walk @ISA until a parent class starting with 'KinoSearch1::' is found.
sub _traverse_at_isa {
    my $orig = shift;
    {
        no strict 'refs';
        my $at_isa = \@{ $orig . '::ISA' };
        for my $parent (@$at_isa) {
            return $parent if $parent =~ /^KinoSearch1::/;
            my $grand_parent = _traverse_at_isa($parent);
            return $grand_parent if $grand_parent;
        }
    };
    return '';
}

sub init_instance { }

sub init_instance_vars {
    my $package = shift;

    no strict 'refs';
    no warnings 'once';
    my $first_isa = ${ $package . '::ISA' }[0];
    %{ $package . '::instance_vars' }
        = ( %{ $first_isa . '::instance_vars' }, @_ );
}

sub ready_get_set {
    ready_get(@_);
    ready_set(@_);
}

sub ready_get {
    my $package = shift;
    no strict 'refs';
    for my $member (@_) {
        *{ $package . "::get_$member" } = sub { return $_[0]->{$member} };
    }
}

sub ready_set {
    my $package = shift;
    no strict 'refs';
    for my $member (@_) {
        *{ $package . "::set_$member" } = sub { $_[0]->{$member} = $_[1] };
    }
}

=for Rationale:
KinoSearch1 is not thread-safe.  Among other things, the C-struct-based classes
cause segfaults or bus errors when their data gets double-freed by DESTROY.
Therefore, CLONE dies with a user-friendly error message before that happens.

=cut

sub CLONE {
    my $package = shift;
    die(      "CLONE invoked by package '$package', indicating that threads "
            . "or Win32 fork were initiated, but KinoSearch1 is not thread-safe"
    );
}

sub abstract_death {
    my ( undef, $filename, $line, $methodname ) = caller(1);
    die "ERROR: $methodname', called at $filename line $line, is an "
        . "abstract method and must be defined in a subclass";
}

sub unimplemented_death {
    my ( undef, $filename, $line, $methodname ) = caller(1);
    die "ERROR: $methodname, called at $filename line $line, is "
        . "intentionally unimplemented in KinoSearch1, though it is part "
        . "of Lucene";
}

sub todo_death {
    my ( undef, $filename, $line, $methodname ) = caller(1);
    die "ERROR: $methodname, called at $filename line $line, is not "
        . "implemented yet in KinoSearch1, but is on the todo list";
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Util::Class - class building utility

==head1 SYNOPSIS

    package KinoSearch1::SomePackage::SomeClass;
    use base qw( KinoSearch1::Util::Class );
    
    BEGIN {
        __PACKAGE__->init_instance_vars(
            # constructor params / members
            foo => undef,
            bar => {},

            # members
            baz => {},
        );
    }

==head1 DESCRIPTION

KinoSearch1::Util::Class is a class-building utility a la
L<Class::Accessor|Class::Accessor>, L<Class::Meta|Class::Meta>, etc.  It
provides four main services:

==over

==item 1 

A mechanism for inheriting instance variable declarations.

==item 2 

A constructor with basic argument checking.

==item 3

Manufacturing of get_xxxx and set_xxxx methods.

==item 4 

Convenience methods which help in defining abstract classes.

==back

==head1 VARIABLES

==head2 %instance_vars

The %instance_vars hash, which is always a package global, serves as a
template for the creation of a hash-based object.  It is built up from all the
%instance_vars hashes in the module's parent classes, using
init_instance_vars().  

Key-value pairs in an %instance_vars hash are labeled as "constructor params"
and/or "members".  Items which are labeled as constructor params can be used
as arguments to new().

    BEGIN {
        __PACKAGE__->init_instance_vars(
            # constructor params / members
            foo => undef,
            bar => 10,
            # members
            baz => '',
        );
    }
    
    # ok: specifies foo, uses default for bar, derives baz
    my $object = __PACKAGE__->new( foo => $foo );

    # not ok: baz isn't a constructor param
    my $object = __PACKAGE__->new( baz => $baz );

    # ok if a parent class defines boffo as a constructor param
    my $object = __PACKAGE__->new( 
        foo   => $foo,
        boffo => $boffo,
    );

%instance_vars may only contain scalar values, as the defaults are merged
into the object using a shallow copy.

init_instance_vars() must be called from within a BEGIN block and before any
C<use> directives load a child class -- if children are born before their
parents, inheritance gets screwed up.

==head1 METHODS

==head2 new

A generic constructor with basic argument checking.  new() expects hash-style
labeled parameters; the label names must be present in the %instance_vars
hash, or it will croak().

After verifying the labeled parameters, new() merges %instance_vars and @_
into a new object.  It then calls $self->init_instance() before returning the
blessed reference.

==head2 init_instance

    $self->init_instance();

Perform customized initialization routine.  By default, this is a no-op.

==head2 init_instance_vars

    BEGIN {
        __PACKAGE__->init_instance_vars(
            a_safe_variable_name_that_wont_clash => 1,
            freep_warble                         => undef,
        );
    }

Package method only.  Creates a package global %instance_vars hash in the
passed in package which consists of the passed in arguments plus all the
key-value pairs in the parent class's %instance_vars hash.

==head2 ready_get_set ready_get ready_set

    # create get_foo(), set_foo(), get_bar(), set_bar() in __PACKAGE__
    BEGIN { __PACKAGE__->ready_get_set(qw( foo bar )) };

Mass manufacture getters and setters.  The setters do not return a meaningful
value.

==head2 abstract_death unimplemented_death todo_death

    sub an_abstract_method      { shift->abstract_death }
    sub an_unimplemented_method { shift->unimplemented_death }
    sub maybe_someday           { shift->todo_death }

These are just different ways to die(), and are of little interest until your
particular application comes face to face with one of them.  

abstract_death indicates that a method must be defined in a subclass.

unimplemented_death indicates a feature/function that will probably not be
implemented.  Typically, this would appear for a sub that a developer
intimately familiar with Lucene would expect to find.

todo_death indicates a feature that might get implemented someday.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

