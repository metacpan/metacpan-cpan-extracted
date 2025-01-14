package Dist::Zilla::Plugin::AlienBuild 0.33 {

  use 5.014;
  use Moose;
  use List::Util qw( first );
  use Path::Tiny qw( path );
  use Capture::Tiny qw( capture );
  use Data::Dumper ();

  # ABSTRACT: Use Alien::Build with Dist::Zilla


  with 'Dist::Zilla::Role::FileMunger',
       'Dist::Zilla::Role::MetaProvider',
       'Dist::Zilla::Role::PrereqSource';

  has alienfile_meta => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
  );

  has clean_install => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
  );

  has eumm_hash_var => (
    is      => 'ro',
    isa     => 'Str',
    default => '%WriteMakefileArgs',
  );

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

  has _build => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Alien::Build',
    default => sub {
      my($self) = @_;
      if(my $file = first { $_->name eq 'alienfile' } @{ $self->zilla->files })
      {
        require Alien::Build;
        my $alienfile = Path::Tiny->tempfile;
        $alienfile->spew($file->content);
        my(undef, undef, $build) = capture { Alien::Build->load($alienfile) };
        return $build;
      }
      else
      {
        $self->log_fatal('No alienfile!');
      }
    },
  );

  sub register_prereqs
  {
    my($self) = @_;

    my $prereqs = $self->zilla->prereqs->as_string_hash;

    if($self->clean_install)
    {
      $self->zilla->register_prereqs({
        phase => 'configure',
        type  => 'requires',
      }, 'Alien::Build::MM' => '1.74');
    }

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

    my $build = $self->_build;

    my $ab_version = '0.32';

    foreach my $hook (qw( build_ffi gather_ffi patch_ffi ))
    {
      if($build->meta->has_hook($hook))
      {
        $ab_version = '0.40';
        last;
      }
    }

    if($self->_installer eq 'Makefile.PL')
    {
      my $prereqs = $self->zilla->prereqs;
      my $eumm_version = $prereqs->requirements_for(qw(build requires))
        ->clone
        ->add_requirements($prereqs->requirements_for(qw(configure requires)))
        ->as_string_hash->{'ExtUtils::MakeMaker'} // 0;
      $eumm_version = '6.52' if $eumm_version < '6.52';
      $self->zilla->register_prereqs(
        { phase => $_ },
        'Alien::Build::MM' => $ab_version,
        'ExtUtils::MakeMaker' => $eumm_version,
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

  my $mm_code_postamble = <<'EOF2';
{ package
    MY;
  sub postamble {
    $abmm->mm_postamble(@_);
  }
  sub install {
    $abmm->can('mm_install')
      ? $abmm->mm_install(@_)
      : shift->SUPER::install(@_);
  }
}
EOF2

  my $comment_begin  = "# BEGIN code inserted by @{[ __PACKAGE__ ]}\n";
  my $comment_end    = "# END code inserted by @{[ __PACKAGE__ ]}\n";
  my $postamble_begin  = "# BEGIN postamble code inserted by @{[ __PACKAGE__ ]}\n";
  my $postamble_end    = "# END postamble code inserted by @{[ __PACKAGE__ ]}\n";

  sub munge_files
  {
    my($self) = @_;

    if($self->_installer eq 'Makefile.PL')
    {

      my $mm_code_prereqs = do {

        my %prop;
        $prop{clean_install} = 1 if $self->clean_install;

        # this is overkill atm, but may be useful as we add other properties
        my $prop = %prop
          ? Data::Dumper->new([{ clean_install => 1 }])->Terse(1)->Indent(0)->Dump =~ s/^\{//r =~ s/\}$//r
          : '';

        my $var  = $self->eumm_hash_var;
        my $call = "\$abmm->mm_args($var)";
        if ($var =~ /^[\$]/) {
          $call = "{ \$abmm->mm_args(\%$var) }";
        } elsif ($var !~ /^[\%]/) {
          $self->log_fatal('eumm_hash_var has to start with % or $');
        }

        <<"EOF1";
use Alien::Build::MM;
my \$abmm = Alien::Build::MM->new@{[ $prop ? "($prop)" : '' ]};
$var = $call;
EOF1
      };

      my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
      my $content = $file->content;

      # Reinsert if already inserted.
      my $ok = $content =~ s/\Q$comment_begin\E(.*)\Q$comment_end\E/"$comment_begin$mm_code_prereqs$comment_end"/se;
      if (!$ok) {
        # Insert at new point.
        $ok = $content =~ s/# ALIEN BUILD MM/"$comment_begin$mm_code_prereqs$comment_end\n\n"/e;
      }
      if (!$ok) {
        # Insert at the point 0.32 would insert at.
        $ok = $content =~ s/(unless \( eval \{ ExtUtils::MakeMaker)/"$comment_begin$mm_code_prereqs$comment_end\n\n$1"/e;
      }
      $self->log_fatal('unable to find the correct location to insert prereqs')
        unless $ok;

      $content .= "\n\n$postamble_begin$mm_code_postamble$postamble_end\n"
        unless $content =~ /\Q$postamble_begin\E/;

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
    my %meta = ( dynamic_config => 1 );
    if($self->alienfile_meta)
    {
      $meta{x_alienfile} = {
        generated_by => "@{[ __PACKAGE__ ]} version @{[ __PACKAGE__->VERSION || 'dev' ]}",
        requires => {
          map {
            my %reqs = %{ $self->_build->requires($_) };
            $reqs{$_} = "$reqs{$_}" for keys %reqs;
            $_ => \%reqs;
          } qw( share system )
        },
      }
    }
    \%meta;
  }

  __PACKAGE__->meta->make_immutable;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AlienBuild - Use Alien::Build with Dist::Zilla

=head1 VERSION

version 0.33

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

=item sets x_alienfile meta

Unless you turn this feature off using C<alienfile_meta> below.

=back

=head1 PROPERTIES

=head2 alienfile_meta

As of version 0.23, this plugin adds a special C<x_alienfile> metadata to your
C<META.json> or C<META.yml>.  This contains the C<share> and C<system> prereqs
based on your alienfile.  This may be useful for one day searching for Aliens
which use another specific Alien during their build.  Note that by their nature,
C<share> and C<system> prereqs are dynamic, so on some platforms they may
actually be different.

This is on by default.  You can turn this off by setting this property to C<0>.

=head2 clean_install

Sets the clean_install property on L<Alien::Build::MM>.

=head2 eumm_hash_var

Sets the variable name that is used in the Makefile.PL for its arguments.
Defaults to C<%WriteMakefileArgs>, and is required to begin with C<%> or C<$>.
This is useful when defining your own Makefile template with L<Dist::Zilla::Plugin::MakeMaker::Custom>.

=head1 NOTES

When defining your own Makefile.PL template (to use with
Dist::Zilla::Plugin::MakeMaker::Custom, for example,) you can specify
where you want this module to insert its code by having this line
in the template:

  # ALIEN BUILD MM

An example template to use would be this:

  use ExtUtils::MakeMaker ##{ $eumm_version ##};
  
  my %args = (
    NAME => "My::Alien::Module",
  ##{ $plugin->get_default(qw(ABSTRACT AUTHOR LICENSE VERSION)) ##}
  ##{ $plugin->get_prereqs(1) ##}
  );
  
  # ALIEN BUILD MM
  
  WriteMakefile(%args);

and a dist.ini using this template would include this:

  [MakeMaker::Custom]
  # We need to manipulate %args on-the-fly if we set the version of ExtUtils::MakeMaker any lower.
  eumm_version: 6.64

  [AlienBuild]
  eumm_hash_var: %args

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Base>, L<Alien::Build::MM>, L<Alien::Build::MB>,
L<Dist::Zilla::Plugin::AlienBase::Doc>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curtis Jewell (CSJEWELL)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2025 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
