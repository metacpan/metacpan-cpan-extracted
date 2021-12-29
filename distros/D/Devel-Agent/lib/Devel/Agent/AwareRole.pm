package Devel::Agent::AwareRole;

use Modern::Perl;
use Role::Tiny;
require Devel::Agent;
our $VERSION=$Devel::Agent::VERSION;

require Scalar::Util;

sub ___db_stack_filter { 
  my ($class,$agent,$frame,$args,$raw_caller)=@_; 

  # prevent deeper traces if we are in here
  $agent->max_depth($frame->{depth}); 

  if(my $blessed=&Scalar::Util::blessed($class)) {
    $class=$blessed;
  }

  # hide internal calls from our trace
  return 0 if $frame->{caller_class} eq $class;

  return 1;
} 

1;
__END__

=head1 NAME

Devel::Agent::AwareRole - default agent role

=head1 SYNOPSIS

  package MySPiffyPackage;

  use Role::Tiny::With;
  with 'Devel::Agent::AwareRole';

  1;

=head1 DESCRIPTION

This class implements the ___db_stack_filter method, used to manipulate object frames in a given stack trace within the Devel::Agent or agent debgger.

=head1 AUTHOR

Michael Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut
