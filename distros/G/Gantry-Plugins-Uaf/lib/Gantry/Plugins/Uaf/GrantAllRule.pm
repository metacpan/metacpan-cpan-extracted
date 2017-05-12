package Gantry::Plugins::Uaf::GrantAllRule;

use 5.008;
use strict;
use warnings;

use Gantry::Plugins::Uaf::Rule;
use base qw(Gantry::Plugins::Uaf::Rule);

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

   # Default is to allow everything

   return 1;

}

sub denies($$$$) {
   my $self = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   # Default is to deny everything

   return 0;

}

1;

__END__

=head1 NAME

Gantry::Plugins::Uaf::GrantAllRule - A rule that grants permission to do everything.

=head1 DESCRIPTION

Gantry::Plugins::Uaf::GrantAllRule is a pre-built rule that grants access for
all permission requests. This rule can be used to help implement a system that
has a default policy of allowing access, and to which you add rules that deny
access for specific cases.

Note that the loose type checking of Perl makes this inherently dangerous, 
since a typo is likely to fail to deny access. It is recommended that you
take the opposite approach with your rules, since a typo will err on the 
side of denying access. The former is a security hole, the latter is a bug
that people will complain about (so you can fix it).

=head1 SEE ALSO

 Gantry::Plugins::Uaf::Authorize

=head1 AUTHOR

Kevin L. Esteb

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
