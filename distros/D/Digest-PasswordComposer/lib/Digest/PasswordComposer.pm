package Digest::PasswordComposer;
{
  $Digest::PasswordComposer::VERSION = '0.1';
}
# ABSTRACT: Generate unique passwords for web sites.

use strict;
use warnings;

use Exporter;
our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(pwdcomposer);

use Digest::MD5 qw(md5_hex);




sub pwdcomposer {
  my ($domain, $pwd) = @_;
  return substr(md5_hex("$pwd:$domain"),0,8);
}


sub new {
  my ($class) = @_;

  bless { domain => '' }, $class;
}


sub domain {
  my $self = shift;
  if (@_) { $self->{domain} = shift }
  return $self->{domain};
}


sub password {
  my $self = shift;
  return pwdcomposer($self->{domain},shift);
}


1;


__END__
=pod

=head1 NAME

Digest::PasswordComposer - Generate unique passwords for web sites.

=head1 VERSION

version 0.1

=head1 SYNOPSIS

This module can generate unique passwords for web sites, using the same algorithm as the Password Composer Greasemonky script for Firefox.

=head1 METHODS

=head2 pwdcomposer

=head2 new

=head2 domain

=head2 password

=head1 SEE ALSO

L<http://www.xs4all.nl/~jlpoutre/BoT/Javascript/PasswordComposer>

=head1 AUTHOR

Søren Lund <soren@lund.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Søren Lund.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

