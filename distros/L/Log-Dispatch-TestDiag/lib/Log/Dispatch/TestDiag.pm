package Log::Dispatch::TestDiag;

use strict;
use warnings;
use base qw(Log::Dispatch::Output);
use Test::More qw();

our $VERSION = '0.03';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless { }, $class;
    my %opts  = @_;

    $self->_basic_init(%opts);

    $self->{as_note} = 1 if ($opts{as_note});

    return $self;
}

sub log_message {
    my $self = shift;
    my %p    = @_;
    $self->{as_note}
        ? Test::More::note($p{message})
        : Test::More::diag($p{message});
}

1;

=head1 NAME

Log::Dispatch::TestDiag - Log to Test::More's diagnostic output

=head1 SYNOPSIS

  use Log::Dispatch;

  my $logger = Log::Dispatch->new(
      outputs => [
          ['TestDiag', min_level=>'debug', as_note=>0],
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

Also accepts an optional "C<as_note>" parameter, to indicate that output should
be sent via C<Test::More::note()> instead of C<Test::More::diag()>.  Difference
is that a "note" only appears in the verbose TAP stream and does not get shown
when running under a test harness.

=item log_message(%p)

Logs the given message.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2011, Graham TerMarsch.  All Rights Reserved.

This is free software, you can redistribute it and/or modify it under the
Artistic-2.0 license.

=head1 SEE ALSO

=over

=item L<Log::Dispatch>

=back

=cut
