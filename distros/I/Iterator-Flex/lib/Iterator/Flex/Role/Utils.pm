package Iterator::Flex::Role::Utils;

# ABSTRACT: Role based utilities

use strict;
use warnings;

our $VERSION = '0.19';

use Ref::Util;

use Role::Tiny;
use experimental 'signatures';















sub _load_module ( $class, $path, $namespaces ) {

    if ( substr( $path, 0, 1 ) eq '+' ) {
        my $module = substr( $path, 1 );
        return $module if eval { Module::Runtime::require_module( $module ) };
        $class->_throw( class => "unable to load $module" );
    }
    else {
        $namespaces //= [ $class->_namespaces ];

        for my $namespace ( @{$namespaces} ) {
            my $module = $namespace . '::' . $path;
            return $module if eval { Module::Runtime::require_module( $module ) };
        }
    }

    $class->_throw(
        class => join ' ',
        "unable to find a module for '$path' in @{[ join( ', ', $namespaces->@* ) ]}"
    );
}













sub _load_role ( $class, $role ) {
    $class->_load_module( $role, [ $class->_role_namespaces ] );
}


































sub _can_meth ( $self, @methods ) {

    my $thing = Ref::Util::is_blessed_ref( $methods[0] ) ? shift @methods : $self;

    my $par = Ref::Util::is_hashref( $methods[-1] ) ? pop @methods : {};

    for my $method ( @methods ) {
        $self->_throw( parameter => "'method' parameters must be a string" )
          if Ref::Util::is_ref( $method );

        my $sub;
        foreach ( "__${method}__", $method ) {
            if ( defined( $sub = $thing->can( $_ ) ) ) {
                my @ret = ( ( !!$par->{name} ? $_ : () ), ( !!$par->{code} ? $sub : () ) );
                push @ret, $sub unless @ret;
                return @ret > 1 ? @ret : $ret[0];
            }
        }
    }

    return undef;
}





















sub _resolve_meth ( $obj, $target, $method, @fallbacks ) {

    my $code = do {

        if ( defined $method ) {
            Ref::Util::is_coderef( $method )
              ? $method
              : $target->can( $method )
              // $obj->_throw( parameter => qq{method '$method' is not provided by the object} );
        }

        else {
            $obj->_can_meth( $target, @fallbacks );
        }
    };

    return $code;
}










sub _throw ( $self, $failure, $msg ) {
    require Iterator::Flex::Failure;
    local @Iterator::Flex::Role::Utils::CARP_NOT = scalar caller;
    my $type = join( '::', 'Iterator::Flex::Failure', $failure );
    $type->throw( { msg => $msg, trace => Iterator::Flex::Failure->croak_trace } );
}


1;

#
# This file is part of Iterator-Flex
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory fallbacks

=head1 NAME

Iterator::Flex::Role::Utils - Role based utilities

=head1 VERSION

version 0.19

=head1 DESCRIPTION

This is a C<Role::Tiny> role which adds a variety of utility methods to
a class.  They are structured that way so that they may be overridden
if necessary.  (Well, technically I<under-ridden> if they already exist before
this role is applied).

=head1 CLASS METHODS

=head2 _load_module

  $module = $class->_load_module( $module, ?\@namespaces );

Loads the named module.  If C<$module> begins with a C<+> it is assumed to be a fully
qualified module name, otherwise it is searched for in the namespaces
provided by C<@namespaces> (which defaults to the namespaces returned
by the C<< L<_namespaces|Iterator::Flex::Base/_namespaces> >> class method.

Throws C<Iterator::Flex::Failure::class> if it couldn't require
the module (for whatever reason).

=head2 _load_role

  $module = $class->_load_role( $role );

Loads the named role.  If C<$role>  begins with a C<+>, it is assumed
to be a fully qualified name, otherwise it is searched for in the
namespaces returned by the C<<
L<_role_namespaces|Iterator::Flex::Base/_role_namespaces> >> class
method.

=head2 _can_meth

  $code = $class->_can_meth( @methods, ?\%pars  );
  $code = $class->_can_meth( $obj, @method, ?\%pars );

Scans an object to see if it provides one of the specified
methods. For each C<$method> in C<@methods>, it probes for
C<__$method__>, then C<$method>.

By default, it returns a reference to the first method it finds, otherwise C<undef> if none was found.

The return value can be altered using C<%pars>.

=over

=item name

return the name of the method.

=item code

return the coderef of the method. (Default)

=back

If both C<code> and C<name> are specified, both are returned as a list, C<name> first:

  ($name, $code ) = $class->_can_meth( $obj, @methods, {name => 1, code => 1 } );

=head2 _resolve_meth

  $code = $obj->_resolve_meth( $target, $method, @fallbacks );

Return a coderef to the specified method or one of the fallbacks.

If C<$method> is a coderef, it is returned.

If C<$method> is defined and is not a coderef, it is checked for directly via C<$target->can>.
If it does not exist, a C<Iterator::Flex::Failure::parameter> error is thrown.

If C<$method> is not defined, then C<< $obj->_can_meth( $target, @fallbacks ) >> is returned.

=head1 METHODS

=head2 _throw

  $obj->_throw( $type => $message );

Throw an exception object of class C<Iterator::Flex::Failure::$type> with the given message.

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-iterator-flex@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex>

=head2 Source

Source is available at

  https://gitlab.com/djerius/iterator-flex

and may be cloned from

  https://gitlab.com/djerius/iterator-flex.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Iterator::Flex|Iterator::Flex>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
