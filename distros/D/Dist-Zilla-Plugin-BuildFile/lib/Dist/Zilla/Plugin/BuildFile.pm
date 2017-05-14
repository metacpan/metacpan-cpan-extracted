package Dist::Zilla::Plugin::BuildFile;
# ABSTRACT: build a custom file by running an external command

use Moose;

BEGIN
  {
    $Dist::Zilla::Plugin::BuildFile::VERSION
      = substr '$$Version: 0.04 $$', 11, -3;
  }

use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);

use Data::Dumper;

with
  ( 'Dist::Zilla::Role::BeforeBuild'
  , 'Dist::Zilla::Role::AfterBuild'
  );

use IPC::Run3;
use Text::Template qw(fill_in_string);
use namespace::autoclean;

sub mvp_multivalue_args { qw(filename target) }

# Public Attributes

has filename   =>
  ( is	       => 'ro'
  , isa	       => 'ArrayRef'
  , required   => 1
  , lazy_build => 1
  );

has target     =>
  ( is	       => 'ro'
  , isa	       => 'ArrayRef'
  , required   => 1
  , lazy_build => 1
  );

has command    =>
  ( is	       => 'ro'
  , isa	       => 'Str'
  , required   => 1
  , lazy_build => 1
  );

has debug      =>
  ( is	       => 'rw'
  , isa	       => 'Bool'
  , default    => 0
  , trigger    => \&_update_debug
  );

has precious   =>
  ( is	       => 'rw'
  , isa	       => 'Bool'
  , default    => 0
  );

# Private Attributes

has _command   =>
  ( is	       => 'rw'
  , isa	       => 'Str'
  , required   => 1
  , lazy_build => 1
  , init_arg   => undef
  );

# Triggers
sub _update_debug
  { my ($self,$arg) = @_;

    $self->log_debug("Setting Debug to $arg");
    $self->logger->set_debug($arg);
    $self->log_debug("Debug now set to $arg");
    return $arg;
  }

# Builders

sub _build_target
  { my $self = shift;

    return [$self->plugin_name];
  }

sub _build_filename
  { my $self = shift;

    return $self->target;
  }

sub _build_command
  { my $self = shift;

    return "make ".join(" ", @{$self->target});
  }

# build a template-expanded version of the command.
sub _build__command
  { my $self = shift;
#    my $module = $self->zilla->main_module;

    my $hash =
      { filenames => $self->filename
      , filename  => ${$self->filename}[0]
      , targets   => $self->target
      , target    => ${$self->target}[0]
#      , module    => $module->name
      };

    return fill_in_string($self->command, HASH => $hash);
  }

# Build all files we'll want to Gather.
sub before_build
  { my ($self, $arg) = @_;

    my $cmd = $self->_command;
    $self->log_debug("About to run: $cmd");
    my $ret = run3($cmd);
    $self->log_fatal("run3 returned $ret") if( !$ret );
    $self->log_fatal("Build command returned error code $?") if( $? );

    my @missing = grep { ! -e } @{$self->filename};
    $self->log_fatal("Some files did not build: ".join(", ",@missing))
      if @missing;
    return;
  }

sub after_build
  { my ($self) = @_;

    return if $self->precious;
    foreach ( @{$self->filename} )
      {
	$self->log_debug("unlinking $_");
	unlink $_;
      }
  }

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::BuildFile - build files by running an external command

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your F<dist.ini>:

  [BuildFile / Readme ]

  [BuildFile / MyModule.pod ]
  command = podextract MyModule.pm >{{$target}}

  [BuildFile]
  target = first long name.txt
  target = second long name.txt

=head1 DESCRIPTION

During the 'BeforeBuild' phase of execution, this plugin creates or
updates one or more files and tests that they now exist. Later, during
the 'AfterBuild' phase of execution the created or updated files are
deleted, unless the 'precious' configuration option was used.

Note that this plugin only generates the files on demand. In order to
put them into the distribution, a FileGatherer such as GatherDir must
also be run.

The file(s) are built by running an external command specified with
the 'command =' configuration parameter. By default that command runs
'make' with the list of targets specified with the 'target = '
configuration parameter. If not specified, the list of targets
contains a single item which is the name of the plugin.

Provided the command runs successfully, the list of files specified
with the 'filename =' configuration parameter is now tested to see if
they exist, and an error is generated if any of the files are
missing. If not specfied, the list of files to check for is the same
as the list of targets.

Thus, by itself, the section specifier of:

    [BuildFile / Readme ]

has a BuildFile section name of 'Readme' which becomes the target file
to build, so that the command 'make Readme' gets executed. Then a test
is run to ensure that a file named 'Readme' now exists.

=head1 ATTRIBUTES

=head2 target

This attribute can appear multiple times and each time it names a
target that needs to be built in order to generate the desired list of
files to install in the distribution. If not specified, the list of
targets is assumed to be just a single item with the same name as the
plugin.

=head2 filename

This attribute can appear multiple times and each time it names a file
that should exist as a result of this Plugin. After running the generating
command, these files are checked for, and if they are not all present
then an error is generated. If not specified, then the list of files
is assumed to be the same as the list of targets.

=head2 command

This attribute gives the command that will be run to generate the
desired filenames. The command is expanded by Text::Template, and the
results are executed by IPC::Run3.

The command substitution uses the substitution delimeters of F<'{{'> and
F<'}}'>, and has the following variables that can be expanded:

=over 4

=item B<@filenames> - The list of filenames

=item B<@targets>   - The list of targets

=item B<$target>    - The first target in the list of targets

=item B<$filename>  - The first filename in the list of filenames

=back

If not specified, the default command is F<"make {{@targets}}">.

=head1 AUTHOR

Stirling Westrup <swestrup@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stirling Westrup.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
