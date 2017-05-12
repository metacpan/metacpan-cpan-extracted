package Gantry::Plugins::Uaf::AuthorizeFactory;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $gobj = shift;

    my $class = ref($proto) || $proto;
    my $self;

    $self->{gantry} = $gobj;
    $self->{rules} = [];

    bless($self, $class);

    $self->rules();

    return $self;

}

sub add_rule($$) {
    my $self = shift;
    my $rule = shift;

    push @{$self->{rules}}, $rule;

    return 1;

}

sub can($$$$) {
    my $self = shift;
    my $user = shift;
    my $action = shift;
    my $resource = shift;

    my $rule;
    my ($granted, $denied) = (0,0);

    for $rule (@{$self->{rules}}) {

        $granted = 1 if ($rule->grants($user, $action, $resource));
        $denied = 1  if ($rule->denies($user, $action, $resource));
        last if ($denied);

    }

    return ($granted && !$denied);

}

sub rules($) {
    my $self = shift;

}

1;

__END__

=head1 NAME

Gantry::Plugins::Uaf::AuthorizeFactory - An abstract base class to use as a
pattern for your Authorize object.

=head1 SYNOPSIS

This package is a simple abstract base class. Use it as the base for creating
your instance of an Authorize object. 

=over 4

 package MyAuthorize;

 use strict;
 use warnings;

 use XYZRule;
 use SomeOtherRule;
 use base qw(Gantry::Plugins::Uaf::AuthorizeFactory);

 sub rules {
    my $self = shift;

    $self->add_rule(XYZRule->new());
    $self->add_rule(SomeOtherRule->new());

 }

 1;

=back

Then later in the main line code.

=over 4

 my $manager = $gobj->uaf_authz;

 if ($manager->can($user, "read", "/etc/shadow")) {
    open DATA, "</etc/shadow";
     ...
 }

=back

=head1 DESCRIPTION

This module implements an authorization scheme. The basic idea is that you 
have a set of users and a set of objects that can be accessed within a system.
In the code of the system itself, you want to surround sensitive operations 
with code that determines if the current user is allowed to do that operation.

This module attempts to make such a system possible. The module requires that 
you write implementations of rules for your system that are subclasses of 
Gantry::Plugins::Uaf::Rule. The rules can be written to use any data types, 
which are abstractly known as "users", "actions", and "resources." 

=over 4

A user is generally a Gantry::Plugins::Uaf::User object that your 
applications has identify as the entity operating the application. 

An action can be any data type (i.e. simply a string). It is really up
to the rule to determine what is valid. But, you have the latitude to
define anything as a action.

A resource can be any data type (i.e simply a string). But, it is really
up to the rule to determine what a resource is. Again, you have the latitude to
define anything as a resource.

=back

These are the steps needed to create an Authorize object:

1. Decide what sections of your code will need to be protected, and 
decide what to do if the user doesn't have access. For example if a 
screen should just hide fields, then the application code needs to 
reflect that.
 
2. Create an Authorize object for your application.

3. Surround sensitive sections of code with something like:

 if ($manager->can($user, "view salary", $payrollRecord)) {

     # show salary fields

 } else {

     # hide salary fields

 }

4. Create rules that spell out the behavior you want and add them
to your application's Authorization object. The basic idea is that
a rule can grant permission, or deny it. If it neither grants or 
denies, then the object will take the safe route and say that the 
action cannot be taken. Part of the code for the rule for protecting 
salaries might look like:

 package SalaryViewRule;

 use Gantry::Plugins::Uaf::User;
 use base qw(Gantry::Plugins::Uaf::Rule);

 sub grants {

     $self = shift;
     $user = shift;
     $action = shift;
     $resource = shift;

     # Do not grant on requests we don't understand.

     return 0 if (!$user->isa("Gantry::Plugin::Uaf::User") ||
                  !$self->isa("Gantry::Plugin::Uaf::Rule"));

     if ($action eq "view salary" && $resource->isa("Payroll::Record")) {

        if ($user->username() eq $resource->getEmployeeName()) {

           return "user can view their own salary";

        }

     }

     return 0;

 }

Then in your subclass of AuthorizeFactory:

 use SalaryViewRule;

   ...

 $viewRule = new SalaryViewRule;
 $manager->add_rule($viewRule);

=head1 METHODS

=over 4

=item new

This method intializes the object. It takes the Gantry object as a parameter.

=item can(user, action, resource)

This is the primary method of the Authorization object. It asks if the 
specified user can do the specified action on the specified resource. 

Example:

=over 4

 $manager->can($user, "eat", "cake");

=back

This would return true if the user is allowed to eat cake.

=item add_rule(rule)

This method will add an new rule to the object.

Example:

=over 4

 $authz->add_rule(MyRule->new());

=back

=item rules

This method should be overridden and your rules applied to the object. See the
above examples for usage.

=back

=head1 SEE ALSO

Gantry::Plugins::Uaf::Rule

=head1 AUTHOR

Kevin L. Esteb E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
