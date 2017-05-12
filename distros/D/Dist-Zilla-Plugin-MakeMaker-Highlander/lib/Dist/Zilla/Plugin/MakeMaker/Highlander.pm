use v5.10;
use strict;
use warnings;

package Dist::Zilla::Plugin::MakeMaker::Highlander;
# ABSTRACT: There can be only one

our $VERSION = '0.004';

use Moose 2;
use List::Util 1.33 'first';
use namespace::autoclean;

with 'Dist::Zilla::Role::InstallTool';

sub setup_installer {
    my ($self) = @_;

    my $build_script = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files }
      or $self->log_fatal('No Makefile.PL found. Using [MakeMaker] is required');

    my $insert = <<'HERE';
# Added by Dist::Zilla::Plugin::MakeMaker::Highlander
if ( $] < 5.012
  && ! $ENV{PERL_NO_HIGHLANDER}
  && ! ( $ENV{PERL_MM_OPT} && $ENV{PERL_MM_OPT} =~ /(?:INSTALL_BASE|PREFIX)/ )
  && ! grep { /INSTALL_BASE/ || /PREFIX/ } @ARGV
) {
    $WriteMakefileArgs{UNINST} = 1;
}

HERE

    my $content = $build_script->content;

    $content =~ s/(?=WriteMakefile\s*\()/$insert/
      or $self->log_fatal("Failed to insert UNINST provision into Makefile.PL");

    return $build_script->content($content);
}

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::Highlander - There can be only one

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # in dist.ini, *after* other MakeMaker plugins
    [MakeMaker::Highlander]

=head1 DESCRIPTION

The vast majority of distributions B<do not need this> and B<should not use
it>.  It is intended for distributions that are bundled with
L<ExtUtils::MakeMaker> in order to bootstrap it.

This plugin sets the C<UNINST> attribute to 1, to ensure that any other copies
of the module files are removed from C<@INC>.  It only runs on Perls before
v5.12 when C<@INC> was reordered, and only if there appears to be no use of
C<INSTALL_BASE> or C<PREFIX>.

This will result in warnings from old ExtUtils::MakeMaker, but appears to
work nonetheless.

If a build system already accounts for ExtUtils::MakeMaker's pathological
bundling and C<UNINST = 1> causes problems, the C<PERL_NO_HIGHLANDER>
environment variable may be set to a true value.

=for Pod::Coverage setup_installer

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-MakeMaker-Highlander/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-MakeMaker-Highlander>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-MakeMaker-Highlander.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Karen Etheridge

=over 4

=item *

David Golden <xdg@xdg.me>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
