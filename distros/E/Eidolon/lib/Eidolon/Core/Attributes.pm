package Eidolon::Core::Attributes;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Core/Attributes.pm - base class for attributes handling
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 04:57:12

# ------------------------------------------------------------------------------
# @ MODIFY_CODE_ATTRIBUTES($class, $code, @attrs)
# modify code attributes (God bless guys from the Catalyst team)
# ------------------------------------------------------------------------------
sub MODIFY_CODE_ATTRIBUTES
{
    my ($class, $code, @attrs) = @_;

    {
        no strict "refs";

        unless (defined ${$class."::_code_cache"})
        {
            ${ $class."::_code_cache" } = {};
            ${ $class."::_attr_cache" } = {};

            *{ $class."::code_cache"  } = sub { return ${ $_[0]."::_code_cache" } }; 
            *{ $class."::attr_cache"  } = sub { return ${ $_[0]."::_attr_cache" } };
        }
    }

    $class->attr_cache->{$code} = [ @attrs ];
    $class->code_cache->{$_}    = $code foreach (@attrs);

    return ();
}

# ------------------------------------------------------------------------------
# @ FETCH_CODE_ATTRIBUTES($class, $code)
# read code attributes
# ------------------------------------------------------------------------------
sub FETCH_CODE_ATTRIBUTES
{
    return @{ $_[0]->attr_cache->{$_[1]} };
}

1;

__END__

=head1 NAME

Eidolon::Core::Attributes - base class for application controllers (only when
L<Eidolon::Driver::Router::Basic> router driver is used).

=head1 SYNOPSIS

Controller for example application (C<lib/Example/Controller/Example.pm>): 

    package Example::Controller::Example;
    use base qw/Eidolon::Core::Attributes/;

    sub default : Default
    {
        my $r;

        $r = Eidolon::Core::Registry->get_instance;
        $r->cgi->send_header;

        print "Hello there!";
    }

    1;

=head1 DESCRIPTION

The I<Eidolon::Core::Attributes> class contains methods to construct application
controllers for L<Eidolon::Driver::Router::Basic> router driver. Each controller 
should contain at least 1 method for request handling. Request routing is done 
with help of code attributes. For additional information about routing please 
refer to L<Eidolon::Driver::Router::Basic>. 

This class should never be used directly.

=head1 METHODS

=head2 MODIFY_CODE_ATTRIBUTES($class, $code, @attrs)

Is called when perl finds a method attribute. C<$class> - package name, in which
the attribute was found, C<$code> - code reference, C<@attrs> - array of
attributes for this method.

=head2 FETCH_CODE_ATTRIBUTES($class, $code)

Returns array of attributes for given C<$code> reference in given C<$class>.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::Router::Basic>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut

