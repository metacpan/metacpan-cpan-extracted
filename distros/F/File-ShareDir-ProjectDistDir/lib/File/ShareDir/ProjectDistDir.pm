use 5.006;
use strict;
use warnings;

package File::ShareDir::ProjectDistDir;

our $VERSION = '1.000009';

# ABSTRACT: Simple set-and-forget using of a '/share' directory in your projects root

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY











use Path::IsDev qw();
use Path::FindDev qw(find_dev);
use Sub::Exporter qw(build_exporter);
use File::ShareDir qw();

my ($exporter) = build_exporter(
  {
    exports => [ dist_dir => \&build_dist_dir, dist_file => \&build_dist_file ],
    groups  => {
      all       => [qw( dist_dir dist_file )],
      'default' => [qw( dist_dir dist_file )],
    },
    collectors => [ 'defaults', ],
  },
);
my $env_key = 'FILE_SHAREDIR_PROJECTDISTDIR_DEBUG';

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub _debug($) { }
## use critic

if ( $ENV{$env_key} ) {
  ## no critic (ProtectPrivateVars,TestingAndDebugging::ProhibitNoWarnings)
  no warnings 'redefine';
  *File::ShareDir::ProjectDistDir::_debug = sub ($) {
    *STDERR->printf( qq{[ProjectDistDir] %s\n}, $_[0] );
  };
  $Path::IsDev::DEBUG   = 1;
  $Path::FindDev::DEBUG = 1;
}

## no critic (RequireArgUnpacking)
sub _croak { require Carp; goto &Carp::croak }
sub _carp  { require Carp; goto &Carp::carp }

sub _path { require Path::Tiny; goto &Path::Tiny::path }

sub _need_pathclass {
  for my $package ( q[], q[::File], q[::Dir] ) {
    ## no critic (Variables::RequireInitializationForLocalVars)
    local $@ = undef;
    my $code = sprintf 'require %s%s;1', 'Path::Class', $package;
    ## no critic (BuiltinFunctions::ProhibitStringyEval,Lax::ProhibitStringyEval::ExceptForRequire)
    next if eval $code;
    my $err = $@;
    _carp('Path::Class is not installed.');
    ## no critic (RequireCarping, ErrorHandling::RequireUseOfExceptions)
    die $err;
  }
  return 1;
}
































































































































sub import {
  my ( $class, @args ) = @_;

  my ( undef, $xfilename, undef ) = caller;

  my $defaults = {
    filename   => $xfilename,
    projectdir => 'share',
    pathclass  => undef,
    strict     => undef,
  };

  if ( not @args ) {
    @_ = ( $class, ':all', defaults => $defaults );
    goto $exporter;
  }

  for ( 0 .. $#args - 1 ) {
    my ( $key, $value );
    next unless $key = $args[$_] and $value = $args[ $_ + 1 ];

    if ( 'defaults' eq $key ) {
      $defaults = $value;
      undef $args[$_];
      undef $args[ $_ + 1 ];
      next;
    }
    for my $setting (qw( projectdir filename distname pathclass pathtiny strict )) {
      if ( $key eq $setting and not ref $value ) {
        $defaults->{$setting} = $value;
        undef $args[$_];
        undef $args[ $_ + 1 ];
        last;
      }
    }
  }

  $defaults->{filename}   = $xfilename if not defined $defaults->{filename};
  $defaults->{projectdir} = 'share'    if not defined $defaults->{projectdir};

  if ( defined $defaults->{pathclass} ) {
    _carp( 'Path::Class support depecated and will be removed from a future release.' . ' see Documentation for details' );
    _need_pathclass();
  }

  @_ = ( $class, ( grep { defined } @args ), 'defaults' => $defaults );

  goto $exporter;
}
















































sub _get_defaults {
  my ( $field, $arg, $col ) = @_;
  my $result;
  $result = $col->{defaults}->{$field} if $col->{defaults}->{$field};
  $result = $arg->{$field}             if $arg->{$field};
  return $result;
}

sub _wrap_return {
  my ( $type, $value ) = @_;
  if ( not $type ) {
    return $value unless ref $value;
    return "$value";
  }
  if ( 'pathtiny' eq $type ) {
    return $value if 'Path::Tiny' eq ref $value;
    return _path($value);
  }
  if ( 'pathclassdir' eq $type ) {
    return $value if 'Path::Class::Dir' eq ref $value;
    _need_pathclass;
    return Path::Class::Dir->new("$value");
  }
  if ( 'pathclassfile' eq $type ) {
    return $value if 'Path::Class::File' eq ref $value;
    _need_pathclass;
    return Path::Class::File->new("$value");
  }
  return _croak("Unknown return type $type");
}

