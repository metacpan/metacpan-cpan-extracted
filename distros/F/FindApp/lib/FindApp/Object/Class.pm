package FindApp::Object::Class;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Vars qw(:all);
use FindApp::Utils qw(:all);

use namespace::clean;

sub class($) {
    my $self = &myself;
    return blessed($self);
}

# postfix scalar operator
sub object($) {
    my $self = &myself;
    return $self;
}

################################################################
# Our three constructors: new, old, renew.
################################################################

# Make and return a new singleton, copying the old one to it.
# This is so subclasses can stick their own singleton into our
# slot without knowing who else put what there.
sub renew { &ENTER_TRACE;
    my $self = shift;
    my $new  = $self->new;
    my $old  = $self->old;
    $new->copy($old);
    $self->old($new);
}

## UNITCHECK { __PACKAGE__->renew }  # stash new singleton

# Return singleton, making one as needed.
# Stash the argument as the new singleton.
sub old { &ENTER_TRACE;
    my($self, $new) = @_;
    state $Singleton;
    $Singleton = $new        if $new;
    return $Singleton ||= $self->new;
}

# Allocate, initialize, and return a new instance
# of the invocant's class, or this one if none.
# As an instance method, copy the old instance's
# values to the new one.  Run any params separately.
# Subclasses should override init and copy methods
# but invoke the c3 next::method to get these ones
# to run, too.
sub new { &ENTER_TRACE;
    my $old = shift;
    my $class = blessed($old) || $old || __PACKAGE__;
    my $new   = bless { }, $class;
    $new->init;
    $new->copy($old)    if blessed($old);
    $new->params(@_)    if @_;
    return $new;
}

################################################################
# Our three subconstructors: init, copy, params.
################################################################

# The job of an init() method is to populate its
# object's attributes.  The base object has only 3:
# origin, default_origin, and groups.  Subclasses
# with their own attributes should override this
# but call their c3 next::method first to eventually
# get back to this one.
sub init { &ENTER_TRACE;
    my $self = shift;

    $self->reset_origin;
    $self->default_origin("script");
    $self->allocate_groups;

    $self->group("root")->allowed->add(".");
    for my $root ($self->rootdir->object) {
        $root->allowed(".");
        $root->wanted("lib/");
    }

    for my $group ($self->subgroups) {
        $group->allowed($group->name);
    }

    $self->bindirs->allowed->add( glob "{script,util}{,s}" );
    
    $self->maybe::next::method;
}

# The job of a copy() method is to mass-copy all the
# attributes of one object into another object.  The
# receiving object is the invocant, and the donating
# object is the argument.  This makes it look like
# assignment with the receiver on the left, saying
# the the new object gets a copy of the old object:
#    $new->copy($old);
sub copy { &ENTER_TRACE;
    good_args(@_ == 2);
    my($new, $old) = @_;

    $new->origin($old->origin) if $old->has_origin;
    $new->default_origin($old->default_origin);

    for my $from_group ($old->groups) {
        my $name = $from_group->name;
        $new->group($name)->copy($from_group);
    }

    return $new;
}

# Run methods passed as constructor arguments
# against the new object. This looks like
# named argument pairs, where the name is
# that of the method, and the argument is a
# reference to any array of arguments to that
# named method.
sub params { &ENTER_TRACE;
    my($self, %method_arg_pair) = @_;
    while (my($method, $argref) = each %method_arg_pair) {
        $self->$method(@$argref);
    }
}

################################################################
# Both class adoptors: adopts_children and adopts_parents.
################################################################

# Class method that inserts itself into the
# inheritance chain of its "new children".
# Used by the -subclass import pragma to make
# it easy for new classes to subclass us.
sub adopts_children { &ENTER_TRACE;
    my($class, @children) = @_;
    for my $child (@children) {
        next if $child eq "FindApp";
        no strict "refs";
        say "push @{ $child . '::ISA' }, $class" if $Debugging;
        push @{ $child . "::ISA" }, $class;
    }
}

# Class method that turns itself into a
# subclass of its "new parents". With one
# parent this is easy, but when inheriting
# from multiple parents, a new class must be
# generated: its name is that of all its
# parent classes, each separated by a "+".
sub adopts_parents { &ENTER_TRACE;
    no strict "refs";
    my($class, @parents) = @_;
    return unless @parents;
    for my $module (@parents) {
        $module =~ s/^(?=::)/FindApp/;
        eval qq{ require $module; 1 } || die;
    }
    @parents = grep { ! $class->isa($_) } uniq @parents;
    unshift @parents, $class unless grep { $_->isa($class) } @parents;
    my $parent = join "+", @parents;
    if (@parents > 1) { 
        debug("$class CREATES A NEW PARENT $parent OUT OF THIN AIR");
        @{ $parent . "::ISA" } = @parents;    # drat, need to make a new parent...
        mro::set_mro($parent, "c3");
    }
    $parent->renew();
    debug("$_[0] SINGLETON BECOMES $parent");
    $_[0] = $parent;                          # ...and a new self
}

1;

=encoding utf8

=head1 NAME

FindApp::Object::Class - FIXME

=head1 SYNOPSIS

 use FindApp::Object::Class;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item adopts_children

=item adopts_parents

=item class

=item copy

=item init

=item new

=item object

=item old

=item params

=item renew

=back

=head2 Exports

=over

=item FIXME

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

