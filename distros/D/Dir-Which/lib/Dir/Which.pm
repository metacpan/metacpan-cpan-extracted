package Dir::Which ;

=begin comment

  ======================

          Jacquelin Charbonnel - CNRS/LAREMA
 
  $Id: Which.pm 133 2007-04-04 07:35:27Z jaclin $
  
  ----
 
    Search for entries in a list of directories

  ----
  $LastChangedDate: 2007-04-04 09:35:27 +0200 (Wed, 04 Apr 2007) $ 
  $LastChangedRevision: 133 $
  $LastChangedBy: jaclin $
  $URL: https://svn.math.cnrs.fr/jaclin/src/lib/Dir-Which/Which.pm $
 
  ======================

=end comment

=head1 NAME

Dir::Which - Search for directory entries in a list of directories.

=head1 SYNOPSIS

  use Dir::Which qw/ which /;

  @entries = which(
               -entry => "myprog.conf", 
               -env => "myprog_path", 
               -defaultpath => ".:".$FindBin::Bin.":/etc:/usr/local/etc") ;

=head1 DESCRIPTION

This module searches directory entries (files, dirs, links, named pipes...) in a list of directories specified as a path-like string.

The path string can be specified in an environment variable or as an argument.

=cut

use 5.006;
use Carp;
use warnings;
use strict;

use base qw/ Exporter /;
use vars qw/ $VERSION @EXPORT_OK /;

use File::Spec ;

$VERSION = "0.3" ;

@EXPORT_OK = qw( which );

=head1 EXPORT

=head2 which

=head1 FUNCTION

=head2 which

This fonction takes named arguments :

=over 8

=item -entry (mandatory) 

The name of the searched entry. 

=item -env (optional) 

The name of a environment variable supposed to be a path-like string, and which be used to search the specified entry.
If one or more entries are found in this path, the search ends and returns these values.

=item -defaultpath (optional) 

The path used to search the specified entry, if C<-env> argument is missing, 
or if this environment variable doesn't exist, or if no entry have been found in it. 

=back

=head1 RETURN VALUE

In scalar context, the first match is returned according to the order of the directories
listed in the path string, or undef if no match can be found.

In list context, all matches are returned in the order corresponding to the directories
listed in the path string (and so an empty list if no match is found).

=head1 EXAMPLES

  use Dir::Which qw/ which /;

  $file = which(
               -entry => "myprog.conf", 
               -defaultpath => "/etc:/usr/local/etc"
          ) ;

Searches the absolute name of C<myprog.conf> successivement in the directories
C</etc> and C</usr/local/etc>. Returns the first entry found.

  use Dir::Which qw/ which /;
  use FindBin qw($Bin) ;

  @entries = which(
               -entry => "myprog.d", 
               -defaultpath => ".:".$FindBin::Bin.":/etc:/usr/local/etc"
             ) ;

Returns the absolute names of C<myprog.d> searched in the current directory, the directory which contains the program binary,
C</etc> and C</usr/local/etc>. 

  use Dir::Which qw/ which /;

  $file = which(
               -entry => "myprog.conf", 
               -env => "myprog_path"
          ) ;

Searches the absolute name of C<myprog.conf> in the path stored in the environment variable C<myprog_path>.
Returns the name of the first file found, or C<undef> if no entry found.

  use Dir::Which qw/ which /;
  use FindBin qw($Bin) ;

  $file = which(
               -entry => "myprog.conf", 
               -env => "myprog_path", 
               -defaultpath => ".:".$FindBin::Bin.":/etc:/usr/local/etc"
          ) ;

Searches the absolute name of C<myprog.conf> in the path stored in the environment variable C<myprog_path>. 
If no file has been found, searches successivement in the current directory, the directory which contains the program binary,
C</etc> and C</usr/local/etc>. Returns the name of the first entry found, or C<undef> if no entry found.


=cut