our %DIST_DIR_CACHE;

sub _get_cached_dist_dir_result {
  my ( undef, $filename, $projectdir, $distname, $strict ) = @_;
  if ( defined $DIST_DIR_CACHE{$distname} ) {
    return $DIST_DIR_CACHE{$distname};
  }
  _debug( 'Working on: ' . $filename );
  my $dev = find_dev( _path($filename)->parent );

  if ( not defined $dev ) {
    ## no critic (Variables::ProhibitPackageVars)
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    return File::ShareDir::dist_dir($distname);
  }

  my $devel_share_dir = $dev->child($projectdir);

  if ($strict) {
    $devel_share_dir = $devel_share_dir->child( 'dist', $distname );
  }
  if ( -d $devel_share_dir ) {
    _debug( 'ISDEV : exists : <devroot>/' . $devel_share_dir->relative($dev) );
    return ( $DIST_DIR_CACHE{$distname} = $devel_share_dir );
  }
  _debug( 'ISPROD: does not exist : <devroot>/' . $devel_share_dir->relative($dev) );
  ## no critic (Variables::ProhibitPackageVars)
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return File::ShareDir::dist_dir($distname);
}

sub build_dist_dir {
  my ( $class, undef, $arg, $col ) = @_;

  my $projectdir = _get_defaults( projectdir => $arg, $col );
  my $pathclass  = _get_defaults( pathclass  => $arg, $col );
  my $pathtiny   = _get_defaults( pathtiny   => $arg, $col );
  my $strict     = _get_defaults( strict     => $arg, $col );
  my $filename   = _get_defaults( filename   => $arg, $col );

  my $wrap_return_type;

  if ($pathclass) { $wrap_return_type = 'pathclassdir' }
  if ($pathtiny)  { $wrap_return_type = 'pathtiny' }

  my $distname = _get_defaults( distname => $arg, $col );

  if ( not $distname ) {
    return sub {
      my ($udistname) = @_;
      my $distdir = $class->_get_cached_dist_dir_result( $filename, $projectdir, $udistname, $strict );
      return _wrap_return( $wrap_return_type, $distdir );
    };
  }
  return sub {
    my $distdir = $class->_get_cached_dist_dir_result( $filename, $projectdir, $distname, $strict );
    return _wrap_return( $wrap_return_type, $distdir );
  };
}
















































