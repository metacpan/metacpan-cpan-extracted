# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Plugin-Test-Pod-LinkCheck
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Pod::LinkCheck;
# git description: v1.003-0-gcb2f3ab

our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Add author tests for POD links
$Dist::Zilla::Plugin::Test::Pod::LinkCheck::VERSION = '1.004';
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

sub register_prereqs {
  my $self = shift;

  $self->zilla->register_prereqs(
    {
        type  => 'requires',
        phase => 'develop',
    },
    'Test::Pod::LinkCheck' => '0',
  );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::Test::Pod::LinkCheck - Add author tests for POD links

=head1 VERSION

version 1.004

=head1 SYNOPSIS

  # dist.ini
  [Test::Pod::LinkCheck]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>
providing the following files:

  xt/author/pod-linkcheck.t - a standard Test::Pod::LinkCheck test

You can skip the test by setting
C<$ENV{SKIP_POD_LINKCHECK}>.

=for Pod::Coverage register_prereqs

=head1 INSTALLING

B<NOTE> You may need to update your L<CPANPLUS> index
before L<Test::Pod::LinkCheck> will work (or in my case even install).
Using the C<x> command at the C<cpanp> prompt did the trick for me.

Read more in L<Test::Pod::LinkCheck/NOTES>.

=head1 SEE ALSO

=over 4

=item *

L<Test::Pod::LinkCheck>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Test::Pod::LinkCheck

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-Pod-LinkCheck>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-test-pod-linkcheck at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugin-Test-Pod-LinkCheck>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Plugin-Test-Pod-LinkCheck>

  git clone https://github.com/rwstauner/Dist-Zilla-Plugin-Test-Pod-LinkCheck.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Dave Rolsky

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/pod-linkcheck.t ]___
#!perl

use strict;
use warnings;
use Test::More;

foreach my $env_skip ( qw(
  SKIP_POD_LINKCHECK
) ){
  plan skip_all => "\$ENV{$env_skip} is set, skipping"
    if $ENV{$env_skip};
}

eval "use Test::Pod::LinkCheck";
if ( $@ ) {
  plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
}
else {
  Test::Pod::LinkCheck->new->all_pod_ok;
}
