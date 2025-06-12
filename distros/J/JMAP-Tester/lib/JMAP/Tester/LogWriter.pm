use v5.14.0;
package JMAP::Tester::LogWriter 0.104;

use Moo::Role;

requires 'write';

use namespace::clean;

{
  package JMAP::Tester::LogWriter::Code 0.104;

  use Moo;
  use namespace::clean;
  with 'JMAP::Tester::LogWriter';
  has code => (is => 'ro', required => 1);
  sub write { $_[0]->code->($_[1]) }
}

{
  package JMAP::Tester::LogWriter::Handle 0.104;

  use Moo;
  use namespace::clean;
  with 'JMAP::Tester::LogWriter';
  has handle => (is => 'ro', required => 1);
  sub write { $_[0]->handle->print($_[1]) }
}

{
  package JMAP::Tester::LogWriter::Filename 0.104;

  use Moo;
  use namespace::clean;
  with 'JMAP::Tester::LogWriter';
  has filename_template => (
    is       => 'ro',
    default => 'jmap-tester-{T}-{PID}.log',
  );

  has _handle => (is => 'rw');
  has _pid => (is => 'rw', init_arg => undef, default => -1);

  sub write { $_[0]->_ensure_handle->print($_[1]) }

  sub _ensure_handle {
    my ($self) = @_;
    return $self->_handle if $self->_pid == $$;

    my $fn = $self->filename_template =~ s/\{T\}/$^T/gr =~ s/\{PID\}/$$/gr;
    open my $fh, '>>', $fn or Carp::confess("can't open $fn for writing: $!");

    $fh->autoflush(1);

    $self->_handle($fh);
    $self->_pid($$);
    return $fh;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::LogWriter

=head1 VERSION

version 0.104

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