sub build_dist_file {
  my ( $class, undef, $arg, $col ) = @_;

  my $projectdir = _get_defaults( projectdir => $arg, $col );
  my $pathclass  = _get_defaults( pathclass  => $arg, $col );
  my $pathtiny   = _get_defaults( pathtiny   => $arg, $col );

  my $strict   = _get_defaults( strict   => $arg, $col );
  my $filename = _get_defaults( filename => $arg, $col );

  my $distname = _get_defaults( distname => $arg, $col );

  my $wrap_return_type;

  if ($pathclass) { $wrap_return_type = 'pathclassfile' }
  if ($pathtiny)  { $wrap_return_type = 'pathtiny' }

  my $check_file = sub {
    my ( $distdir, $wanted_file ) = @_;
    my $child = _path($distdir)->child($wanted_file);
    return unless -e $child;
    if ( -d $child ) {
      return _croak("Found dist_file '$child', but is a dir");
    }
    if ( not -r $child ) {
      return _croak("File '$child', no read permissions");
    }
    return _wrap_return( $wrap_return_type, $child );
  };
  if ( not $distname ) {
    return sub {
      my ( $udistname, $wanted_file ) = @_;
      my $distdir = $class->_get_cached_dist_dir_result( $filename, $projectdir, $udistname, $strict );
      return $check_file->( $distdir, $wanted_file );
    };
  }
  return sub {
    my ($wanted_file) = @_;
    my $distdir = $class->_get_cached_dist_dir_result( $filename, $projectdir, $distname, $strict );
    return $check_file->( $distdir, $wanted_file );
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ShareDir::ProjectDistDir - Simple set-and-forget using of a '/share' directory in your projects root

=head1 VERSION

version 1.000009

=head1 DETERRENT

B<STOP!>. Before using this distribution, some warnings B<MUST> be considered.

The primary use-case for this module is targeted at development projects that are I<NOT> intended for C<CPAN>.

As such, using it for C<CPAN> is generally a bad idea, and better solutions generally involve the less fragile L<< C<Test::File::ShareDir>|Test::File::ShareDir >>, constraining any magical
behavior exclusively to where it is needed: Tests.

Why?

=over 4

=item * Determining whether or not we are C<dev> during C<runtime> is a perilous heuristic that routinely fails with even slightly unusual file system layouts.

=item * Auto-magical changing of behavior at C<runtime> based on the above leads to many surprising and hard to debug problems.

=back

For these reason, it is dangerous to rely on this distribution while striving to produce quality code.

If this documentation is not sufficient to dissuade you, I must B<strongly implore you> to choose the L<< "strict"|/Strict Mode. >> mechanism,
because that substantially reduces the possibilities with regards to false-positive of potential C<dev> directories.

I have in mind to find a better mechanism to deliver the same objective, but no solutions are forthcoming at this time.

=head1 SYNOPSIS

  package An::Example::Package;

  use File::ShareDir::ProjectDistDir;

  # during development, $dir will be $projectroot/share
  # but once installed, it will be wherever File::Sharedir thinks it is.
  my $dir = dist_dir('An-Example')

Project layout requirements:

  $project/
  $project/lib/An/Example/Package.pm
  $project/share/   # files for package 'An-Example' go here.

You can use a directory name other than 'share' ( Assuming you make sure when
you install that, you specify the different directory there also ) as follows:

  use File::ShareDir::ProjectDistDir ':all', defaults => {
    projectdir => 'templates',
  };

=head1 METHODS

=head2 import

    use File::ShareDir::ProjectDistDir (@args);

This uses L<< C<Sub::Exporter>|Sub::Exporter >> to do the heavy lifting, so most usage of this module can be maximized by
understanding that first.

=over 4

=item * B<C<:all>>

    ->import( ':all' , .... )

Import both C<dist_dir> and C<dist_file>

=item * B<C<dist_dir>>

    ->import('dist_dir' , .... )

Import the dist_dir method

=item * B<C<dist_file>>

    ->import('dist_file' , .... )

Import the dist_file method

=item * B<C<projectdir>>

    ->import( .... , projectdir => 'share' )

Specify what the project directory is as a path relative to the base of your distributions source,
and this directory will be used as a C<ShareDir> simulation path for the exported methods I<During development>.

If not specified, the default value 'share' is used.

=item * B<C<filename>>

    ->import( .... , filename => 'some/path/to/foo.pm' );

Generally you don't want to set this, as its worked out by caller() to work out the name of
the file its being called from. This file's path is walked up to find the 'lib' element with a sibling
of the name of your C<projectdir>.

=item * B<C<distname>>

    ->import( .... , distname => 'somedistname' );

Specifying this argument changes the way the functions are emitted at I<installed C<runtime>>, so that instead of
taking the standard arguments File::ShareDir does, the specification of the C<distname> in those functions is eliminated.

i.e:

    # without this flag
    use File::ShareDir::ProjectDistDir qw( :all );

    my $dir = dist_dir('example');
    my $file = dist_file('example', 'path/to/file.pm' );

    # with this flag
    use File::ShareDir::ProjectDistDir ( qw( :all ), distname => 'example' );

    my $dir = dist_dir();
    my $file = dist_file('path/to/file.pm' );

=item * B<C<strict>>

    ->import( ... , strict => 1 );

This parameter specifies that all C<dist> C<sharedirs> will occur within the C<projectdir> directory using the following layout:

    <root>/<projectdir>/dist/<DISTNAME>/

As opposed to

    <root>/<projectdir>

This means if Heuristics misfire and accidentally find another distributions C<share> directory, it will not pick up on it
unless that C<share> directory also has that layout, and will instead revert to the C<installdir> path in C<@INC>

B<This parameter may become the default option in the future>

Specifying this parameter also mandates you B<MUST> declare the C<DISTNAME> value in your file somewhere. Doing otherwise is
considered insanity anyway.

=item * B<C<defaults>>

    ->import( ... , defaults => {
        filename => ....,
        projectdir => ....,
    });

This is mostly an alternative syntax for specifying C<filename> and C<projectdir>,
which is mostly used internally, and their corresponding other values are packed into this one.

=back

=head3 Sub::Exporter tricks of note.

=head4 Make your own sharedir util

    package Foo::Util;

    sub import {
        my ($caller_class, $caller_file, $caller_line )  = caller();
        if ( grep { /share/ } @_ ) {
            require File::ShareDir::ProjectDistDir;
            File::ShareDir::ProjectDistDir->import(
                filename => $caller_file,
                dist_dir => { distname => 'myproject' , -as => 'share' },
                dist_dir => { distname => 'otherproject' , -as => 'other_share' , projectdir => 'share2' },
                -into => $caller_class,
            );
        }
    }

    ....

    package Foo;
    use Foo::Util qw( share );

    my $dir = share();
    my $other_dir => other_share();

=head2 build_dist_dir

    use File::ShareDir::ProjectDirDir ( : all );

    #  this calls
    my $coderef = File::ShareDir::ProjectDistDir->build_dist_dir(
      'dist_dir' => {},
      { defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } }
    );

    use File::ShareDir::ProjectDirDir ( qw( :all ), distname => 'example-dist' );

    #  this calls
    my $coderef = File::ShareDir::ProjectDistDir->build_dist_dir(
      'dist_dir' => {},
      { distname => 'example-dist', defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } }
    );

    use File::ShareDir::ProjectDirDir
      dist_dir => { distname => 'example-dist', -as => 'mydistdir' },
      dist_dir => { distname => 'other-dist',   -as => 'otherdistdir' };

    # This calls
    my $coderef = File::ShareDir::ProjectDistDir->build_dist_dir(
      'dist_dir',
      { distname => 'example-dist' },
      { defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } },
    );
    my $othercoderef = File::ShareDir::ProjectDistDir->build_dist_dir(
      'dist_dir',
      { distname => 'other-dist' },
      { defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } },
    );

    # And leverages Sub::Exporter to create 2 subs in your package.

