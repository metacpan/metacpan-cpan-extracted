package Dist::Zilla::Plugin::FFI::Build 1.07 {

  use 5.020;
  use Moose;
  use List::Util qw( first );

  # ABSTRACT: Add FFI::Build to your Makefile.PL


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

  has lang => (
    is  => 'ro',
    isa => 'Maybe[Str]',
  );

  has build => (
    is => 'ro',
    isa => 'Maybe[Str]',
  );

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

    if($self->lang)
    {
      $self->zilla->register_prereqs( +{
          phase => 'runtime',
          type  => 'requires',
        },
        "FFI::Platypus::Lang::@{[ $self->lang ]}" => 0,
      );
    }

    if($self->build)
    {
      $self->zilla->register_prereqs( +{
          phase => 'configure',
          type  => 'requires',
        },
        "FFI::Build::File::@{[ $self->build ]}" => 0,,
      );
    }

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

    my $lang = $self->lang;

    foreach my $file ((), @{ $self->zilla->files })
    {
      my $name = $file->name;
      my $prune = 0;
      $prune = 1 if $name =~ m!^ffi/_build/!;
      $prune = 1 if defined $lang && $lang eq 'Rust' && $name =~ m!^(t/|)ffi/target/!;
      if($prune)
      {
        $self->log([ 'pruning %s', $name ]);
        $self->zilla->prune_file($file);
      }
      else
      {
        $self->log_debug([ 'NOT pruning %s', $name ]);
      }
    }

  }

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FFI::Build - Add FFI::Build to your Makefile.PL

=head1 VERSION

version 1.07

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

=head1 PROPERTIES

=head2 lang

If you are using a L<language plugin|FFI::Platypus::Lang> then you can
specify it here.  It will add it as a prereq.  This should be the "short"
name of the plugin, without the C<FFI::Platypus::Lang> prefix.  So for
example for L<FFI::Platypus::Lang::Rust> you would just set this to
C<Rust>.

In addition setting these C<lang> to these languages will have the following
additional affects:

=over 4

=item C<Rust>

The paths C<ffi/target> and C<t/ffi/target> will be pruned when building
the dist.  This is usually what you want.

=back

=head2 build

If you need a language specific builder this is where you specify it.
These are classes that live in the C<FFI::Build::File::> namespace.
For example for Rust you would specify L<Cargo|FFI::Build::File::Cargo>
and for Go you would specify L<GoMod|FFI::Build::File::GoMod>.

Setting this property will add the appropriate module as a configure
time prereq.

You do not usually need this for the C programming language.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Zaki Mughal (zmughal)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
