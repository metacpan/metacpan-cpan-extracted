package File::Find::Rule::UnixPermissions;

use 5.006;
use strict;
use warnings;

use File::Find::Rule;
use base qw(File::Find::Rule);
use Fcntl qw(:mode);

=head1 NAME

File::Find::Rule::UnixPermissions - Use unix permissions for searching for files with File::Find.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS


    use File::Find::Rule::UnixPermissions;
    use Fcntl ':mode';

    # Find all types that are world writable... files, sockets, dirs, etc
    my @world_writeable_drek=File::Find::Rule::UnixPermissions->UnixPermissions(include=>[S_IWOTH])
                                                              ->in('.');

    # Only find files that are world writable
    my @world_writeable_drek=File::Find::Rule::UnixPermissions->file
                                                              ->UnixPermissions(include=>[S_IWOTH])
                                                              ->in('.')

    # Only find files that are world and group writable
    my @world_writeable_drek=File::Find::Rule::UnixPermissions->file
                                                              ->UnixPermissions(include=>[S_IWOTH, S_IWGRP])
                                                              ->in('.')

    # Only find files that are world or group writable
    my @world_writeable_drek=File::Find::Rule::UnixPermissions->file
                                                              ->UnixPermissions(include=>[S_IWOTH, S_IWGRP], any_include=>1)
                                                              ->in('.')

'include' is a array of octal values to match against. These are most easily supplied via Fcntl.

'any_include' is a boolean and setting it to true results in it matching any item in which any
the includes hit.

In regards to the ones below, it is worth noting these will match ANY
permissions even a single one of their respective bits is set.

    S_IRWXG
    S_IRWXO
    S_IRWXU

These will safely match just their respective bits

    S_IRUSR S_IWUSR S_IXUSR
    S_IRGRP S_IWGRP S_IXGRP
    S_IROTH S_IWOTH S_IXOTH

A quick reference table...

    S_IRWXU -> User Read, Write, Execute
    S_IRUSR -> User Read
    S_IWUSR -> User Write
    S_IXUSR -> User Execute

    S_IRWXG -> Group Read, Write, Execute
    S_IRGRP -> Group Read
    S_IWGRP -> Group Write
    S_IXGRP -> Group Execute

    S_IRWXO -> Other Read, Write, Execute
    S_IROTH -> Other Read
    S_IWOTH -> Other Write
    S_IXOTH -> Other Execute

=cut

sub UnixPermissions{
	my $self = shift()->_force_object;
	my %criteria = ref($_[0]) eq "HASH" ? %{$_[0]} : @_;

	if ( ! defined( $criteria{include} ) ){
		die('File::Find::Rule::UnixPermissions - include not specified');
	}

	if ( ! defined( $criteria{any_include} ) ){
		$criteria{any_include}=0;
	}

	$self->exec(sub{
					my $file=shift;

					my $mode=(stat($file))[2];

					#process the include list
					my $include_int=0;
					my $matched=0;
					while( defined( $criteria{include}[$include_int] ) ){
						if ( $mode & $criteria{include}[$include_int] ){
							$matched++;
						}

						$include_int++;
					}
					# return on any include matches
					# this will need to be rewriten post exlude inclusion
					if ( $criteria{any_include} && $matched ){
						return 1;
					}
					# if none of these are matched, no reason to process the exclude list
					if ( ! $matched ){
						return 0;
					}
					#make sure they all matched
					if ( $matched !=  $include_int ){
						return 0;
					}

					return 1;

					# Will finish this all bit when I have more time and not on a clock.
					# #process the exclude list
					# my $exclude_int=0;
					# $matched=0; #reset this
					# while( defined( $criteria{exclude}[$exclude_int] ) ){
					# 	if ( $mode & $criteria{exclude}[$exclude_int] ){
					# 		$matched++;
					# 	}

					# 	$exclude_int++;
					# }
					# # if any_exclude is set, return false on any exclude matching
					# if ( $criteria{any_exclude} &&
					# 	 ( $matched > 0)
					# 	){
					# 	return 0;
					# }
					# #return false if all exclude match
					# if ( $matched ==  $include_int ){
					# 	return 0;
					# }

					# return 1;
				});
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-find-rule-unixpermissions at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-UnixPermissions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Find::Rule::UnixPermissions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Find-Rule-UnixPermissions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Find-Rule-UnixPermissions>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/File-Find-Rule-UnixPermissions>

=item * Search CPAN

L<https://metacpan.org/release/File-Find-Rule-UnixPermissions>

=item * Repository

L<http://gitea.eesdp.org/vvelox/File-Find-Rule-UnixPermissions>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of File::Find::Rule::UnixPermissions
