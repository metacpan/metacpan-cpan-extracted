use 5.020;
use true;

package Dist::Zilla::Plugin::FFI::CheckLib 1.08 {

  # ABSTRACT: FFI::CheckLib alternative to Dist::Zilla::Plugin::CheckLib

  use Moose;
  use experimental qw( signatures );

  with
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::InstallTool',
    'Dist::Zilla::Role::PrereqSource',
  ;

  use namespace::autoclean;

  my @list_options = qw/
    alien
    lib
    libpath
    symbol
    systempath
    verify
  /;
  sub mvp_multivalue_args { @list_options }

  has $_ => (
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [] },
    traits  => ['Array'],
    handles => { $_ => 'elements' },
  ) for @list_options;

  has [ qw/recursive try_linker_script/ ] => (
    is      => 'rw',
    lazy    => 1,
    default => sub { 0 },
  );

  around dump_config => sub {
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = +{
      (map {; $_ => [ $self->$_ ] } @list_options),
      recursive => $self->recursive,
      try_linker_script => $self->try_linker_script,
    };

    $config
  };

  sub register_prereqs ($self) {
    $self->zilla->register_prereqs( +{
        phase => 'configure',
        type  => 'requires',
      },
      'FFI::CheckLib' => '0.28',
    );
  }

  my %files;
  sub munge_files ($self) {
    my @mfpl = grep
      {; $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' }
        @{ $self->zilla->files };

    for my $mfpl (@mfpl) {
      $self->log_debug('munging ' . $mfpl->name . ' in file gatherer phase');
      $files{ $mfpl->name } = $mfpl;
      $self->_munge_file($mfpl);
    }

    ()
  }

  sub setup_installer ($self) {
    my @mfpl = grep
      {; $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' }
        @{ $self->zilla->files };

    unless (@mfpl) {
      $self->log_fatal(
        'No Makefile.PL or Build.PL was found.'
        .' [FFI::CheckLib] should appear in dist.ini'
        .' after [MakeMaker] or variant!'
      );
    }

    for my $mfpl (@mfpl) {
      next if exists $files{ $mfpl->name };
      $self->log_debug('munging ' . $mfpl->name . ' in setup_installer phase');
      $self->_munge_file($mfpl);
    }

    ()
  }

  sub _munge_file ($self, $file) {
    my $orig_content = $file->content;
    $self->log_fatal('could not find position in ' . $file->name . ' to modify!')
      unless $orig_content =~ m/use strict;\nuse warnings;\n\n/g;
    my $pos = pos($orig_content);

    my @options = map {;
      my @stuff = map {; '\'' . $_ . '\'' } $self->$_;
      @stuff ?
        [
          $_ => @stuff > 1 ? ('[ ' . join(', ', @stuff) . ' ]') : $stuff[0]
        ] : ()
    } grep !/^verify$/, @list_options,
        ( $self->recursive ? 'recursive' : () ),
        ( $self->try_linker_script ? 'try_linker_script' : () );

    my @verify = map { s/^\|//r } $self->verify;

    $file->content(
        substr($orig_content, 0, $pos)
      . "# inserted by " . blessed($self)
      . ' ' . ($self->VERSION || '<self>') . "\n"
      . "use FFI::CheckLib;\n"
      . "check_lib_or_exit(\n"
      . join('', map {; ' 'x2 . $_->[0] . ' => ' . $_->[1] . ",\n" } @options )
      . (@verify ? join("\n", map { ' 'x2 . $_ } 'verify => sub {', (map { ' 'x2 . $_ } @verify), '},')."\n" : '')
      . ");\n\n"
      . substr($orig_content, $pos)
    );
  }

  __PACKAGE__->meta->make_immutable;

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FFI::CheckLib - FFI::CheckLib alternative to Dist::Zilla::Plugin::CheckLib

=head1 VERSION

version 1.08

=head1 SYNOPSIS

In your F<dist.ini>:

 [FFI::CheckLib]
 lib = zmq

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that modifies the F<Makefile.PL> or
F<Build.PL> in your distribution to check for a dynamic library L<FFI::Platypus> (or
similar) can access; uses L<FFI::CheckLib> to perform the check.

If the library is not available, the program exits with a status of zero,
which will result in a NA result on a CPAN test reporter.

This module is adapted directly from Dist::Zilla::Plugin::CheckLib, copyright (c) 2014 by Karen Etheridge (CPAN: ETHER).
Look there for XS modules.

=head1 CONFIGURATION OPTIONS

All options are as documented in L<FFI::CheckLib>:

=head2 C<lib>

The name of a single dynamic library (for example, C<zmq>).
Can be used more than once.

L<FFI::CheckLib> will prepend C<lib> and append an appropriate dynamic library
suffix as needed.

=head2 C<symbol>

A symbol that must be found. Can be used more than once.

=head2 C<systempath>

The system search path to use (instead of letting L<FFI::CheckLib> determine
paths). Can be used more than once.

=head2 C<libpath>

Additional path to search for libraries. Can be used more than once.

=head2 C<alien>

The name of an L<Alien> class that provides the L<Alien::Base> interface for
dynamic libraries.

Can be used more than once.

=head2 C<recursive>

If set to true, directories specified in C<libpath> will be searched
recursively.

Defaults to false.

=head2 C<try_linker_script>

If set to true, uses the linker command to attempt to resolve C<.so> files for
platforms where C<.so> files are linker scripts.

Defaults to false.

=head2 C<verify>

The verify function body to use.  For each usage, is one line of the function
body.  You can prefix with the pipe C<|> character to get proper indentation.

 verify = | my($name, $libpath) = @_;
 verify = | my $ffi = FFI::Platypus->new;
 verify = | $ffi->lib($libpath);
 verify = | my $f = $ffi->function('foo_version', [] => 'int');
 verify = | if($f) {
 verify = |   return $f->call() >= 500; # we accept version 500 or better
 verify = | } else {
 verify = |   return;
 verify = | }

If you use any modules, such as L<FFI::Platypus> in this example, be sure that
you declare them as configure requires.

=head1 SEE ALSO

=over 4

=item *

L<FFI::CheckLib>

=item *

L<Devel::CheckLib> and L<Dist::Zilla::Plugin::CheckLib>

=item *

L<Devel::AssertOS> and L<Dist::Zilla::Plugin::AssertOS>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Zaki Mughal (zmughal)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
