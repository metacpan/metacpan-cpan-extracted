package File::EmptyDirs;
use strict;
use Carp;
require Exporter;
use vars qw/@ISA @EXPORT_OK $VERSION/;
use File::Find::Rule::DirectoryEmpty;
use Cwd;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/remove_empty_dirs/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;

sub remove_empty_dirs {
	my $abs = shift;
	-d $abs or Carp::cluck("argument [$abs] is not a dir.") and return;

   my @empty_dirs_removed;


	my $found_empty_subdirs=1; # startflag  
	while ($found_empty_subdirs){
	   $found_empty_subdirs=0; # assume we will not find empty subdirs to continue with
		 
		my @empty_dirs = File::Find::Rule::DirectoryEmpty->directoryempty->in($abs) ;

      EMPTY_DIR: for my $d (@empty_dirs){
         
         next if (Cwd::abs_path($d) eq Cwd::abs_path($abs));

         $found_empty_subdirs++;	
         
         rmdir($d) 
            or Carp::cluck("cannot rmdir '$d', check permissions? '$!'")
            and next EMPTY_DIR;

         push @empty_dirs_removed, $d;            
      }
	}

   wantarray ? ( @empty_dirs_removed ) : ( scalar @empty_dirs_removed );

}

1;

__END__

=pod

=head1 NAME

File::EmptyDirs - find all empty directories in a path and remove recursively

=head1 SYNOPSIS

	use File::EmptyDirs 'remove_empty_dirs';
   
	my @abs_dirs_removed = remove_empty_dirs('/home/myself');
   
   my $count_removed = remove_empty_dirs('/home/otherself');

=head1 DESCRIPTION

Ever end up with some miscellaneous empty directories in a messy filesystem and you
just want to clean up all empty dirs?

For example.. If you have..

   /home/myself/tp/this/nada

And the only thing in this is 'nada', and 'nada' does not contain anything, you'd like
to remove both of those. This is what to use.
Remove empty directories recursively.

Nothing exported by default.

The operation  is self exclusive, that is, if you pass dir /home/myself, it will not
delete /home/myself if it is an empty dir.

=head1 SUBS

=head2 remove_empty_dirs()

Argument is an abs path to a directory.
Will remove all empty directories within that filesystem hierarchy, recursively.

Returns number of dirs removed in scalar context.
In list context, returns abs paths to dirs removed.

Returns undef on failure.

=head1 SEE ALSO

L<File::Find::Rule::DirectoryEmpty> - used internally to find the empty dirs.
L<IO::All>, might want to check this out.
L<ermdir>, included cli.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2010 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

