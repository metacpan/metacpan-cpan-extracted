package Dist::Zilla::Plugin::NoAutomatedTesting;
{
  $Dist::Zilla::Plugin::NoAutomatedTesting::VERSION = '0.08';
}

# ABSTRACT: Avoid running under CPAN Testers

use Moose;
with 'Dist::Zilla::Role::InstallTool';

sub setup_installer {
  my $self = shift;

  my @build_files  = grep { $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } @{ $self->zilla->files };

  $self->log_fatal('No Makefile.PL or Build.PL was found. [NoAutomatedTesting] should appear in dist.ini after your installer plugin!')
    unless @build_files;

  my $content = 'exit 0 if $ENV{AUTOMATED_TESTING};' . "\n";
  foreach my $file (@build_files)
  {
    $file->content( $content . $file->content );
  }
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

'NO SMOKING'

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::NoAutomatedTesting - Avoid running under CPAN Testers

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  # In dist.ini - It is important that NoAutomatedTesting follows MakeMaker

  [MakeMaker]
  [NoAutomatedTesting]

The resultant distribution will exit at C<Makefile.PL> if the C<AUTOMATED_TESTING> environment variable is
set, indicating a CPAN Tester environment.

=head1 DESCRIPTION

CPAN Testers are great and do a worthy and thankless job, testing all the distributions uploaded to CPAN.
But sometimes we don't want a distribution to be tested by these gallant individuals.

Dist::Zilla::Plugin::NoAutomatedTesting is a L<Dist::Zilla> plugin that mungles C<Makefile.PL> to 
detect that it is being run by a CPAN Tester and C<exit 0> if it is.

As this plugin mungles the C<Makefile.PL> it is imperative that it is specified in C<dist.ini> AFTER C<[MakeMaker]>.

=head2 METHODS

These are required by the roles that this plugin uses.

=over

=item C<setup_installer>

Required by L<Dist::Zilla::Role::InstallTool>.

=back

=head1 NAME

Dist::Zilla::Plugin::NoAutomatedTesting - Avoid running under CPAN Testers

=head1 SEE ALSO

L<Dist::Zilla>

L<http://wiki.cpantesters.org/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
