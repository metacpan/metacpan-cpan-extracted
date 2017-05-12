package Dist::Zilla::Role::Meta::Dynamic::Config;
{
  $Dist::Zilla::Role::Meta::Dynamic::Config::VERSION = '0.04';
}

# ABSTRACT: set dynamic_config to true in resultant META files

use Moose::Role;
with 'Dist::Zilla::Role::MetaProvider';

requires 'dynamic_config';

sub metadata {
  my $self = shift;
  return {
    dynamic_config => $self->dynamic_config,
  };
}

1;



__END__
=pod

=head1 NAME

Dist::Zilla::Role::Meta::Dynamic::Config - set dynamic_config to true in resultant META files

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Dist::Zilla::Role::Meta::Dynamic::Config is a L<Dist::Zilla> role that allows an author to
specify that their plugin performs some dynamic configuration as per L<CPAN::Meta::Spec>.

=head1 SEE ALSO

L<Dist::Zilla>

L<CPAN::Meta::Spec>

=for Pod::Coverage metadata
=end

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

