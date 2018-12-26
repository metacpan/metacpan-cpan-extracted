package Dist::Zilla::Plugin::Alt 0.06 {

  use 5.014;
  use Moose;
  use List::Util qw( first );
  use File::Find ();
  use File::chdir;

  # ABSTRACT: Create Alt distributions with Dist::Zilla


  with 'Dist::Zilla::Role::FileMunger';
  with 'Dist::Zilla::Role::MetaProvider';
  with 'Dist::Zilla::Role::NameProvider';

  sub munge_files
  {
    my($self) = @_;
  
    if(my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files })
    {
      my $content = $file->content;
      my $extra = join "\n", qq{# begin inserted by @{[blessed $self ]} @{[ $self->VERSION || 'dev' ]}},
                          q{my $alt = $ENV{PERL_ALT_INSTALL} || '';},
                          q{$WriteMakefileArgs{DESTDIR} =},
                          q{  $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt';},
                          q<if($^O eq 'MSWin32' && $WriteMakefileArgs{DESTDIR}) {>,
                          q{  # Windows is a precious snowflake that can't handle DESTDIR},
                          q{  # Caveat: this probably ignores any PREFIX specified by the user},
                          q{  require Config;},
                          q{  require File::Spec;},
                          q{  my @prefix = split /:/, $Config::Config{prefix};},
                          q{  $WriteMakefileArgs{PREFIX} = File::Spec->catdir($WriteMakefileArgs{DESTDIR}, @prefix);},
                          q{  delete $WriteMakefileArgs{DESTDIR};},
                          q<}>,
                          qq{# end inserted by @{[blessed $self ]} @{[ $self->VERSION || 'dev' ]}},
                          q{};
      if($content =~ s{^WriteMakefile}{${extra}WriteMakefile}m)
      {
        $file->content($content);
      }
      else
      {
        $self->log_fatal('unable to find WriteMakefile in Makefile.PL');
      }
    }
    elsif($file = first { $_->name eq 'Build.PL' } @{ $self->zilla->files })
    {
      my $content = $file->content;
      my $extra = join "\n", qq{# begin inserted by @{[blessed $self ]} @{[ $self->VERSION || 'dev' ]}},
                             q{my $alt = $ENV{PERL_ALT_INSTALL} || '';},
                             q{$module_build_args{destdir} =},
                             q{  $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt';},
                             q<if($^O eq 'MSWin32' && $module_build_args{destdir}) {>,
                             q{  # Windows is a precious snowflake that can't handle destdir},
                             q{  # Caveat: this probably ignores any PREFIX specified by the user},
                             q{  require Config;},
                             q{  require File::Spec;},
                             q{  my @prefix = split /:/, $Config::Config{prefix};},
                             q{  $module_build_args{PREFIX} = File::Spec->catdir($module_build_args{destdir}, @prefix);},
                             q{  delete $module_build_args{destdir};},
                             q<}>,
                             qq{# end inserted by @{[blessed $self ]} @{[ $self->VERSION || 'dev' ]}},
                             q{};
      if($content =~ s{^(my \$build =)}{$extra . "\n" . $1}me)
      {
        $file->content($content);
      }
      else
      {
        $self->log_fatal('unable to find Module::Build->new in Build.PL');
      }
    }
    else
    {
      $self->log_fatal('unable to find Makefile.PL or Build.PL');
    }
  }

  sub metadata
  {
    my($self) = @_;
    return {
      no_index => {
        file => [ grep !/^lib\/Alt\//, grep /^lib.*\.pm$/, map { $_->name } @{ $self->zilla->files } ],
      },
    };
  }

  sub provide_name
  {
    my($self) = @_;
    local $CWD = $self->zilla->root;
    return unless -d 'lib/Alt';
    my @files;
    File::Find::find(sub { return unless -f; push @files, $File::Find::name }, "lib/Alt");  
    return unless @files;
    $self->log_fatal("found too many Alt modules!") if @files > 1;
    my $name = $files[0];
    $name =~ s/^lib\///;
    $name =~ s/\.pm$//;
    $name =~ s/\//-/g;
    $name;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Alt - Create Alt distributions with Dist::Zilla

=head1 VERSION

version 0.06

=head1 SYNOPSIS

Your dist.ini:

 [GatherDir]
 [MakeMaker]
 [Alt]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin can be added to an existing dist.ini file to
turn your (or someone else's) distribution into an L<Alt> distribution.
What it does is:

=over 4

=item Modifies C<Makefile.PL> or C<Build.PL>

Adds code to change the install location so that your dist won't
be installed unless the environment variable C<PERL_ALT_INSTALL>
is set to C<OVERWRITE>.

=item Updates the no_index meta

So that only C<.pm> files in your lib directory that are in the
C<Alt::> namespace will be indexed.

=item Sets the dist name property

If the name isn't already set in your C<dist.ini> by some other
means, this plugin will set the name based on the Alt module.
If you have more than one Alt module (which would be unusual)
then it is an error unless you set the name by some other means.

=back

=head1 CAVEATS

This plugin should appear in your C<dist.ini> toward the end, or at
least after your C<[GatherDir]> and C<[MakeMaker]> plugins (or equivalent).

=head1 SEE ALSO

=over 4

=item L<Alt>

=item L<Dist::Zilla>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
