package Gantry::Plugins::Uaf::User;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($proto, $username) = @_;

    my $class = ref($proto) || $proto;
    my $self = {
        username => $username, 
        attributes => {}
    };

    bless($self, $class);

    return $self;

}

sub username {
    my ($self) = shift;

    return $self->{username};

}

sub attribute {
    my ($self, $name, $p) = @_;

    $self->{attributes}->{$name} = $p if (defined($p));
    return $self->{attributes}->{$name};

}

1;

__END__

=head1 NAME

Gantry::Plugins::Uaf::User - A module that defines a basic user object.

=head1 SYNOPSIS

=over 4

 use Gantry::Plugins::Uaf::User;

 my $username = 'joe blow';
 my $user = Gantry::Plugins::Uaf::User->new($username);
 $user->attribute('birthday', '01-Jan-2008');
 
=back

=head1 DESCRIPTION

Gantry::Plugins::Uaf::User is a base module that can be used to create an
user object. The object is extremely flexiable and is not tied to any one 
data source. 

=head1 METHODS

=over 4

=item new

This method initializes the user object. It takes one parameter, the username.

Example:

=over 4

 my $username = 'joeblow';
 my $user = Gantry::Plugins::Uaf::User->new($username);

=back

=back

=head1 MUTATORS

=over 4

=item attribute

Set/Returns a user object attribute.

Example:

=over 4

 $birthday = $user->attribute('birthday');
 $user->attribute('birthday', $birthday);

=back

=back

=head1 SEE ALSO

 Gantry::Plugins::Uaf

=head1 AUTHOR

Kevin L. Esteb

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
