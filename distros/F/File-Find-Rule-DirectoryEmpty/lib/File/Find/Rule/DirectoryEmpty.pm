package File::Find::Rule::DirectoryEmpty;
use strict;
use base 'File::Find::Rule';
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)/g;

sub File::Find::Rule::directoryempty {
	my $self = shift->_force_object;


	$self->exec( 
		sub {
			opendir(DIR,+shift) or return;	

         for( readdir DIR ){
            if( !/^\.\.?$/ ){
               closedir DIR;
               return 0;
            }
         }
         closedir DIR;
         return 1;            
		}
	);		
}



1;

__END__

=pod

=head1 NAME

File::Find::Rule::DirectoryEmpty - find empty directories recursively

=head1 SYNOPSIS

	use File::Find::Rule::DirectoryEmpty;
	
	my @emptydirs = File::Find::Rule->directoryempty->in('/home/myself');
   
   # another way..
   
   my $o = new File::Find::Rule;
   $o->directoryempty;
   my @emptydirs = $o->in( $ENV{HOME} );

=head1 Matching Rules

=head2 directoryempty()

Matches only if it is an empty directory.

=head1 DESCRIPTION

This module inherits File::Find::Rule. It lets you find empty directories recursively.
Note that a directory with an empty directory inside it is not an empty directory.

=head2 NOTES

Instead of reading full count of directory contents, we return false as soon as we match
something other then . or .. This helps with speed.

=head1 CAVEATS

This may not work on windows platforms. You're welcome to send in a patch for it. 

=head1 SEE ALSO

L<File::Find::Rule>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.
   
=cut

