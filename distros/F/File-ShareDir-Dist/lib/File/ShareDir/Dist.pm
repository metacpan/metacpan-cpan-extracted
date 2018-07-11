package File::ShareDir::Dist;

use strict;
use warnings;
use 5.008001;
use base qw( Exporter );
use File::Spec;

our @EXPORT_OK = qw( dist_share );

# ABSTRACT: Locate per-dist shared files
our $VERSION = '0.06'; # VERSION


# TODO: Works with PAR

our %over;

sub dist_share ($)
{
  my($dist_name) = @_;
  
  $dist_name =~ s/::/-/g;

  local $over{$1} = $2
    if defined $ENV{PERL_FILE_SHAREDIR_DIST} && $ENV{PERL_FILE_SHAREDIR_DIST} =~ /^(.*?)=(.*)$/;

  return File::Spec->rel2abs($over{$dist_name}) if $over{$dist_name};

  my @pm = split /-/, $dist_name;
  $pm[-1] .= ".pm";

  foreach my $inc (@INC)
  {
    my $pm = File::Spec->catfile( $inc, @pm );
    if(-f $pm)
    {
      my $share = File::Spec->catdir( $inc, qw( auto share dist ), $dist_name );
      if(-d $share)
      {
        return File::Spec->rel2abs($share);
      }
      
      if(!File::Spec->file_name_is_absolute($inc))
      {
        my($v,$dir) = File::Spec->splitpath( File::Spec->rel2abs($inc), 1 );
        my @dirs = File::Spec->splitdir($dir);
        if(defined $dirs[-1] && $dirs[-1] eq 'lib')
        {
          pop @dirs; # pop off the 'lib';
          # put humpty dumpty back together again
          my $share = File::Spec->catdir(
            File::Spec->catpath($v,
              File::Spec->catdir(@dirs),
              '',
            ),
            'share',
          );
          
          if(-d $share)
          {
            return $share;
          }
        }
      }

      last;
    }
  }
  
  return;
}

sub import
{
  my($class, @args) = @_;

  my @modify;
  
  foreach my $arg (@args)
  {
    if($arg =~ /^-(.*?)=(.*)$/)
    {
      $over{$1} = $2;
    }
    else
    {
      push @modify, $arg;
    }
  }
  
  @_ = ($class, @modify);
  
  goto \&Exporter::import;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ShareDir::Dist - Locate per-dist shared files

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use File::ShareDir::Dist qw( dist_share );
 
 my $dir = dist_share 'Foo-Bar-Baz';

=head1 DESCRIPTION

L<File::ShareDir::Dist> finds share directories for distributions.  It is similar to L<File::ShareDir>
with a few differences:

=over 4

=item Only supports distribution directories.

It doesn't support perl modules or perl class directories.  I have never really needed anything
other than a per-dist share directory.

=item Doesn't compute filenames.

Doesn't compute files in the share directory for you.  This is what L<File::Spec> or L<Path::Tiny>
are for.

=item Doesn't support old style shares.

For some reason there are two types.  I have never seen or needed the older type.

=item Hopefully doesn't find the wrong directory.

It doesn't blindly go finding the first share directory in @INC that matches the dist name.  It actually
checks to see that it matches the .pm file that goes along with it.

That does mean that you need to have a .pm that corresponds to your dist name.  This is not
always the case for some older historical distributions, but it has been the recommended convention
for quite some time.

=item No non-core dependencies.

L<File::ShareDir> only has L<Class::Inspector>, but since we are only doing per-dist share
directories we don't even need that.

The goal of this project is to have no non-core dependencies for the two most recent production
versions of Perl.  As of this writing that means Perl 5.26 and 5.24.  In the future, we C<may> add
dependencies on modules that are not part of the Perl core on older Perls.

=item Works in your development tree.

Uses the heuristic, for determining if you are in a development tree, and if so, uses the common
convention to find the directory named C<share>.  If you are using a relative path in C<@INC>,
if the directory C<share> is a sibling of that relative entry in C<@INC> and if the last element
in that relative path is C<lib>.

Example, if you have the directory structure:

 lib/Foo/Bar/Baz.pm
 share/data

and you invoke perl with

 % perl -Ilib -MFoo::Bar::Baz -MFile::ShareDir::Dist=dist_share -E 'say dist_share("Foo-Bar-Baz")'

C<dist_share> will return the (absolute) path to ./share/data.  If you invoked it with:

 % export PERL5LIB `pwd`/lib
 perl -MFoo::Bar::Baz -MFile::ShareDir::Dist=dist_share -E 'say dist_share("Foo-Bar-Baz")'

it would not.  For me this covers most of my needs when developing a Perl module with a share
directory.

L<prove> foils this heuristic by making C<@INC> absolute paths.  To get around that you can use
L<App::Prove::Plugin::ShareDirDist>.

=item Built in override.

The hash C<%File::ShareDir::Dist::over> can be used to override what C<dist_share> returns.
You can also override behavior on the command line using a dash followed by a key value pair
joined by the equal sign.  In other words:

 % perl -MFile::ShareDir::Dist=-Foo-Bar-Baz=./share -E 'say File::ShareDir::Dist::dist_share("Foo-Bar-Baz")'
 /.../share

If neither of those work then you can set PERL_FILE_SHAREDIR_DIST to a dist name, directory pair

 % env PERL_FILE_SHAREDIR_DIST=Foo-Bar-Baz=`pwd`/share perl -MFile::ShareDir::Dist -E 'say File::ShareDir::Dist::dist_share("Foo-Bar-Baz")'

For L<File::ShareDir> you have to either mock the C<dist_dir> function or install
L<File::ShareDir::Override>.  For testing you can use L<Test::File::ShareDir>.  I have never
understood why such a simple concept needs three modules to do all of this.

=back

=head1 FUNCTIONS

Functions must be explicitly exported.  They are not exported by default.

=head2 dist_share

 my $dir = dist_share $dist_name;
 my $dir = dist_share $module_name;

Returns the absolute path to the share directory of the given distribution.

As a convenience you can also use the "main" module name associated with the
distribution.  That means if you want the share directory for the dist
C<Foo-Bar-Baz> you may use either C<Foo-Bar-Baz> or C<Foo::Bar::Baz> to find
it.

Returns nothing if no share directory could be found.

=head1 ENVIRONMENT

=over 4

=item PERL_FILE_SHAREDIR_DIST

Can be used to set a single dist directory override.

=back

=head1 CAVEATS

All the stuff that is in L<File::ShareDir> but not in this module could be considered either
caveats or features depending on your perspective I suppose.

=head1 SEE ALSO

=over

=item L<File::ShareDir>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Yanick Champoux (yanick)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
