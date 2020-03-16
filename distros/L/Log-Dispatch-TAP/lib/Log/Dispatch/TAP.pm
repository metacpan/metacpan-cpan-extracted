package Log::Dispatch::TAP;

# ABSTRACT: Log to TAP output

use v5.10.0;
use strict;
use warnings;

use Params::ValidationCompiler qw/ validation_for /;
use Types::Standard qw/ Enum /;
use Test2::API qw/ context /;

use base qw/ Log::Dispatch::Output /;

use namespace::autoclean;

our $VERSION = 'v0.1.1';


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    state $validator = validation_for(
        params => {
            method => {
                type    => Enum[qw/ note diag /],
                default => 'note',
            },
        },
        slurpy => 1,
    );

    my %p = $validator->(@_);
    my $self = bless { method => $p{method} }, $class;
    $self->_basic_init(%p);
    return $self;
}


sub log_message {
    my $self   = shift;
    my %p      = @_;
    my $ctx    = context();
    my $method = $ctx->can( $self->{method} );
    $ctx->$method( $p{message} );
    $ctx->release;
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::TAP - Log to TAP output

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

  use Log::Dispatch;

  my $logger = Log::Dispatch->new(
    outputs => [
      [
         'TAP',
         method    => 'note',
         min_level => 'debug',
    ]
  );

=head1 DESCRIPTION

This module provides a L<Log::Dispatch> output sink for logging to
L<Test::Simple> diagnostics.

It is similar to L<Log::Dispatch::TestDiag>, except that it allows you
to choose the logging method.

=head1 CONSTRUCTOR

The constructor takes the following parameter in addition to the
standard parameters for L<Log::Dispatch::Output>.

=head2 method

This is the logging method, which is either C<note> or C<diag>
(corresponding to those functions in L<Test::More>).

=for Pod::Coverage log_message

=head1 SEE ALSO

L<Log::Log4perl::Appender::TAP>

L<Log::Dispatch::TestDiag>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Log-Dispatch-TAP>
and may be cloned from L<git://github.com/robrwo/Log-Dispatch-TAP.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Log-Dispatch-TAP/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of the code was adapted from L<Log::Log4perl::Appender::TAP>
and L<Log::Dispatch::TestDiag>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