sub which {
  my(%h) = @_ ;

  %h = map { /^-/ ? lc : $_ ;} %h ;
  
  my $file = $h{"-entry"} or croak "error in Dir::Which::which : argument '-entry' is missing" ;

  my @matches = () ;
  if (exists($h{"-env"}))  
  {
    my $env = $h{"-env"} ;
	if (exists($ENV{$env}))
	{
	  my @path = _split($env) ;
	  @matches = _search($file,@path) ;
	}
  }
  
  if (scalar(@matches)>0)
  {
    return wantarray ? @matches : $matches[0] ;
  }

  if (exists($h{"-defaultpath"}))  
  {
    $ENV{"defaultpath_$$"} = $h{"-defaultpath"} ;
	my @path = _split("defaultpath_$$") ;
	@matches = _search($file,@path) ;
  }

  if (scalar(@matches)>0)
  {
    return wantarray ? @matches : $matches[0] ;
  }
  return wantarray ? () : undef ;
}

sub _split
{
  my ($path) = @_ ;
  
  eval { require Env::Path };
  if ($@) 
  {
    # no Env::Path so we just split on :
    return split(/:/, $ENV{$path});
  } 
  else 
  {
    my $lpath = Env::Path->$path;
    return $lpath->List;
  }
}
 
sub _search
{
  my($file,@path) = @_ ;
  my @matches ;
  
    for my $d (@path) {
    # blank means current directory
    $d = File::Spec->curdir unless $d;

    # Create the filename
    my $testfile = File::Spec->catfile( $d, $file);

    # does the file exist?
    next unless -e $testfile ;

    # File looks to be found store it
    push(@matches, $testfile);

    # if we are in a scalar context we do not need to keep on looking
    last unless wantarray();

  }

  # return the result
  if (wantarray) {
    return @matches;
  } else {
    return $matches[0];
  }
}

=head1 NOTES

If C<Env::Path> module is installed it will be used. This allows for
more portability than simply assuming colon-separated paths.

=head1 SEE ALSO

L<File::SearchPath>, L<FindBin>, L<Env::Path>, L<File::Which>.

=head1 AUTHOR

Jacquelin Charbonnel, C<< <jacquelin.charbonnel at math.cnrs.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dir-which at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dir-Which>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dir::Which

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dir-Which>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dir-Which>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dir-Which>

=item * Search CPAN

L<http://search.cpan.org/dist/Dir-Which>

=back

=head1 ACKNOWLEDGEMENTS

C<Dir::Which> is inspired by C<File::SearchPath> written by Tim Jenness.  
Thanks to Tim for allowing me to reuse his idea.

=head1 COPYRIGHT & LICENSE

Copyright Jacquelin Charbonnel E<lt>jacquelin.charbonnel at math.cnrs.frE<gt>

This software is governed by the CeCILL-C license under French law and
abiding by the rules of distribution of free software.  You can  use, 
modify and/ or redistribute the software under the terms of the CeCILL-C
license as circulated by CEA, CNRS and INRIA at the following URL
"http://www.cecill.info". 

As a counterpart to the access to the source code and  rights to copy,
modify and redistribute granted by the license, users are provided only
with a limited warranty  and the software's author,  the holder of the
economic rights,  and the successive licensors  have only  limited
liability. 

In this respect, the user's attention is drawn to the risks associated
with loading,  using,  modifying and/or developing or reproducing the
software by the user in light of its specific status of free software,
that may mean  that it is complicated to manipulate,  and  that  also
therefore means  that it is reserved for developers  and  experienced
professionals having in-depth computer knowledge. Users are therefore
encouraged to load and test the software's suitability as regards their
requirements in conditions enabling the security of their systems and/or 
data to be ensured and,  more generally, to use and operate it in the 
same conditions as regards security. 

The fact that you are presently reading this means that you have had
knowledge of the CeCILL-C license and that you accept its terms.

=cut

