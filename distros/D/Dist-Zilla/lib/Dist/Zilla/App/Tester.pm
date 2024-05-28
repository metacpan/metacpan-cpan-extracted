package Dist::Zilla::App::Tester 6.032;
# ABSTRACT: testing library for Dist::Zilla::App

use Dist::Zilla::Pragmas;

use parent 'App::Cmd::Tester::CaptureExternal';
use App::Cmd::Tester 0.306 (); # result_class, ->app

use Dist::Zilla::App;
use File::Copy::Recursive qw(dircopy);
use File::pushd ();
use File::Spec;
use File::Temp;
use Dist::Zilla::Path;

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => [ test_dzil => Sub::Exporter::Util::curry_method() ],
  groups  => [ default   => [ qw(test_dzil) ] ],
};

use namespace::autoclean -except => 'import';

sub result_class { 'Dist::Zilla::App::Tester::Result' }

sub test_dzil {
  my ($self, $source, $argv, $arg) = @_;
  $arg ||= {};

  local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

  my $tmpdir = $arg->{tempdir} || File::Temp::tempdir(CLEANUP => 1);
  my $root   = path($tmpdir)->child('source');
  $root->mkpath;

  dircopy($source, $root);

  my $wd = File::pushd::pushd($root);

  local $ENV{DZIL_TESTING} = 1;
  my $result = $self->test_app('Dist::Zilla::App' => $argv);
  $result->{tempdir} = $tmpdir;

  return $result;
}

{
  package Dist::Zilla::App::Tester::Result 6.032;

  BEGIN { our @ISA = qw(App::Cmd::Tester::Result); }

  sub tempdir {
    my ($self) = @_;
    return $self->{tempdir};
  }

  sub zilla {
    my ($self) = @_;
    return $self->app->zilla;
  }

  sub build_dir {
    my ($self) = @_;
    return $self->zilla->built_in;
  }

  sub clear_log_events {
    my ($self) = @_;
    $self->app->zilla->logger->logger->clear_events;
  }

  sub log_events {
    my ($self) = @_;
    $self->app->zilla->logger->logger->events;
  }

  sub log_messages {
    my ($self) = @_;
    [ map {; $_->{message} } @{ $self->app->zilla->logger->logger->events } ];
  }
}

#pod =head1 DESCRIPTION
#pod
#pod This module exports only one function, C<test_dzil>.
#pod
#pod =head2 C<test_dzil>
#pod
#pod This function is used to test L<Dist::Zilla::App>.
#pod It receives two mandatory options. The first is the path to a Dist::Zilla-based
#pod distribution. The second, an array reference to a list of arguments. 
#pod
#pod The third optional argument is a hash reference, with further options. At the moment
#pod the only supported option is c<tempdir>.
#pod
#pod It returns a L<Dist::Zilla::App::Tester::Result>, that inherits from 
#pod L<App::Cmd::Tester::Result>. Typical methods called from this result are:
#pod
#pod =over 4 
#pod
#pod =item C<output>
#pod
#pod The output of running dzil;
#pod
#pod =item C<tempdir>
#pod
#pod The folder used for temporary files.
#pod
#pod =item C<build_dir>
#pod
#pod The folder where the distribution was built.
#pod
#pod =back
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Tester - testing library for Dist::Zilla::App

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This module exports only one function, C<test_dzil>.

=head2 C<test_dzil>

This function is used to test L<Dist::Zilla::App>.
It receives two mandatory options. The first is the path to a Dist::Zilla-based
distribution. The second, an array reference to a list of arguments. 

The third optional argument is a hash reference, with further options. At the moment
the only supported option is c<tempdir>.

It returns a L<Dist::Zilla::App::Tester::Result>, that inherits from 
L<App::Cmd::Tester::Result>. Typical methods called from this result are:

=over 4 

=item C<output>

The output of running dzil;

=item C<tempdir>

The folder used for temporary files.

=item C<build_dir>

The folder where the distribution was built.

=back

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
