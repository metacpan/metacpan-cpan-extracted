package Gantry::Plugins::Uaf::Rule;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
   my $proto = shift;

   my $class = ref($proto) || $proto;
   my $self  = { };

   bless ($self, $class);

   return $self;

}

sub grants($$$$) {

   my $self = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   return 0;

}

sub denies($$$$) {

   my $self = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   # Abstract rule denies everything. Do not use.

   return 1;

}

1;

__END__

=head1 NAME

Gantry::Plugins::Uaf::Rule - A base class for rules.

=head1 DESCRIPTION

Each rule is a custom-written class that implements some aspect of your site's
access logic. Rules can choose to grant or deny a request. 

 package sample::Test;

 use strict;
 use warnings;

 use base qw(Gantry::Plugins::Uaf::Rule);

 sub grants($$$$) {

     my $self = shift;
     my $user = shift;
     my $action = shift;
     my $resource = shift;

     if ($action eq "edit" && $resource->isa("sample::Record")) {

        return 1 if ($user->username eq "root");

     }

     return 0;

 }

 sub denies($$$$) {

     return 0;
 
 }

 1;

The Authorize object will only give permission if I<at least> one rule grants
permission, I<and no> rule denies it. 

It is important that your rules never grant or deny a request they do not
understand, so it is a good idea to use type checking to prevent strangeness.
B<Assertions should not be used> if you expect different rules to accept
different resource types or user types, since each rule is used on every access
request.

=head1 SEE ALSO

 Gantry
 Gantry::Plugins::Uaf
 Gantry::Plugins::Uaf::User
 Gantry::Plugins::Uaf::Authenticate
 Gantry::Plugins::Uaf::AuthorizeFactory

=head1 AUTHOR

Kevin L. Esteb E<lt>kesteb@wsipc.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
