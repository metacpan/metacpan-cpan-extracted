package Dist::Zilla::Plugin::AlienBuild;

use 5.014;
use Moose;
use List::Util qw( first );
use Path::Tiny qw( path );

# ABSTRACT: Use Alien::Build with Dist::Zilla
our $VERSION = '0.19'; # VERSION


with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::MetaProvider';
with 'Dist::Zilla::Role::PrereqSource';

has _installer => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my($self) = @_;
    my $name = first { /^(Build|Makefile)\.PL$/ } map { $_->name } @{ $self->zilla->files };
    $self->log_fatal('Unable to find Makefile.PL or Build.PL') unless $name;
    $name;
  },
);

sub register_prereqs
{
  my($self) = @_;

  my $prereqs = $self->zilla->prereqs->as_string_hash;

  foreach my $phase (keys %$prereqs)
  {
    foreach my $type (keys %{ $prereqs->{$phase} })
    {
      if(defined $prereqs->{$phase}->{$type}->{'Alien::Base'})
      {
        $self->zilla->register_prereqs({
          type => $type,
          phase => $phase,
        }, 'Alien::Base' => '0.038' );
      }
    }
  }

  if(my $file = first { $_->name eq 'alienfile' } @{ $self->zilla->files })
  {
    require Alien::Build;
    my $alienfile = Path::Tiny->tempfile;
    $alienfile->spew($file->content);
    my $build = Alien::Build->load($alienfile);

    my $ab_version = '0.32';

    foreach my $hook (qw( build_ffi gather_ffi patch_ffi ))
    {
      $ab_version = '0.40';
    }

    if($self->_installer eq 'Makefile.PL')
    {
      $self->zilla->register_prereqs(
        { phase => $_ },
        'Alien::Build::MM' => $ab_version,
        'ExtUtils::MakeMaker' => '6.52',
      ) for qw( configure build );
    }
    else
    {
      $self->zilla->register_prereqs(
        { phase => $_ },
        'Alien::Build::MB' => '0.02',
      ) for qw( configure build );
    }

    # Configure requires...
    $self->zilla->register_prereqs(
      { phase => 'configure' },
      'Alien::Build' => $ab_version,
      %{ $build->requires('configure') },
    );
    
    # Build requires...
    $self->zilla->register_prereqs(
      { phase => 'build' },
      'Alien::Build' => $ab_version,
      %{ $build->requires('any') },
    );
  }
  else
  {
    $self->log_fatal('No alienfile!');
  }
  
}

my $mm_code_prereqs = <<'EOF1';
use Alien::Build::MM;
my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);
EOF1

my $mm_code_postamble = <<'EOF2';
sub MY::postamble {
  $abmm->mm_postamble;
}
EOF2

my $comment_begin  = "# BEGIN code inserted by Dist::Zilla::Plugin::AlienBuild\n";
my $comment_end    = "# END code inserted by Dist::Zilla::Plugin::AlienBuild\n";

sub munge_files
{
  my($self) = @_;

  if($self->_installer eq 'Makefile.PL')
  {
    my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
    my $content = $file->content;
 
    my $ok = $content =~ s/(unless \( eval \{ ExtUtils::MakeMaker)/"$comment_begin$mm_code_prereqs$comment_end\n\n$1"/e;
    $self->log_fatal('unable to find the correct location to insert prereqs')
      unless $ok;
    
    $content .= "\n\n$comment_begin$mm_code_postamble$comment_end\n";
    
    $file->content($content);
  }
  
  elsif($self->_installer eq 'Build.PL')
  {
    my $plugin = first { $_->isa('Dist::Zilla::Plugin::ModuleBuild') } @{ $self->zilla->plugins };
    $self->log_fatal("unable to find [ModuleBuild] plugin") unless $plugin;
    if($plugin->mb_class eq 'Module::Build')
    {
      $self->log('setting mb_class to Alien::Build::MB');
      $plugin->mb_class('Alien::Build::MB');
    }
    else
    {
      if(eval { $plugin->mb_class->isa('Alien::Build::MB') })
      {
        $self->log('mb_class is already a Alien::Build::MB');
      }
      else
      {
        $self->log_fatal("@{[ $plugin->mb_class ]} is not an Alien::Build::MB");
      }
    }
  }
  
  else
  {
    $self->log_fatal('unable to find Makefile.PL or Build.PL');
  }
}

sub metadata {
  my($self) = @_;
  { dynamic_config => 1 };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AlienBuild - Use Alien::Build with Dist::Zilla

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 [AlienBuild]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin is designed to help create L<Alien> modules using
the L<alienfile> and L<Alien::Build> recipe system with L<Alien::Base>.  The
intent is that you will maintain your L<alienfile> as you normally would,
and this plugin will ensure the right prereqs are specified in the C<META.json>
and other things that are easy to get not quite right.

Specifically, this plugin:

=over 4

=item adds prereqs

Adds the C<configure> requirements to your dist C<configure> requires.  It
adds the C<any> requirements from your L<alienfile> to your dist C<build>
requires.

=item adjusts Makefile.PL

Adjusts your C<Makefile.PL> to use L<Alien::Build::MM>.  If you are using
L<ExtUtils::MakeMaker>.

=item sets the mb_class for Build.PL

sets mb_class to L<Alien::Build::MB> on the L<Dist::Zilla::Plugin::ModuleBuild>
plugin.  If you are using L<Module::Build>.

=item turn on dynamic prereqs

Which are used by most L<Alien::Build> based L<Alien> distributions.

=back

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Base>, L<Alien::Build::MM>, L<Alien::Build::MB>,
L<Dist::Zilla::Plugin::AlienBase::Doc>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