Generates the exported 'dist_dir' method. In development environments, the generated method will return a path to the
development directories 'share' directory. In non-development environments, this simply returns C<File::ShareDir::dist_dir>.

As a result of this, specifying the Distribution name is not required during development ( unless in C<strict> mode ), however,
it will start to matter once it is installed. This is a potential avenues for bugs if you happen to name it wrong.

In C<strict> mode, the distribution name is B<ALWAYS REQUIRED>, either at least at C<import> or C<dist_dir()> time.

=head2 build_dist_file

    use File::ShareDir::ProjectDirDir ( : all );

    #  this calls
    my $coderef = File::ShareDir::ProjectDistDir->build_dist_file(
      'dist_file' => {},
      { defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } }
    );

    use File::ShareDir::ProjectDirDir ( qw( :all ), distname => 'example-dist' );

    #  this calls
    my $coderef = File::ShareDir::ProjectDistDir->build_dist_file(
      'dist_file' => {},
      { distname => 'example-dist', defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } }
    );

    use File::ShareDir::ProjectDirDir
      dist_file => { distname => 'example-dist', -as => 'mydistfile' },
      dist_file => { distname => 'other-dist',   -as => 'otherdistfile' };

    # This calls
    my $coderef = File::ShareDir::ProjectDistDir->build_dist_file(
      'dist_file',
      { distname => 'example-dist' },
      { defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } },
    );
    my $othercoderef = File::ShareDir::ProjectDistDir->build_dist_file(
      'dist_file',
      { distname => 'other-dist' },
      { defaults => { filename => 'path/to/yourcallingfile.pm', projectdir => 'share' } },
    );

    # And leverages Sub::Exporter to create 2 subs in your package.

Generates the 'dist_file' method.

In development environments, the generated method will return
a path to the development directories 'share' directory. In non-development environments, this simply returns
C<File::ShareDir::dist_file>.

Caveats as a result of package-name as stated in L</build_dist_dir> also apply to this method.

=begin MetaPOD::JSON v1.0.0

{
    "namespace":"File::ShareDir::ProjectDistDir"
}


=end MetaPOD::JSON

=head1 SIGNIFICANT CHANGES

=head2 1.000000

=head3 Strict Mode.

=head4 Using Strict Mode

    use File::ShareDir::ProjectDistDir ':all', strict => 1;
    use File::ShareDir::ProjectDistDir 'dist_dir' => { strict => 1 };

=head4 Why you should use strict mode

Starting with C<1.000000>, there is a parameter C<strict> that changes
how C<sharedir> resolution performs.

Without strict:

    lib/...
    share/...

With strict

    lib/...
    share/dist/Dist-Name-Here/...

This technique greatly builds resilience to the long standing problem
with "develop" vs "install" heuristic ambiguity.

Here at least,

    dist_dir('Dist-Name')

Will instead fall back to

    @INC/auto/share/dist/Dist-Name

When

    share/dist/Dist-Name

Does not exist.

This means if you have a layout like this:

    <DEVROOT>/inc/<a local::lib path here>
    <DEVROOT>/lib/<development files here>

Then when C<Foo-Bar-Baz> is installed as:

    <DEVROOT>/inc/lib/Foo/Bar/Baz.pm
    <DEVROOT>/inc/lib/auto/share/dist/Foo-Bar-Baz

