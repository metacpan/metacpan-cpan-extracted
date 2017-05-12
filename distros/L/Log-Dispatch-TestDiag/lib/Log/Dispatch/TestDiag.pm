package Log::Dispatch::TestDiag;

use strict;
use warnings;
use base qw(Log::Dispatch::Output);
use Test::More qw();

our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless { }, $class;
    $self->_basic_init(@_);
    return $self;
}

sub log_message {
    my $self = shift;
    my %p    = @_;
    Test::More::diag($p{message});
}

1;

=head1 NAME

Log::Dispatch::TestDiag - Log to Test::More's diagnostic output

=head1 SYNOPSIS

  use Log::Dispatch;

  my $logger = Log::Dispatch->new(
      outputs => [
          ['TestDiag', min_level=>'debug'],
      ],
  );

=head1 DESCRIPTION

This module provides a C<Log::Dispatch> output that spits the logged records out
using C<Test::More>'s diagnostic output.

=head1 METHODS

=over

=item new()

Constructs a new C<Log::Dispatch::TestDiag> object and returns it to the caller.
Accepts standard C<Log::Dispatch::Output> parameters (e.g. C<min_level>).

=item log_message(%p)

Logs the given message to C<Test::More::diag()>.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2011, Graham TerMArsch.  All Rights Reserved.

This is free software, you can redistribute it and/or modify it under the
Artistic-2.0 license.

=head1 SEE ALSO

L<Log::Dispatch>.

=cut
