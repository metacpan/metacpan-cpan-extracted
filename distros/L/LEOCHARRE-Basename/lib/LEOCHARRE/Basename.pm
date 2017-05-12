package LEOCHARRE::Basename;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS @ISA $VERSION);
use Exporter;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(basename basename_ext abs_dir abs_loc_or_die abs_path_or_die abs_dir_or_die abs_file abs_file_or_die abs_loc abs_path dirname filename filename_ext filename_only);
%EXPORT_TAGS = ( all => \@EXPORT_OK ); # this was missing \@ a slash, causing errors

sub dirname { my $loc = abs_loc($_[0]); filename($loc); }

*basename_only = \&filename_only;
*basename_ext = \&filename_ext;
*basename = \&filename;

sub filename {
   $_[0] or return;
   $_[0]=~/([^\/]+)\/*$/ or return;
   $1;   
}

sub filename_ext {
   my $f = filename(+shift) or return;
   $f=~/\.([a-z0-9]{1,7})$/i or return;
   my $ext = $1;
   @_ ? _matches_one_of($ext,@_) : $ext;   
}
sub filename_only {
   my $f = filename($_[0]) or return;
   $f=~s/\.([a-z0-9]{1,7})$//i;
   $f;
}

sub abs_loc {
   $_[0] or return; # if left out, returns as if cwd were arg
   my $a = abs_path($_[0]) or return;
   $a=~s/\/[^\/]+\/*$//;
   $a;
}
sub abs_loc_or_die { abs_loc($_[0]) or die }

sub abs_file {
   require Cwd;
   require Carp;
   my $abs = Cwd::abs_path($_[0]) or Carp::cluck("Can't Cwd::abs_path($_[0])") and return;
   -f $abs or Carp::cluck("Not file on disk: '$abs'") and return;
   $abs;
}
sub abs_dir {
   require Cwd;
   require Carp;
   my $abs = Cwd::abs_path($_[0]) or Carp::cluck("Can't Cwd::abs_path($_[0])") and return;
   -d $abs or Carp::cluck("Not dir on disk: '$abs'") and return;
   $abs;
}
sub abs_path {
   require Cwd;
   require Carp;
   my $abs = Cwd::abs_path($_[0]) or Carp::cluck("Can't Cwd::abs_path($_[0])") and return;
   -e $abs or Carp::cluck("Not on disk: '$abs'") and return;
   $abs;
}

sub abs_path_or_die {
   require Cwd;
   require Carp;
   my $abs = Cwd::abs_path($_[0]) or Carp::croak("Can't Cwd::abs_path('$_[0]')");
   -e $abs or Carp::croak("Not on disk: '$abs'");
   $abs;
}
sub abs_file_or_die {
   require Cwd;
   require Carp;
   my $abs = Cwd::abs_path($_[0]) or Carp::croak("Can't Cwd::abs_path('$_[0]')");
   -f $abs or Carp::croak("Not file on disk: '$abs'");
   $abs;
}
sub abs_dir_or_die {
   require Cwd;
   require Carp;
   my $abs = Cwd::abs_path($_[0]) or Carp::croak("Can't Cwd::abs_path('$_[0]')");
   -d $abs or Carp::croak("Not dir on disk: '$abs'");
   $abs;
}

sub _matches_one_of {
   my $string = shift;

   for my $arg ( @_ ){
      ref $arg or (($string eq $arg) ? return 1 : next);

      if (ref $arg eq 'ARRAY'){
            map { ( $string eq $_ ) and return $string } @$arg;
      }

      elsif ( ref $arg eq 'Regexp' ){
            $string=~$arg and return $string;         
      }
   }
   return;
}

1;


__END__

=pod

=head1 NAME

LEOCHARRE::Basename - very basic filename string and path operations such as ext and paths

=head1 SUBS

None exported by default.

All of the subs warn if they do not find something.
All of the subs use Cwd::abs_path() internally, so all symlinks are resolved.

=head2 abs_dir()

Arg is path string.
Checks that it is a dir on disk.
Returns abs path.
Returns undef and warns on fail.

=head2 abs_dir_or_die()

Like abs_dir() but dies on fail.

=head2 abs_file()

Arg is path string.
Checks that it is a file on disk.
Returns abs path.
Returns undef and warns on fail.

=head2 abs_file_or_die()

=head2 abs_loc()

Arg is path string.
Checks that it exists on disk.
Returns abs path to parent directory.
Returns undef on fail.

=head2 abs_loc_or_die() 

=head2 abs_path()

Arg is path string.
Checks that it exists on disk. Returns abs path.
Returns undef on fail.

=head2 abs_path_or_die()

=head2 dirname()

Arg is path string, or string.
Returns name of parent directory.
Returns undef on fail.

=head2 filename() basename()

Arg is path string, or string.
Cleans up and returns filename.
Returns undef on fail.

=head2 filename_ext()

Arg is path string, or string.
Cleans up and returns filename extesion.
Returns undef on fail.

Optional argument is a list or strings to match, an array ref of strings to match, 
or a quoted regex.
Note that the matching is done to the extension, not to the file or path name.

   # returns 'fey':
   filename_ext('tina.fey');

   # returns undef:
   filename_ext('tina');

   # returns undef:
   filename_ext('tina.');

   # returns 'fey':
   filename_ext('tina.fey',qw/fey txt jpg/);

   # returns undef:
   filename_ext('tina.fey',qw/txt jpg/);

   # returns 'fey':
   filename_ext('tina.fey',qr/txt|TXT|fey/);

   # returns undef:
   filename_ext('tina.fey',[qw/txt jpg FEY/]);

   # returns 'fey':
   filename_ext('tina.fey',[qw/txt jpg FEY/]);

   grep { filename_ext( $_,qr/txt/i ) } @filepaths



=head2 filename_only()

Arg is path string, or string.
Cleans up and returns filename without extension.
If it has no extension, returns same arg.
Returns undef on fail.

=head1 BUGS

Please contact the AUTHOR for any issues, suggestions, bugs etc.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) Leo Charre. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This means that you can, at your option, redistribute it and/or modify it under either the terms the GNU Public License (GPL) version 1 or later, or under the Perl Artistic License.

See http://dev.perl.org/licenses/

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Use of this software in any way or in any form, source or binary, is not allowed in any country which prohibits disclaimers of any implied warranties of merchantability or fitness for a particular purpose or any disclaimers of a similar nature.

IN NO EVENT SHALL I BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT LIMITED TO, LOST PROFITS) EVEN IF I HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE

=cut



