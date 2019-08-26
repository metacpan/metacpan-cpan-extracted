package Interact::Later;

use 5.020;
use strict;
use warnings;


use Storable qw( store retrieve );
use Path::Class qw/dir/;
use Moose;
use Data::UUID;
use File::Find::Rule;
use Data::Printer;

use experimental 'signatures';
no if ( $] >= 5.018 ), 'warnings' => 'experimental';

has 'cache_path' => (
  is      => 'ro',
  isa     => 'Str',
  trigger => sub {

    # The trigger operate a transformation on the relative path that is passed
    # as an argument.
    # $_[0] is the new value
    # $_[1] is the old value
    # See https://stackoverflow.com/a/1415884/954777
    $_[ 0 ]->{ cache_path } = dir( $_[ 1 ] )->absolute->stringify() . '/';
  }
);

has 'file_extension' => (
  is  => 'ro',
  isa => 'Str'
);

sub get_oldest_file_in_cache($self) {
  my @files = File::Find::Rule
    ->file
    ->name( '*' . $self->file_extension );
  p @files;

  # https://stackoverflow.com/a/7585306/954777
}

sub get_all_cache_files_ordered_by_date ($self) {
  my $path_and_pattern = $self->cache_path . '*' . $self->file_extension;
  my @files
    = sort { ( stat $a )[ 10 ] <=> ( stat $b )[ 10 ] } glob $path_and_pattern;
  return @files;
}

sub release_cache($id) { }

sub clean_cache($self) {
  while ( glob $self->cache_path . '*' . $self->file_extension ) {
    unlink $_ or warn("Can't remove $_: $!");
  }

}

sub generate_uuid {
  my $uuid = Data::UUID->new->create_str();
  return $uuid;
}

sub write_data_to_disk ( $self, $data ) {
  if ( not -d $self->cache_path ) {
    mkdir $self->cache_path;
    say 'created cache directory';
  }
  my $uuid = generate_uuid();
  store \$data, $self->cache_path . $uuid . $self->file_extension;
  return $uuid;
}

sub retrieve_data_from_disk($id) {

}


=encoding UTF-8

=head1 NAME

Interact::Later - Delay some tasks for later by dumping their data to disk

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Can be used, for example, when you receive lots of C<POST> requests that you
don't want to proceed right now to save database load.

This module will fastly store the data content on disk (with L<Storable>) without
the need to use a database or a job queue. I believe as Perl is fast at writing
files to disk, we can hope good results. This is an experiment...


    use Interact::Later;

    my $delayer = Interact::Later->new(
      cache_path => 'path/to/cache',
      file_extension => '.dmp'
    );

    $delayer->write_data_to_disk($data);

    # Later...
    # Do it until there are no more files...
    $delayer->get_oldest_file_in_cache();

    # Finally
    $delayer->clean_cache;

=head1 MOTIVATIONS

TODO Telling the story of what happened at work and the situation with
databases, job queues, etc. that got troubled by the large amount of POST
requests.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 ATTRIBUTES

To instantiate a new C<Interacter::Later> delayer, simply pass a hashref
containing a key-value couple containing the following:

=head2 cache_path

C<cache_path> is the relative path to the directory that will contain multiple
cache files. It will be expanded to an absolute path by the L<Moose> trigger and
L<Path::Class>.

Keep it simple, it don't require a C</> in the beginning nor the end, and you
will be able to access it through C<$delayer->class_path>.

  $ pwd
  /home/smonff/later/

  my $delayer = Interact::Later->new( cache_path => 'path/to/cache', ... );
  say $delayer->class_path;
  # /home/smonff/later/path/to/cache/
  # Note it add a / in the end

=head2 file_extension

TODO

=head1 SUBROUTINES/METHODS

=head2 get_oldest_cache_files_ordered_by_date

Retrieve the oldest file in the cache. C<$files[0]> is the oldest,
C<$files[-1]>the newest.

=head2 clean_cache

Flush the cache.

=head2 release_cache

Retrieve a specific file by ID

=head2 generate_uuid

=head2 write_data_to_disk

Writes the cache files to disk using C<Storable>. It also checks that the cache
path exists and if not, it creates it.

Returns the UUID so this way, the caller could re-use it (by placing it in a
queue for example).


=head2 retrieve_data_from_disk


=head1 AUTHOR

Sébastien Feugère, C<< <smonff at riseup.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<interact-later at gitlab.com>, or through
the web interface at L<https://gitlab.com/smonff/interact-later/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Interact::Later


You can also look for information at:

=over 4

=item * Gitlab: Gitlab issues tracker (report bugs here)

L<http://gitlab.com/smonff/Interact-Later>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Interact-Later>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Interact-Later>

=item * Search CPAN

L<http://search.cpan.org/dist/Interact-Later/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Sébastien Feugère.

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

1;    # End of Interact::Later
