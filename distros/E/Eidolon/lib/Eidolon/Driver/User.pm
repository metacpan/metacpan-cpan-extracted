package Eidolon::Driver::User;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7 
#   ---
#   Eidolon/Driver/User.pm - generic user driver
#
# ==============================================================================

use base qw/Eidolon::Driver Class::Accessor::Fast/;
use Eidolon::Driver::User::Exceptions;
use warnings;
use strict;

__PACKAGE__->mk_accessors(qw/agent ip language referer/);

our $VERSION  = "0.02"; # 2009-05-14 05:33:34

# ------------------------------------------------------------------------------
# \% new()
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $self);

    $class = shift;

    # class attributes
    $self  = 
    {
        "ip"       => undef,
        "agent"    => undef,
        "language" => undef,
        "referer"  => undef
    };

    bless $self, $class;
    $self->_init;

    return $self;
}

# ------------------------------------------------------------------------------
# _init()
# class initialization
# ------------------------------------------------------------------------------
sub _init()
{
    my ($self, $buffer);

    $self = shift;

    $self->agent  ( $ENV{"HTTP_USER_AGENT"}      ) if ($ENV{"HTTP_USER_AGENT"});
    $self->referer( $ENV{"HTTP_REFERER"}         ) if ($ENV{"HTTP_REFERER"});
    $self->ip     ( $ENV{"REMOTE_ADDR"}          ) if ($ENV{"REMOTE_ADDR"});
    $self->ip     ( $ENV{"HTTP_X_FORWARDED_FOR"} ) if ($ENV{"HTTP_X_FORWARDED_FOR"});

    if ($ENV{"HTTP_ACCEPT_LANGUAGE"}) 
    {
        ($buffer) = $ENV{"HTTP_ACCEPT_LANGUAGE"} =~ /^([^;]+);/;
        $self->language( substr($buffer, 0, index($buffer, ",")) ) if ($buffer && index($buffer, ",") != -1);
    }
}

# ------------------------------------------------------------------------------
# authorize($login)
# authorize user
# ------------------------------------------------------------------------------
sub authorize
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# unauthorize()
# unauthorize user
# ------------------------------------------------------------------------------
sub unauthorize
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# $ authorized()
# check if user is authorized
# ------------------------------------------------------------------------------
sub authorized
{
    throw CoreError::AbstractMethod;
}

1;

__END__

=head1 NAME

Eidolon::Driver::User - Eidolon generic user driver.

=head1 SYNOPSIS

Example user driver:

    package MyApp::Driver::User;
    use base qw/Eidolon::Driver::User/;

    sub authorized
    {
        my $self = shift;
        throw DriverError::User("This is just an example!");
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::User> is a generic user driver for 
I<Eidolon>. It declares some functions that are common for all driver 
types and some abstract methods, that I<must> be overloaded in ancestor classes.
All user drivers should subclass this package.

=head1 METHODS

=head2 new()

Class constructor. Creates the driver object and calls object initialization 
function.

=head2 authorize($login)

Authorize user. Abstract method, should be overloaded in ancestor class.

=head2 unauthorize()

Unauthorize user. Abstract method, should be overloaded in ancestor class.

=head2 authorized()

Checks if user is authorized. Abstract method, should be overloaded in ancestor
class.

=head1 ATTRIBUTES

The I<Eidolon::Driver::User> package has got several useful class 
attributes that filled in during object initialization. These variables could be
accessed through driver object using hashref or subroutine syntax:

    my ($r, $user, $ip, $referer);

    $r       = Eidolon::Core::Registry->get_instance;
    $user    = $r->loader->get_object("Eidolon::Driver::User");

    $ip      = $user->ip;       # or $user->{"ip"}
    $referer = $user->referer;  # or $user->{"referer"}

=head2 agent

User's HTTP user agent string (I<User-Agent:> field in HTTP request header).

=head2 ip

User's remote IP address (in string format).

=head2 language

User's preferred language string, that is transferred in HTTP request header
in I<Accept-Languages:> field. If this field contains more than one language,
first is used.

=head2 referer

User's HTTP referer (I<Referer:> field in HTTP request header).

=head1 SEE ALSO

L<Eidolon>, 
L<Eidolon::Driver::User::Exceptions>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
