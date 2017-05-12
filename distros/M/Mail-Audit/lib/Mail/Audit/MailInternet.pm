use strict;
package Mail::Audit::MailInternet;
{
  $Mail::Audit::MailInternet::VERSION = '2.228';
}
# ABSTRACT: a Mail::Internet-based Mail::Audit object

use Mail::Internet;
use parent qw(Mail::Audit Mail::Internet);

sub _autotype_new {
  my $class = shift;
  my $self  = shift;
  bless($self, $class);
}

sub new {
  my $class = shift;
  my $type  = ref($class) || $class;

  # we want to create a subclass of Mail::Internet
  # call M::I's constructor
  my $self = Mail::Internet->new(@_);

  # now rebless it into this class
  bless $self, $type;
}

sub is_mime { 0; }

1;

__END__

=pod

=head1 NAME

Mail::Audit::MailInternet - a Mail::Internet-based Mail::Audit object

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
