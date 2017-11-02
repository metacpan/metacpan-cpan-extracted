package Filter::Cleanup;
# ABSTRACT: Execute cleanup statements when scope closes, regardless of errors
$Filter::Cleanup::VERSION = '0.03';

use 5.012;
use strict;
use warnings;
use Keyword::Declare;

our $CLEANUP;

sub import {
  keyword cleanup (Block $cl, /\s*;\s/? $br) :then(Statement* $st='1') {
    qq{
      local \$Filter::Cleanup::CLEANUP = Filter::Cleanup->new(sub $cl);
      $st
    };
  }
}

sub new {
  my ($class, $code) = @_;
  bless $code, $class;
}

sub DESTROY {
  my $self = shift;
  if (defined $self) {
    $self->();
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Filter::Cleanup - Execute cleanup statements when scope closes, regardless of errors

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Filter::Cleanup;

  open my $fh, $file_path or die $!;
  cleanup { close $fh };
  do_risky_stuff_with_fh($fh);

=head1 DESCRIPTION

Defines a block of code to be evaluated once the current scope has completed
execution. If an error is thrown during the execution of statements after the
C<cleanup> block, the error is trapped and rethrown after the C<cleanup> block
is executed.

=head1 NAME

Filter::Cleanup

=head1 CAVEATS

=head2 ORDERING OF CLEANUP BLOCKS

A cleanup block will execute ahead of any cleanups defined before it. That is,
for a given scope, cleanup blocks will be called in the opposite order in which
they were declared.

=head2 IMPLEMENTATION

This module was originally implemented as a source filter (hence the name), but
now uses L<Keyword::Declare>.

=head1 SEE ALSO

=head2 Guard

L<Guard> is implemented in XS and attaches a code block to the actual stack
frame, ensuring it is executed regardless of how the scope was exited. In many
cases, this may be preferable to the behavior of C<Filter::Cleanup>, which will
not be executed if the block calls C<exit> or C<goto> (note that C<last> I<is>
handled correctly).

=head1 AUTHOR

Jeff Ober L<sysread@fastmail.fm>

=head1 LICENSE

Perl5

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
