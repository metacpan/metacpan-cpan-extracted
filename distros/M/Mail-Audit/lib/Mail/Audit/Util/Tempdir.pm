use strict;
use warnings;
package Mail::Audit::Util::Tempdir;
{
  $Mail::Audit::Util::Tempdir::VERSION = '2.228';
}
require File::Tempdir;
use parent 'File::Tempdir';
# ABSTRACT: self-cleaning fork-respecting tempdirs

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{'Mail::Audit'}{pid} = $$;
  return $self;
}

sub DESTROY {
  return unless do {
    local $@;
    eval { $_[0]->{'Mail::Audit'}{pid} == $$ };
  };
  $_[0]->SUPER::DESTROY;
}

1;

__END__

=pod

=head1 NAME

Mail::Audit::Util::Tempdir - self-cleaning fork-respecting tempdirs

=head1 VERSION

version 2.228

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Meng Weng Wong

=item *

Ricardo SIGNES

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
