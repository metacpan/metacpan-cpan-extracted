package Dist::Zilla::Plugin::MathInt64;

use Moose;
use Dist::Zilla::File::InMemory;
use ExtUtils::Typemaps;
use File::ShareDir qw( dist_dir );

# ABSTRACT: Include the Math::Int64 C client API in your distribution
our $VERSION = '0.09'; # VERSION


with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::PrereqSource';

has dir => (
  is => 'ro',
);

has typemap => (
  is      => 'ro',
  default => 1,
);

has typemap_path => (
  is      => 'ro',
  default => 'typemap',
);

has _source_dir => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    if(defined $ENV{DIST_ZILLA_PLUGIN_MATH64_TEST})
    {
      require Path::Class::Dir;
      return Path::Class::Dir->new($ENV{DIST_ZILLA_PLUGIN_MATH64_TEST});
    }
    elsif(defined $Dist::Zilla::Plugin::MathInt64::VERSION)
    {
      require Path::Class::Dir;
      return Path::Class::Dir->new(dist_dir('Dist-Zilla-Plugin-MathInt64'));
    }
    else
    {
      require Path::Class::File;
      return Path::Class::File->new(__FILE__)
        ->parent
        ->parent
        ->parent
        ->parent
        ->parent
        ->absolute
        ->subdir('share');
    }
  },
);

sub gather_files
{
  my($self) = @_;
  
  foreach my $source_name (qw( perl_math_int64.c  perl_math_int64.h perl_math_int64_types.h ))
  {
    my $dst = defined $self->dir
    ? join('/', $self->dir, $source_name)
    : $source_name;
  
    $self->log("create $dst");
    $self->add_file(
      Dist::Zilla::File::InMemory->new(
        name    => $dst,
        content => scalar $self->_source_dir->file($source_name)->slurp,
      ),
    );
  }
  
  return unless $self->typemap;
  
  unless(grep { $_->name eq $self->typemap_path } @{ $self->zilla->files })
  {
    $self->log("create " . $self->typemap_path);
    $self->add_file(
      Dist::Zilla::File::InMemory->new(
        name    => $self->typemap_path,
        content => ExtUtils::Typemaps->new->as_string,
      ),
    );
  }
}

sub munge_files
{
  my($self) = @_;
  
  return unless $self->typemap;
  
  my($file) = grep { $_->name eq $self->typemap_path } @{ $self->zilla->files };

  unless(defined $file)
  {
    $self->log_fatal("unable to find " . $self->typemap_path . " which I should have created, perhaps another plugin pruned it?");
  }
  
  $self->log("update " . $self->typemap_path);

  my $typemap = ExtUtils::Typemaps->new(string => $file->content);
  $typemap->merge(
    typemap => ExtUtils::Typemaps->new(
      string => scalar $self->_source_dir->file('typemap')->slurp,
    ),
  );
  $file->content($typemap->as_string);
}

sub register_prereqs
{
  my($self) = @_;
  
  $self->zilla->register_prereqs(
    { type => 'requires', phase => 'runtime' },
    'Math::Int64' => '0.28',
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MathInt64 - Include the Math::Int64 C client API in your distribution

=head1 VERSION

version 0.09

=head1 SYNOPSIS

in your dist.ini

 [PPPort]
 [MathInt64]
 [ModuleBuild]
 mb_class = MyDist::ModuleBuild

in your xs (lib/MyDist.xs):

 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 #include "ppport.h"
 
 /* provides int64_t and uint64_t if not   *
  * already available                      */
 #include "perl_math_int64_types.h"
 
 /* #define MATH_INT64_NATIVE_IF_AVAILABLE */
 #include "perl_math_int64.h"
 
 MODULE = MyDist  PACKAGE = MyDist
 
 int64_t
 function_that_returns_64bit_integer()
 
 void
 function_that_takes_64bit_integer(number)
     int64_t number
 
 SV *
 same_idea_but_with_xs(sv_number)
     SV *sv_number
   CODE:
     int64_t native_number = SvI64(sv_number);
     ...
     RETVAL = newSVi64(native_number);
   OUTPUT:
     RETVAL

See L<Math::Int64#C-API> for details.

in your Module::Build subclass (inc/MyDist/ModuleBuild.pm):

 package MyDist::ModuleBuild;
 
 use base qw( Module::Build );
 
 sub new
 {
   my($class, %args) = @_;
   $args{c_source} = '.';
   $class->SUPER::new(%args);
 }

=head1 DESCRIPTION

L<Math::Int64> provides an API for Perl and XS modules for dealing
with 64 bit integers.

This plugin imports the C client API from L<Math::Int64> into your
distribution.  The C client API depends on ppport.h, so make sure
that you also get that (the easiest way is via the 
L<PPPort plugin|Dist::Zilla::Plugin::PPPort>.

This plugin will also create an appropriate C<typemap> or update
an existing C<typemap> to automatically support the types C<int64_t>
and C<uint64_t> in your XS code.  (You can turn this off by setting
typemap = 0).

This plugin will also declare L<Math::Int64> as a prerequisite for
your distribution.

One thing this plugin does NOT do is, it doesn't tell either
L<Module::Build> or L<ExtUtils::MakeMaker> where to find the C
and XS sources.  One way of doing this would be to create 
your own L<Module::Build> subclass and set the C<c_source> attribute
to where the C header and source code go (see the synopsis above
as an example).

=head1 ATTRIBUTES

=head2 dir

Directory to dump the C source and header files into.
If not specified, they go into the distribution root.
If you use this option you probably need to tell the
L<PPPort plugin|Dist::Zilla::Plugin::PPPort> to put
the C<ppport.h> file in the same place.

 [PPPort]
 filename = xs/ppport.h
 [MathInt64]
 dir = xs

=head2 typemap

If set to true (the default), then create a typemap
file if it does not already exist with the appropriate
typemaps for 64 bit integers, or if a typemap already
exists, add the 64 bit integer mappings.

=head2 typemap_path

The path to the typemap file (if typemap is true).
The default is simply 'typemap'.

=head1 CAVEATS

This plugin uses L<ExtUtils::Typemaps> to munge the typemaps
file, which strips any comments from the typemap file, but
should be semantically identical.  Versions prior to 0.05
did its own parsing but would retain comments.

=head1 BUNDLED SOFTWARE

This distribution comes bundled with C source code placed
in the public domain by Salvador Fandino.

Thanks to Salvador Fandino for writing L<Math::Int64> and
providing a XS / C Client API for other distribution authors.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
