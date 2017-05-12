package FFI::CheckLib;

use strict;
use warnings;
use File::Spec;
use Carp qw( croak carp );
use base qw( Exporter );

our @EXPORT = qw(
  find_lib
  assert_lib
  check_lib
  check_lib_or_exit
  find_lib_or_exit
  find_lib_or_die 
);

# ABSTRACT: Check that a library is available for FFI
our $VERSION = '0.15'; # VERSION


our $system_path;
our $os = $ENV{FFI_CHECKLIB_TEST_OS} || $^O;
our $dyna_loader = 'DynaLoader';

if($os eq 'MSWin32')
{
  $system_path = eval q{
    use Env qw( @PATH );
    \\@PATH;
  }; die $@ if $@;
}
else
{
  $system_path = eval q{
    require DynaLoader;
    \\@DynaLoader::dl_library_path;
  }; die $@ if $@;
}

our $pattern = [ qr{^lib(.*?)\.so.*$} ];

if($os eq 'cygwin')
{
  push @$pattern, qr{^cyg(.*?)(?:-[0-9]+)?\.dll$};
}
elsif($os eq 'msys')
{
  # doesn't seem as though msys uses psudo libfoo.so files
  # in the way that cygwin sometimes does.  we can revisit
  # this if we find otherwise.
  $pattern = [ qr{^msys-(.*?)(?:-[0-9]+)?\.dll$} ];
}
elsif($os eq 'MSWin32')
{
  $pattern = [ qr{^(?:lib)?(.*?)(?:-[0-9]+)?\.dll$} ];
}
elsif($os eq 'darwin')
{
  push @$pattern, qr{^lib(.*?)(?:-[0-9\.]+)?\.(?:dylib|bundle)$};
}

sub _matches
{
  my($filename, $path) = @_;
  foreach my $regex (@$pattern)
  {
    return [ $1, File::Spec->catfile($path, $filename) ] if $filename =~ $regex;
  }
  return ();
}


my $diagnostic;

sub find_lib
{
  my(%args) = @_;
  
  undef $diagnostic;
  croak "find_lib requires lib argument" unless defined $args{lib};

  my $recursive = $args{_r} || $args{recursive} || 0;

  # make arguments be lists.
  foreach my $arg (qw( lib libpath symbol verify ))
  {
    next if ref $args{$arg} eq 'ARRAY';
    if(defined $args{$arg})
    {
      $args{$arg} = [ $args{$arg} ];
    }
    else
    {
      $args{$arg} = [];
    }
  }
  
  if(defined $args{systempath} && !ref($args{systempath}))
  {
    $args{systempath} = [ $args{systempath} ];
  }
  
  my @path = @{ $args{libpath} };
  @path = map { _recurse($_) } @path if $recursive;
  push @path, grep { defined } defined $args{systempath}
    ? @{ $args{systempath} }
    : @$system_path;
  
  my $any = 1 if grep { $_ eq '*' } @{ $args{lib} };
  my %missing = map { $_ => 1 } @{ $args{lib} };
  my %symbols = map { $_ => 1 } @{ $args{symbol} };
  my @found;
  
  delete $missing{'*'};

  foreach my $path (@path)
  {
    next unless -d $path;
    my $dh;
    opendir $dh, $path;
    my @maybe = 
      # prefer non-symlinks
      sort { -l $a->[1] <=> -l $b->[1] }
      # filter out the items that do not match
      # the name that we are looking for
      grep { $any || $missing{$_->[0]} }
      # get [ name, full_path ] mapping,
      # each entry is a 2 element list ref
      map { _matches($_,$path) } 
      # read all files from the directory
      readdir $dh;
    closedir $dh;
    
    # TODO: the FFI::Sweet implementation
    # has some aggresive techniques for
    # finding .dlls from .a files that may
    # be worth adopting.
    
    midloop:
    foreach my $lib (@maybe)
    {
      next unless $any || $missing{$lib->[0]};
      
      foreach my $verify (@{ $args{verify} })
      {
        next midloop unless $verify->(@$lib);
      }
      
      delete $missing{$lib->[0]};
      
      foreach my $symbol (keys %symbols)
      {
        next unless do {
          require "$dyna_loader.pm";
          no strict 'refs';
          my $dll = &{"$dyna_loader\::dl_load_file"}($lib->[1],0);
          my $ok = &{"$dyna_loader\::dl_find_symbol"}($dll, $symbol) ? 1 : 0;
          &{"$dyna_loader\::dl_unload_file"}($dll);
          $ok;
        };
        delete $symbols{$symbol};
      }
      
      push @found, $lib->[1];
    }    
  }

  if(%missing)
  {
    my @missing = keys %missing;
    if(@missing > 1)
    { $diagnostic = "libraries not found: @missing" }
    else
    { $diagnostic = "library not found: @missing" }
  }
  elsif(%symbols)
  {
    my @missing = keys %symbols;
    $diagnostic = "symbols not found: @missing";
  }
  
  return if %symbols;
  return $found[0] unless wantarray;
  return @found;
}

