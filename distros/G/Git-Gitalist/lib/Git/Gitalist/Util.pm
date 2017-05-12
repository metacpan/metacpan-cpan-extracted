package Git::Gitalist::Util;

use Moose;

use Method::Signatures;

use File::Which;
use Git::PurePerl;
use IPC::Run qw(run start);
use Symbol qw(geniosym);
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

has repository => (
  isa       => 'Git::Gitalist::Repository',
  handles   => { gitdir => 'path' },
  is        => 'bare',                 # No accessor
  weak_ref  => 1,                      # Weak, you have to hold onto me.
  predicate => 'has_repository',
);

has _git => (
  isa        => NonEmptySimpleStr,
  is         => 'ro',
  lazy_build => 1,
);

has gpp => (
  isa => 'Git::PurePerl', is => 'ro', lazy => 1,
  default => sub {
    my $self = shift;
    confess("Cannot get gpp without repository")
         unless $self->has_repository;
    Git::PurePerl->new(gitdir => $self->gitdir);
  },
);

sub git_executable_path {
  return File::Which::which('git');
}

method BUILDARGS(@p) {
  my $args = $self->SUPER::BUILDARGS(@p);

  unless($args->{_git}) {
    $args->{_git} ||= git_executable_path
         or die "Could not find a git executable in the PATH";
  }

  return $args;
}

method run_cmd (@args) {
  unshift @args, ( '--git-dir' => $self->gitdir )
       if $self->has_repository;
  #        print STDERR 'RUNNING: ', $self->_git, qq[ @args], $/;
  run [$self->_git, @args], \my($in, $out, $err);

  return $out;
}

method run_cmd_fh (@args) {
  my ($in, $out, $err) = (geniosym, geniosym, geniosym);
  unshift @args, ('--git-dir' => $self->gitdir)
       if $self->has_repository;
  #        print STDERR 'RUNNING: ', $self->_git, qq[ @args], $/;
  start [$self->_git, @args],
       '<pipe', $in,
       '>pipe', $out,
       '2>pipe', $err
            or die "cmd returned *?";
  return $out;
}

method run_cmd_list (@args) {
  my $cmdout = $self->run_cmd(@args);
  return $cmdout ? split(/\n/, $cmdout) : ();
}

method get_gpp_object (MooseX::Types::Common::String::NonEmptySimpleStr $sha1) {
  return $self->gpp->get_object($sha1) || undef;
}

1;

__END__

=head1 NAME

Git::Gitalist::Util - Class for utilities to run git or deal with Git::PurePerl

=head1 SEE ALSO

L<Git::PurePerl>.

=head1 AUTHORS

See L<Git::Gitalist> for authors.

=head1 LICENSE

See L<Git::Gitalist> for the license.

=cut

