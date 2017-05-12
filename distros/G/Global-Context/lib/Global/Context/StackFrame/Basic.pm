package Global::Context::StackFrame::Basic;
{
  $Global::Context::StackFrame::Basic::VERSION = '0.003';
}
use Moose;
with 'Global::Context::StackFrame';
# ABSTRACT: trivial class implementing Global::Context::StackFrame


has description => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_string { $_[0]->description }

1;

__END__

=pod

=head1 NAME

Global::Context::StackFrame::Basic - trivial class implementing Global::Context::StackFrame

=head1 VERSION

version 0.003

=head1 SEE ALSO

L<Global::Context::Terminal>

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
