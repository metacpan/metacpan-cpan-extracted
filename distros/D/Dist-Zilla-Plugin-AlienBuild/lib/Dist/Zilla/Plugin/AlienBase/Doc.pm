package Dist::Zilla::Plugin::AlienBase::Doc 0.27 {

  use 5.014;
  use Moose;
  use Carp ();

  # ABSTRACT: Generate boilerplate documentation for Alien::Base subclass


  with 'Dist::Zilla::Role::FileMunger';
  with 'Dist::Zilla::Role::FileFinderUser' => { default_finders => [ ':InstallModules', ':ExecFiles' ] };
  with 'Dist::Zilla::Role::PPI';
  with 'Dist::Zilla::Role::TextTemplate';

  use Sub::Exporter::ForMethods 'method_installer';
  use Data::Section 0.004 # fixed header_re
      { installer => method_installer }, '-setup';


  has class_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      my $name = $self->zilla->name;
      $name =~ s{-}{::};
      $name;
    },
  );


  has min_version => (
    is      => 'ro',
    isa     => 'Str',
    default => '0',
  );


  has type => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [ 'library' ] },
  );

  has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
  );


  has see_also => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [ 'Alien', 'Alien::Base', 'Alien::Build::Manual::AlienUser' ] },
  );

  around mvp_multivalue_args => sub {
    my($orig, $self) = @_;
    ($self->$orig, 'type', 'see_also');
  };

  sub render_synopsis
  {
    my($self) = @_;

    my $str = "\n=head1 SYNOPSIS";

    foreach my $type (@{ $self->type })
    {
      my $template;

      if($type eq 'library')
      {
        $template = $self->section_data('__SYNOPSIS_LIBRARY__')
      }
      elsif($type eq 'tool')
      {
        $template = $self->section_data('__SYNOPSIS_TOOL__')
      }
      elsif($type eq 'ffi')
      {
        $template = $self->section_data('__SYNOPSIS_FFI__')
      }
      else
      {
        Carp::croak("unknown type: $type");
      }

      $template = $$template;
      $template =~ s{\s*$}{};

      $str .= "\n\n";
      $str .= $self->fill_in_string($template, {
        class      => $self->class_name,
        name       => $self->name,
        version    => $self->min_version,
        optversion => $self->min_version ? " @{[ $self->min_version ]}" : '',
      });
    }

    $str .= "\n\n=cut\n\n";

    $str;
  }

  sub render_description
  {
    my($self) = @_;

    my $template = $self->section_data('__DESCRIPTION__');

    $template = $$template;
    $template =~ s{\s*$}{};

    my $str = "\n";

    $str .= $self->fill_in_string($template, {
      class      => $self->class_name,
      name       => $self->name,
      version    => $self->min_version,
      optversion => $self->min_version ? " @{[ $self->min_version ]}" : '',
    });

    $str .= "\n\n";

    $str;
  }

  sub render_see_also
  {
    my($self) = @_;

    my $str = "\n=head1 SEE ALSO\n\n";
    $str .= join ', ', map { "L<$_>" } @{ $self->see_also };
    $str .= "\n\n=cut\n\n";

    $str;
  }

  sub munge_files
  {
    my($self) = @_;
    $self->munge_file($_) for @{ $self->found_files };
    return;
  }

  sub munge_file
  {
    my($self, $file) = @_;

    my $doc = $self->ppi_document_for_file($file);

    return unless defined $doc;

    my $comments = $doc->find('PPI::Token::Comment');
    my $modified = 0;

    foreach my $comment (@{ $comments || [] })
    {
      if($comment =~ /^\s*##?\s*ALIEN (SYNOPSIS|DESCRIPTION|SEE ALSO)\s*$/)
      {
        my $type = $1;
        if($type eq 'SYNOPSIS')
        {
          $comment->set_content($self->render_synopsis);
        }
        elsif($type eq 'DESCRIPTION')
        {
          $comment->set_content($self->render_description);
        }
        elsif($type eq 'SEE ALSO')
        {
          $comment->set_content($self->render_see_also);
        }
        $modified = 1;
      }
    }

    if($modified)
    {
      $self->save_ppi_document_to_file( $doc, $file);
      $self->log_debug([ 'adding ALIEN documentation to %s', $file->name ]);
    }

    return;
  }

  __PACKAGE__->meta->make_immutable;

}

package Dist::Zilla::Plugin::AlienBase::Doc;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AlienBase::Doc - Generate boilerplate documentation for Alien::Base subclass

=head1 VERSION

version 0.27

=head1 SYNOPSIS

In your dist.ini:

 [AlienBase::Doc]
 name = libfoo

In your Alien/Foo.pm:

 package Alien::Foo;
 
 use strict;
 use warnings;
 use base qw( Alien::Base );
 
 # ALIEN SYNOPSIS
 # ALIEN DESCRIPTION
 # ALIEN SEE ALSO
 
 1;

=head1 DESCRIPTION

This plugin generates some boiler plat documentation for your
L<Alien::Base> based L<Alien> module.  It will find the special codes
C<ALIEN SYNOPSIS>, C<ALIEN DESCRIPTION>, and C<ALIEN SEE ALSO> and
replace them with the appropriate boilerplate POD documentation for how
to use the module.  The generated synopsis and see also sections are
probably good enough as is.  The description is a little more basic, and
you may want to write a more detailed description yourself.  It is, at
least, better than nothing though!

=head1 ATTRIBUTES

=head2 class_name

The name of the L<Alien::Base> subclass.  The default is based on the
distribution's main module.

=head2 min_version

The minimum version to suggest using as a prereq.

=head2 type

Types of the L<Alien>.  This can be specified multiple times.  Valid types:

=over 4

=item library

=item tool

=item ffi

=back

=head2 see_also

List of modules to refer to in the C<SEE ALSO> section.  By default this is

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<Alien::Build::Manual::AlienUser>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__[ __SYNOPSIS_LIBRARY__ ]__
In your Build.PL:

 use Module::Build;
 use {{ $class }};
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     '{{ $class }}' => '{{ $version }}',
     ...
   },
   extra_compiler_flags => {{ $class }}->cflags,
   extra_linker_flags   => {{ $class }}->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use {{ $class }};
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     '{{ $class }}' => '{{ $version }}',
   },
   CCFLAGS => {{ $class }}->cflags . " $Config{ccflags}",
   LIBS    => [ {{ $class }}->libs ],
   ...
 );

__[ __SYNOPSIS_FFI__ ]__
In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use {{ $class }}{{ $optversion }};
 
 my $ffi = FFI::Platypus->new(
   lib => [ {{ $class }}->dynamic_libs ],
 );

__[ __SYNOPSIS_TOOL__ ]__
In your script or module:

 use {{ $class }}{{ $optversion }};
 use Env qw( @PATH );
 
 unshift @PATH, {{ $class }}->bin_dir;

__[ __DESCRIPTION__ ]__
=head1 DESCRIPTION

This distribution provides {{ $name }} so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of {{ $name }} on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=cut
