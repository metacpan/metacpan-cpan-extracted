=head1 NAME

SubClass - Fake class being subclassed

=head1 SYNOPSIS

Nah...

=cut





package SubClass;
@ISA = "Class::IsaAssignmentScalar";
@ISA = ("Class::IsaAssignmentList1", "Class::IsaAssignmentList2");
@ISA = qw/ Class::IsaAssignmentQwList1 Class::IsaAssignmentQwList2 /;

push(@ISA, "Class::PushIsa");
push(@ISA, "Class::PushAnotherIsa");

use base "Class::UseBaseScalar";

 use base "Class::UseBaseBareList1", "Class::UseBaseBareList2";
 use base ("Class::UseBaseList1", "Class::UseBaseList2");

use base qw| Class::UseBaseQw1 Class::UseBaseQw2 |;


1;





#EOF
