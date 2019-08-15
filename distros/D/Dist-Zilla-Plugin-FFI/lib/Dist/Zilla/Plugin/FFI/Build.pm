package Dist::Zilla::Plugin::FFI::Build 1.04 {

  use 5.014;
  use Moose;
  use List::Util qw( first );


  # TODO: also add build and test prereqs for aliens
  # TODO: release as separate CPAN dist
  with 'Dist::Zilla::Role::FileMunger',
       'Dist::Zilla::Role::MetaProvider',
       'Dist::Zilla::Role::PrereqSource',
       'Dist::Zilla::Role::FilePruner',
  ;

my $mm_code_prereqs = <<'EOF1';
use FFI::Build::MM 0.83;
my $fbmm = FFI::Build::MM->new;
%WriteMakefileArgs = $fbmm->mm_args(%WriteMakefileArgs);
EOF1

my $mm_code_postamble = <<'EOF2';
BEGIN {
  # append to any existing postamble.
  if(my $old = MY->can('postamble'))
  {
    no warnings 'redefine';
    *MY::postamble = sub {
      $old->(@_) .
      "\n" .
      $fbmm->mm_postamble;
    };
  }
  else
  {
    *MY::postamble = sub {
      $fbmm->mm_postamble;
    };
  }
}
EOF2

  my $comment_begin = "# BEGIN code inserted by @{[ __PACKAGE__ ]}\n";
  my $comment_end   = "# END code inserted by @{[ __PACKAGE__ ]}\n";

  sub munge_files
  {
    my($self) = @_;
    my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
    $self->log_fatal("unable to find Makefile.PL")
      unless $file;
    my $content = $file->content;
    my $ok = $content =~ s/(unless \( eval \{ ExtUtils::MakeMaker)/"$comment_begin$mm_code_prereqs$comment_end\n\n$1"/e;
    $self->log_fatal('unable to find the correct location to insert prereqs')
      unless $ok;
    $content .= "\n\n$comment_begin$mm_code_postamble$comment_end\n";
    $file->content($content);
  }

  sub register_prereqs {
    my ($self) = @_;
    $self->zilla->register_prereqs( +{
        phase => 'configure',
        type  => 'requires',
      },
      'FFI::Build::MM' => '0.83',
    );
  }

  sub metadata
  {
    my($self) = @_;
    my %meta = ( dynamic_config => 1 );
    \%meta;
  }

  sub prune_files
  {
    my($self) = @_;

    foreach my $file (@{ $self->zilla->files })
    {
      next unless $file->name =~ m!^ffi/_build/!;
      $self->log_debug([ 'pruning %s', $file->name ]);
      $self->zilla->prune_file($file);
    }
  }
  
  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FFI::Build

=head1 VERSION

version 1.04

=head1 SYNOPSIS

 [FFI::Build]

=head1 DESCRIPTION

This plugin makes the appropriate modifications to your dist to allow
you to bundle code with L<FFI::Platypus::Bundle>.  It works with
L<FFI::Build::MM>, and only works with L<ExtUtils::MakeMaker>, so
don't try to use it with L<Module::Build>.

It specifically:

=over

=item Updates C<Makefile.PL>

To call L<FFI::Build::MM> to add the necessary hooks to build and install
your bundled code.

=item Sets configure-time prereqs

For L<FFI::Build::MM>.  It also makes the prereqs for your distribution
dynamic, which is required for L<FFI::Build::MM>.

=item Prunes any build files

Removes any files in C<ffi/_build> which may be created when developing
an FFI module using the bundle interface.

=back

This plugin adds the appropriate hooks for L<FFI::Build::MM> into your
C<Makefile.PL>.  It does not work with L<Module::Build>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