Then C<Baz.pm> will not see the C<DEVROOT> and assume "Hey, this is development" and then proceed to try finding files in
C<DEVROOT/share>

Instead, C<DEVROOT> must have C<DEVROOT/share/dist/Foo-Bar-Baz> too, otherwise it reverts
to C<DEVROOT/inc/lib/auto...>

=head3 C<Path::Class> interfaces deprecated and dependency dropped.

If you have any dependence on this function, now is the time to get yourself off it.

=head4 Minimum Changes to stay with C<Path::Class> short term.

As the dependency has been dropped on C<Path::Class>, if you have C<CPAN>
modules relying on C<Path::Class> interface, you should now at a very minimum
start declaring

    { requires => "Path::Class" }

This will keep your dist working, but will not be future proof against further changes.

=head4 Staying with C<Path::Class> long term.

Recommended approach if you want to stay using the C<Path::Class> interface:

    use File::ShareDir::... etc
    use Path::Class qw( dir file );

    my $dir = dir( dist_dir('Dist-Name') );

This should future-proof you against anything File::ShareDir may do in the future.

=head3 C<Versioning Scheme arbitrary converted to float>

This change is a superficial one, and should have no bearing on how significant you think this release is.

It is a significant release, but the primary reason for the version change is simply to avoid compatibility issues in
I<versions themselves>.

However, outside that, C<x.y.z> semantics are still intended to be semi-meaningful, just with less C<.> and more C<0> ☺

=head3 C<dev> path determination now deferred to call time instead of C<use>

This was essentially a required change to make C<strict> mode plausible, because strict mode _requires_ the C<distname> to be
known, even in the development environment.

This should not have any user visible effects, but please, if you have any problems, file a bug.

=head3 C<file> component determination wrested from C<File::ShareDir>.

    dist_file('foo','bar')

Is now simply sugar syntax for

    path(dist_dir('foo'))->child('bar')

This should have no side effects in your code, but please file any bugs you experience.

( return value is still C<undef> if the file does not exist, and still C<croak>'s if the file is not a file, or unreadable, but
these may both be subject to change )

=head2 0.5.0 - Heuristics and Return type changes

=head3 New C<devdir> heuristic

Starting with 0.5.0, instead of using our simple C<lib/../share> pattern heuristic, a more
advanced heuristic is used from the new L<< C<Path::FindDev>|Path::FindDev >> and L<< C<Path::IsDev>|Path::IsDev >>.

This relies on a more "concrete" marker somewhere at the top of your development tree, and more importantly, checks for the
existence of specific files that are not likely to occur outside a project root.

C<lib> and C<share> based heuristics were a little fragile, for a few reasons:

=over 4

=item * C<lib> can, and does appear all over UNIX file systems, for purposes B<other> than development project roots.

For instance, have a look in C</usr/>

    /usr/bin
    /usr/lib
    /usr/share  ## UHOH.

This would have the very bad side effect of anything installed in C</usr/lib> thinking its "in development".

Fortunately, nobody seems to have hit this specific bug, which I suspect is due only to C</usr/lib> being a symbolic link on most
x86_64 systems.

=item * C<lib> is also reasonably common within C<CPAN> package names.

For instance:

    lib::abs

Which means you'll have a hierarchy like:

    $PREFIX/lib/lib/abs

All you need for something to go horribly wrong would be for somebody to install a C<CPAN> module named:

    share::mystuff

Or similar, and instantly, you have:

    $PREFIX/lib/lib/
    $PREFIX/lib/share/

Which would mean any module calling itself C<lib::*> would be unable to use this module.

=back

So instead, as of C<0.5.0>, the heuristic revolves around certain specific files being in the C<dev> directory.

Which is hopefully a more fault resilient mechanism.

=head3 New Return Types

Starting with 0.5.0, the internals are now based on L<< C<Path::Tiny>|Path::Tiny >> instead of L<< C<Path::Class>|Path::Class >>,
and as a result, there may be a few glitches in transition.

Also, previously you could get a C<Path::Class::*> object back from C<dist_dir> and C<dist_file> by importing it as such:

    use File::ShareDir::ProjectDistDir
        qw( dist_dir dist_file ),
        defaults => { pathclass => 1 };

Now you can also get C<Path::Tiny> objects back, by passing:

    use File::ShareDir::ProjectDistDir
        qw( dist_dir dist_file ),
        defaults => { pathtiny => 1 };

B<< For the time being, you can still get Path::Class objects back, it is deprecated since 1.000000 >>

( In fact, I may even make 2 specific sub-classes of C<PDD> for people who want objects back, as it will make the C<API> and the
code much cleaner )

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
