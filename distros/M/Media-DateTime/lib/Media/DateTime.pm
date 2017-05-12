package Media::DateTime;

# ABSTRACT: A simple module to extract the timestamp from media files in an flexible manner.

use strict;
use warnings;

our $VERSION = '0.49';

use Carp;
use DateTime;
use Module::Pluggable
  search_path => 'Media::DateTime',
  require     => 1,
  sub_name    => 'matchers';

sub new {
    my $that = shift;
    my $class = ref($that) || $that;    # Enables use to call $instance->new()
    return bless {}, $class;
}

sub datetime {
    my ( $self, $f ) = @_;
    for my $class ( $self->matchers ) {
        if ( $class->match($f) ) {
            my $v = $class->datetime($f);
            return $v if defined $v;
        }
    }
    return $self->_datetime_from_filesystem_stamp($f);
}

sub _datetime_from_filesystem_stamp {
    my ( $self, $f ) = @_;

    my $c_date = ( stat($f) )[9];
    return DateTime->from_epoch( epoch => $c_date, time_zone => 'local' );
}

1;

__END__

=pod

=head1 NAME

Media::DateTime - A simple module to extract the timestamp from media files in an flexible manner.

=head1 VERSION

version 0.49

=head1 SYNOPSIS

  use DateTime;
  use Media::DateTime;
  my $dt = Media::DateTime->datetime( $file );
  
  # or more cleanly OO
  my $dater = Media::DateTime->new;
  my $dt = $dater->datetime( $file );

=head1 DESCRIPTION

Provides a very simple, but highly extensible method of extracting the
creation date and time from a media file (any file really). The base
module comes with support for JPEG files that store the creation date 
in the exif header. 

Plugins can be written to support any file format. See the 
C<Media::DateTime::JPEG> module for an example.

If no plugin is found for a particular file (or the plugin returns 
a false vale) the file creation date as specified by the O/S is used.

Returns a C<DateTime> object.

=head1 METHODs

=over 2

=item new

Constructor that returns a C<Media::DateTime> object. Methods can be
called on either the class or an instance.

	my $dt = Media::DateTime->new;

=item datetime

Takes a file as an arguement and returns a C<DateTime> object representing
its creation date. Falls back to the creation date specified by the 
filesystem if no plugin is available.

	my $dt = Media::DateTime->datetime( $file );
	# or
	my $dt = $dater->datetime( $file );

=back

=head1 SEE ALSO

See the excellent C<DateTime> module which simplifies the handling of dates.
See C<Module::Pluggable> and C<Module::Pluggable::Ordered> which are used
to implement the plugin system. C<Image::Info> is used to extract data from
JPEG files for the C<Media::DateTime::JPEG> plugin.

Make sure you have configured the local time zone on your machine. See
C<DateTime::TimeZone::Local> for information on how the timezone is 
determined.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
