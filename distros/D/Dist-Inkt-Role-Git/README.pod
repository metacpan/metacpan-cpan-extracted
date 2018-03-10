use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Git;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';


use Moose::Role;
use Git::Sub qw(tag status log);
use Types::Standard 'Bool';
use namespace::autoclean;
 
has source_control_is_git => (
        is      => "ro",
        isa     => Bool,
        lazy    => 1,
        builder => "_build_source_control_is_git",
);
 
sub _build_source_control_is_git {
        my $self = shift;
        !! $self->rootdir->child(".git")->is_dir;
}
 
after BUILD => sub {
  my $self = shift;
  return unless $self->source_control_is_git;
  $self->log('Source control is git');

  my @uncommitted = git::status qw(--untracked-files=no --porcelain);
  if (scalar @uncommitted) {
	 $self->log("git has uncommitted changes in following files:");
	 foreach my $msg (@uncommitted) {
		$self->log($msg);
	 }
	 die "Please commit them";
  }

};


before BuildTarball => sub {
  my $self = shift;
  return unless $self->source_control_is_git;
  my $pstr = 'release-' . $self->version;
  $pstr = 'dev-' . $pstr if ($self->version =~ m/_/);
  my $short = git::log qw(--pretty=format:'%h' -n 1);
  $self->log("Tagging $short as $pstr.");
  git::tag -s => -m => "Releasing $short tagged $pstr.", $pstr;
};


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Role::Git - Git functions for Dist::Inkt

=head1 DESCRIPTION

This module has the following functions:

=over

=item * Prevents building the release if there are uncommitted changes.

=item * Tags the release with the version number just before building the tarball.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-dist-inkt-role-git/issues>.

=head1 SEE ALSO

L<Dist::Inkt>

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

