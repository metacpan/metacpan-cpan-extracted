=head1 NAME

SubClass - Fake class being composed with Moose syntax

=head1 SYNOPSIS

Nah...

=cut



package Class::Moose::SubClass::QwList;
use Moose;

with qw/ Class::Moose::RoleQwList1 Class::Moose::RoleQwList2 /;



1;



#EOF
