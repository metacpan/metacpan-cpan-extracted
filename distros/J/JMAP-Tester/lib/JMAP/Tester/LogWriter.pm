package JMAP::Tester::LogWriter;
$JMAP::Tester::LogWriter::VERSION = '0.025';
use Moo::Role;

requires 'write';

use namespace::clean;

{
  package JMAP::Tester::LogWriter::Code;
$JMAP::Tester::LogWriter::Code::VERSION = '0.025';
use Moo;
  use namespace::clean;
  with 'JMAP::Tester::LogWriter';
  has code => (is => 'ro', required => 1);
  sub write { $_[0]->code->($_[1]) }
}

{
  package JMAP::Tester::LogWriter::Handle;
$JMAP::Tester::LogWriter::Handle::VERSION = '0.025';
use Moo;
  use namespace::clean;
  with 'JMAP::Tester::LogWriter';
  has handle => (is => 'ro', required => 1);
  sub write { $_[0]->handle->print($_[1]) }
}

{
  package JMAP::Tester::LogWriter::Filename;
$JMAP::Tester::LogWriter::Filename::VERSION = '0.025';
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

version 0.025

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
