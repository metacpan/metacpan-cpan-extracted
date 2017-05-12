package Mac::Path::Util;
use strict;

use warnings;
no warnings;

use base qw(Exporter);
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Cwd qw(getcwd);
use Exporter;

@EXPORT_OK   = qw(DARWIN MACOS);
%EXPORT_TAGS = (
	'system' => [ qw(DARWIN MACOS) ],
	);
$VERSION = '1.001';

my $Startup;

=encoding utf8

=head1 NAME

Mac::Path::Util - convert between darwin and Mac paths

=head1 SYNOPSIS

	use Mac::Path::Util;

	my $path     = Mac::Path::Util->new( "/Users/foo/file.txt" );
	my $mac_path = $path->mac_path;

=head1 DESCRIPTION

THIS IS ALPHA SOFTWARE.  SOME THINGS ARE NOT FINISHED.

Convert between darwin (unix) and Mac file paths.

This is not as simple as changing the directory separator. The Mac path
has the volume name in it, whereas the darwin path leaves off the
startup volume name because it is mounted as /.  Mac::Path::Util can
optionally use Mac::Carbon to determine the real startup volume name
(off by default) if you have installed Mac::Carbon.  You can use
this module on other platforms too.  Once the module has looked up the
volume name, it caches it.  If you want to reset the cache, use the
clear_startup() method.

Colons ( ":" ) in the darwin path become / in the Mac path, and forward
slashes in the Mac path become colons in the darwin path.

Mac paths do not have a leading directory separator for absolute paths.

Normally, Mac paths that end in a directory name have a trailing colon,
but this module cannot necessarily verify that since you may want to
convert paths.

=head2 Methods

=over 4

=cut

use constant DARWIN    => 'darwin';
use constant MACOS     => 'macos';

use constant DONT_KNOW => "Don't know";
use constant BAD_PATH  => "Bad Path";

use constant TRUE      => 'true';
use constant FALSE     => 'false';

use constant LOCAL     => 'local';
use constant REMOTE    => 'remote';

use constant STARTUP   => 'Startup';

=item new( PATH [, HASH ] )

The optional anonymous hash can have these values:

	type      DARWIN or MACOS (explicitly state which sort of path
                 with these symbolic constants)
	startup   the name of the startup volume (if not defined, tries to use
                 the startup volume on the local machine)

=cut

sub new {
	my $class = shift;
	my $path  = shift;
	my $args  = shift;

	my $type  = DONT_KNOW
		unless ( $args->{type} && ( $args->{type} eq DARWIN
			or $args->{type} eq MACOS ) );

	my $self = {
		starting_path   => $path,
		type            => $type,
		path            => $path,
		use_carbon      => ( $^O eq 'darwin' or $^O =~ /MacOS/ ),
		};

	bless $self, $class;

	$self->{startup} = $args->{startup} || undef;

	$self->_identify;

	return if $self->{type} eq BAD_PATH;

	# we know that there is at least one colon in the path
	# if the type is MACOS
	if( $self->type eq MACOS ) {
		$self->{mac_path} = $self->path;

		# absolute paths do not start with colons
		if( index( $self->path, 0, 1 ) ne ":" ) {
			my( $volume )= $self->path =~ m/^(.+?):/g;

			$self->{volume} = $volume;
			}
		else {
			$self->{volume}  = $self->_get_startup;
			$self->{startup} = $self->volume
				if $self->_is_startup( $self->{volume} ) eq TRUE;
			}
		}
	elsif( $self->type eq DARWIN ) {
		$self->{darwin_path} = $self->path;

		if( index( $self->path, 0, 1 ) eq "/" ) {
			$self->{volume} = $self->path =~ m|^/Volumes/(.*?)/?|g;
			}

		unless( defined $self->volume ) {
			$self->{volume}  = $self->_get_startup;
			$self->{startup} = $self->volume
				if $self->_is_startup( $self->{volume} ) eq TRUE;
			}

		$self->_darwin2mac;
		}


	return $self;
	}