sub _recurse
{
  my($dir) = @_;
  return unless -d $dir;
  my $dh;
  opendir $dh, $dir;
  my @list = grep { -d $_ } map { File::Spec->catdir($dir, $_) } grep !/^\.\.?$/, readdir $dh;
  closedir $dh;
  ($dir, map { _recurse($_) } @list);
}


sub assert_lib
{
  croak $diagnostic || 'library not found' unless check_lib(@_);
}


sub check_lib_or_exit
{
  unless(check_lib(@_))
  {
    carp $diagnostic || 'library not found';
    exit;
  }
}


sub find_lib_or_exit
{
  my(@libs) = find_lib(@_);
  unless(@libs)
  {
    carp $diagnostic || 'library not found';
    exit;
  }
  return unless @libs;
  wantarray ? @libs : $libs[0];
}


sub find_lib_or_die
{
  my(@libs) = find_lib(@_);
  unless(@libs)
  {
    croak $diagnostic || 'library not found';
  }
  return unless @libs;
  wantarray ? @libs : $libs[0];
}


sub check_lib
{
  find_lib(@_) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::CheckLib - Check that a library is available for FFI

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use FFI::CheckLib;
  
  check_lib_or_exit( lib => 'jpeg', symbol => 'jinit_memory_mgr' );
  check_lib_or_exit( lib => [ 'iconv', 'jpeg' ] );
  
  # or prompt for path to library and then:
  print "where to find jpeg library: ";
  my $path = <STDIN>;
  check_lib_or_exit( lib => 'jpeg', libpath => $path );

=head1 DESCRIPTION

This module checks whether a particular dynamic library is available for 
FFI to use. It is modeled heavily on L<Devel::CheckLib>, but will find 
dynamic libraries even when development packages are not installed.  It 
also provides a L<find_lib|FFI::CheckLib#find_lib> function that will 
return the full path to the found dynamic library, which can be feed 
directly into L<FFI::Platypus> or L<FFI::Raw>.

Although intended mainly for FFI modules via L<FFI::Platypus> and 
similar, this module does not actually use any FFI to do its detection 
and probing.  This modules does not have any non-core dependencies on 
Perls 5.8-5.18.  On Perl 5.20 and newer it has a configure, build and 
test dependency on L<Module::Build>.

=head1 FUNCTIONS

All of these take the same named parameters and are exported by default.

=head2 find_lib

This will return a list of dynamic libraries, or empty list if none were 
found.

[version 0.05]

If called in scalar context it will return the first library found.

=head3 lib

Must be either a string with the name of a single library or a reference 
to an array of strings of library names.  Depending on your platform, 
C<CheckLib> will prepend C<lib> or append C<.dll> or C<.so> when 
searching.

[version 0.11]

As a special case, if C<*> is specified then any libs found will match.

=head3 libpath

A string or array of additional paths to search for libraries.

=head3 systempath

[version 0.11]

A string or array of system paths to search for instead of letting 
L<FFI::CheckLib> determine the system path.  You can set this to C<[]> 
in order to not search I<any> system paths.

=head3 symbol

A string or a list of symbol names that must be found.

=head3 verify

A code reference used to verify a library really is the one that you 
want.  It should take two arguments, which is the name of the library 
and the full path to the library pathname.  It should return true if it 
is acceptable, and false otherwise.  You can use this in conjunction 
with L<FFI::Platypus> to determine if it is going to meet your needs.  
Example:

 use FFI::CheckLib;
 use FFI::Platypus;
 
 my($lib) = find_lib(
   name => 'foo',
   verify => sub {
     my($name, $libpath) = @_;
     
     my $ffi = FFI::Platypus->new;
     $ffi->lib($libpath);
     
     my $f = $ffi->function('foo_version', [] => 'int');
     
     return $f->call() >= 500; # we accept version 500 or better
   },
 );

=head3 recursive

[version 0.11]

Recursively search for libraries in any non-system paths (those provided 
via C<libpath> above).

=head2 assert_lib

This behaves exactly the same as L<find_lib|FFI::CheckLib#find_lib>, 
except that instead of returning empty list of failure it throws an 
exception.

=head2 check_lib_or_exit

This behaves exactly the same as L<assert_lib|FFI::CheckLib#assert_lib>, 
except that instead of dying, it warns (with exactly the same error 
message) and exists.  This is intended for use in C<Makefile.PL> or 
C<Build.PL>

=head2 find_lib_or_exit

[version 0.05]

This behaves exactly the same as L<find_lib|FFI::CheckLib#find_lib>, 
except that if the library is not found, it will call exit with an 
appropriate diagnostic.

=head2 find_lib_or_die

[version 0.06]

This behaves exactly the same as L<find_lib|FFI::CheckLib#find_lib>, 
except that if the library is not found, it will die with an appropriate 
diagnostic.

=head2 check_lib

This behaves exactly the same as L<find_lib|FFI::CheckLib#find_lib>, 
except that it returns true (1) on finding the appropriate libraries or 
false (0) otherwise.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Call library functions dynamically without a compiler.

=item L<Dist::Zilla::Plugin::FFI::CheckLib>

L<Dist::Zilla> plugin for this module.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
