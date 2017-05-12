package Dist::Zilla::Plugin::Template::Tiny;

use Moose;
use Template::Tiny;
use Dist::Zilla::File::InMemory;
use List::Util qw(first);

# ABSTRACT: process template files in your dist using Template::Tiny
our $VERSION = '0.04'; # VERSION


with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::FileInjector';
with 'Dist::Zilla::Role::FilePruner';

use namespace::autoclean;


has finder => (
  is  => 'ro',
  isa => 'Str',
);


has output_regex => (
  is      => 'ro',
  isa     => 'Str',
  default => '/\.tt$//',
);


has trim => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has var => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);


has replace => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has _munge_list => (
  is      => 'ro',
  isa     => 'ArrayRef[Dist::Zilla::Role::File]',
  default => sub { [] },
);

has _tt => (
  is      => 'ro',
  isa     => 'Template::Tiny',
  lazy    => 1,
  default => sub {
    Template::Tiny->new( TRIM => shift->trim );
  },
);


has prune => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has _prune_list => (
  is      => 'ro',
  isa     => 'ArrayRef[Dist::Zilla::Role::File]',
  default => sub { [] },
);


sub gather_files
{
  my($self, $arg) = @_;

  my $list =
    defined $self->finder 
    ? $self->zilla->find_files($self->finder)
    : [ grep { $_->name =~ /\.tt$/ } @{ $self->zilla->files } ];

  foreach my $template (@$list)
  {
    my $filename = do {
      my $filename = $template->name;
      eval q{ $filename =~ s} . $self->output_regex;
      $self->log("processing " . $template->name . " => $filename");
      $filename;
    };
    my $exists = first { $_->name eq $filename } @{ $self->zilla->files };
    if($self->replace && $exists)
    {
      push @{ $self->_munge_list }, [ $template, $exists ];
    }
    else
    {
      my $file = Dist::Zilla::File::InMemory->new(
        name    => $filename,
        content => do {
          my $output = '';
          my $input = $template->content;
          $self->_tt->process(\$input, $self->_vars, \$output);
          $output;
        },
      );
      $self->add_file($file);
    }
    push @{ $self->_prune_list }, $template if $self->prune;
  }
}

sub _vars
{
  my($self) = @_;
  
  unless(defined $self->{_vars})
  {
  
    my %vars = ( dzil => $self->zilla );
    foreach my $var (@{ $self->var })
    {
      if($var =~ /^(.*?)=(.*)$/)
      {
        my $name = $1;
        my $value = $2;
        for($name,$value) {
          s/^\s+//;
          s/\s+$//;
        }
        $vars{$name} = $value;
      }
    }
    
    $self->{_vars} = \%vars;
  }
  
  return $self->{_vars};
}


sub munge_files
{
  my($self) = @_;
  foreach my $item (@{ $self->_munge_list })
  {
    my($template,$file) = @$item;
    my $output = '';
    my $input = $template->content;
    $self->_tt->process(\$input, $self->_vars, \$output);
    $file->content($output);
  }
  $self->prune_files;
}


sub prune_files
{
  my($self) = @_;
  foreach my $template (@{ $self->_prune_list })
  {
    $self->log("pruning " . $template->name);
    $self->zilla->prune_file($template);
  }
  
  @{ $self->_prune_list } = ();
}


sub mvp_multivalue_args { qw(var) }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Template::Tiny - process template files in your dist using Template::Tiny

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 [Template::Tiny]

=head1 DESCRIPTION

This plugin processes TT template files included in your distribution using
L<Template::Tiny> (a subset of L<Template Toolkit|Template>).  It provides
a single variable C<dzil> which is an instance of L<Dist::Zilla> which can
be queried for things like the version or name of the distribution.

=head1 ATTRIBUTES

=head2 finder

Specifies a L<FileFinder|Dist::Zilla::Role::FileFinder> for the TT files that
you want processed.  If not specified all TT files with the .tt extension will
be processed.

 [FileFinder::ByName / TTFiles]
 file = *.tt
 [Template::Tiny]
 finder = TTFiles

=head2 output_regex

Regular expression substitution used to generate the output filenames.  By default
this is

 [Template::Tiny]
 output_regex = /\.tt$//

which generates a C<Foo.pm> for each C<Foo.pm.tt>.

=head2 trim

Passed as C<TRIM> to the constructor for L<Template::Tiny>.

=head2 var

Specify additional variables for use by your template.  The format is I<name> = I<value>
so to specify foo = 1 and bar = 'hello world' you would include this in your dist.ini:

 [Template::Tiny]
 var = foo = 1
 var = bar = hello world

=head2 replace

If set to a true value, existing files in the source tree will be replaced, if necessary.

=head2 prune

If set to a true value, the original template files will NOT be included in the built distribution.

=head1 METHODS

=head2 $plugin-E<gt>gather_files( $arg )

This method processes the TT files and injects the results into your dist.

=head2 $plugin-E<gt>munge_files

This method is used to munge files that need to be replaced instead of injected.

=head2 $plugin-E<gt>prune_files

This method is used to prune the original templates if the C<prune> attribute is
set.

=head2 $plugin-E<gt>mvp_multivalue_args

Returns list of attributes that can be specified multiple times.

=head1 EXAMPLES

Why would you even need templates that get processed when you build your distribution
anyway?  There are many useful L<Dist::Zilla> plugins that provide mechanisms for
manipulating POD and Perl after all.  I work on Perl distributions that are web apps
that include CSS and JavaScript, and I needed a way to get the distribution version into
the JavaScript.  This seemed to be the clearest and most simple way to go about this.

First of all, I have a share directory called public that gets installed via 
L<[ShareDir]|Dist::Zilla::Plugin::ShareDir>.

 [ShareDir]
 dir = public

Next I use this plugin to process .js.tt files in the appropriate directory, so that
.js files are produced.

 [FileFinder::ByName / JavaScriptTTFiles]
 dir = public/js
 file = *.js.tt
 [Template::Tiny]
 finder = JavaScriptTTFiles
 replace = 1
 prune = 1

Finally, I create a version.js.tt file

 if(PlugAuth === undefined) var PlugAuth = {};
 if(PlugAuth.UI === undefined) PlugAuth.UI = {};
 
 PlugAuth.UI.Name = 'PlugAuth WebUI';
 PlugAuth.UI.VERSION = '[% dzil.version %]';

which gets processed and used when the distribution is built and later installed.  I also
create a version.js file in the same directory so that I can use the distribution without
having to build it.

 if(PlugAuth === undefined) var PlugAuth = {};
 if(PlugAuth === undefined) PlugAuth.UI = {};
 
 PlugAuth.UI.Name = 'PlugAuth WebUI';
 PlugAuth.UI.VERSION = 'dev';

Now when I run it out of the checked out distribution I get C<dev> reported as the version
and the actual version reported when I run from an installed copy.

There are probably other use cases and ways to get yourself into trouble.

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