=back

=head2 Accessor methods

=over 4

=item type

=item path

=item volume

=item startup

=item mac_path

=item darwin_path

=back

=cut

sub type            { return $_[0]->{type}        }
sub path            { return $_[0]->{path}        }
sub volume          { return $_[0]->{volume}      }
sub startup         { return $_[0]->{startup}     }
sub mac_path        { return $_[0]->{mac_path}    }
sub darwin_path     { return $_[0]->{darwin_path} }

=head2 Setter methods

=over 4

=item use_carbon( [ TRUE | FALSE ] )

Mac::Path::Util will try to use Mac::Carbon to determine the real
startup volume name if you pass this method a true value and you
have Mac::Carbon installed.  Otherwise it will use a default
startup volume name.

=cut

sub use_carbon {
	my $self = shift;

	$self->{use_carbon} = $_[0] ? 1 : 0;

	$self->clear_startup
	}

sub _d2m_trans {
	my $name = shift;

	$name =~ tr|/:|:/|;

	return $name;
	}

sub _darwin2mac {
	my $self = shift;

	my $name = $self->{starting_path};

	$self->{mac_path} = do {
		# is this a relative url?
		if(    substr( $name, 0, 1 ) ne "/" ) {
			my $path = ":" . _d2m_trans( $name );
			$path;
			}
		# is this an absolute url with another Volume?
		elsif( $name =~ m|^/Volumes/([^/]+)(/.*)| ) {
			my $volume = $1;
			my $path   = $2;

			$path = _d2m_trans( $path );

			my $abs = $volume .  $path;
			}
		# absolute path off of startup volume?
		elsif( substr( $name, 0, 1 ) eq "/" ) {
			my $volume = $self->_get_startup;

			my $path = _d2m_trans( $name );

			my $abs = $volume . $path;
			}
		};

	return $self->{mac_path};
	}

sub _mac2darwin {
	my $self = shift;
	my $name = shift;

	$name =~ tr|/:|:/|;

	return $name;
	}

sub _identify {
	my $self = shift;

	my $colons = 0;
	my $slashes = 0;

	if ( defined $self->{starting_path} ) {
		$colons  = $self->{starting_path} =~ tr/://;
		$slashes = $self->{starting_path} =~ tr|/||;
		}

	if(    $colons == 0 and $slashes == 0 ) {
		$self->{type} = DONT_KNOW;
		}
	elsif( $colons != 0 and $slashes == 0 ) {
		$self->{type} = MACOS;
		}
	elsif( $colons == 0 and $slashes != 0 ) {
		$self->{type} = DARWIN;
		}
	elsif( $colons != 0 and $slashes != 0 ) {
		$self->{type} = DONT_KNOW;
		}

	}

=item clear_startup

Clear the cached startup volume name. The next lookup will
reset the cache.

=cut

sub clear_startup {
	my $self = shift;

	delete $self->{startup} if ref $self;
	$Startup = undef;
	}

sub _get_startup {
	my $self = shift;

	return $self->startup if defined $self->startup;
	return $Startup if defined $Startup;

	my $volume = do {
		if( $self->{use_carbon} and eval { require MacPerl } ) {
			(my $volume = scalar MacPerl::Volumes()) =~ s/^.+?:(.+)$/$1/;
			$volume;
			}
		else {
			STARTUP;
			}
		};

	#print STDERR "I think the startup volume is [$volume]\n";

	$Startup = $self->{startup} = $volume;

	return $volume;
	}

sub _is_startup {
	my $self = shift;
	my $name = shift;

	$self->_get_startup unless defined $self->startup;

	$name eq $Startup ? TRUE : FALSE;
	}

=back

=head1 SOURCE AVAILABILITY

This source is on GitHub:

	https://github.com/briandfoy/mac-path-util

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"See why 1984 won't be like 1984";
