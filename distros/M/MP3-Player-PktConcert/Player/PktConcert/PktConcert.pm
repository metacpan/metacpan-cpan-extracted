package MP3::Player::PktConcert;
# ============================================================
# MP3::Player::
#  ____  _    _    ____                          _   
# |  _ \| | _| |_ / ___|___  _ __   ___ ___ _ __| |_ 
# | |_) | |/ / __| |   / _ \| '_ \ / __/ _ \ '__| __|
# |  __/|   <| |_| |__| (_) | | | | (_|  __/ |  | |_ 
# |_|   |_|\_\\__|\____\___/|_| |_|\___\___|_|   \__|
#
#  A Perl OO wrapper to John Seagull's C API to the Intel Pocket Concert
# ============================================================
use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw(
	IPC_CACHE_CLEAN
	IPC_CACHE_DIRTY
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
	IPC_CACHE_CLEAN
	IPC_CACHE_DIRTY
);
our $VERSION = '0.01';

$|++;

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined MP3::Player::PktConcert macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap MP3::Player::PktConcert $VERSION;

# ============================================================
sub delete {
# ============================================================
# Deletes a file from the Intel PocketConcert, if found
	my $self = shift;
	my $file = shift;
	my @tracks = $self->tracks;
	my $regex = $file;
	$regex =~ s/\./\./g;
	my @found = grep { 
		$_->name =~ /$file/ ||
		$_->id eq $file
	} @tracks;

	# if( @found > 1 ) {
	#	print "More than one match for '$file':\n".
	#	map { sprintf("%9d %-40s\n", $_->id, $_->name) } @found;
	# } else {
	#	print "Deleting file '$file'..."
	# }
	
	foreach( @found ) { $self->delete_track( $_->id ); }
}

# ============================================================
sub send {
# ============================================================
# Transfer a file to the Intel PocketConcert
	my $self = shift;
	my $file = shift;
	my $callback = shift;
	my $name;

	$callback = sub { 
		my $sent = shift;
		my $total = shift;
		printf( "%9d bytes out of %9d bytes sent. (%3.1f complete)\r",
			$sent, $total, ($sent/$total)*100 );
	} unless( defined $callback );

	$file = $file.".mp3" unless $file =~ /\.mp3$/;
	unless( -e $file ) {
		print "File \"$file\" does not exist\n";
		return undef;
	}
	my ($free, $total) = $self->usage;
	unless( $free >= -s $file ) {
		print "Not enough free memory\n";
		return undef;
	}

	if( $file =~ /\// ) {
		($name) = $file =~ /\/(.*)$/;
	} else {
		$name = $file;
		$file = "./$file";
	}
	$self->send_tracks( $name, $file, $callback );
	1;
}

# ============================================================
sub tracks {
# ============================================================
# Returns an array of tracks (songs) that are stored in your
# Intel PocketConcert.
	my $self = shift;
	my @tracks;
	$self->reset_tracks;
	while( my $track = $self->next_track ) {
		push @tracks, $track;
	}
	@tracks;
}

1;
__END__

=head1 NAME

MP3::Player::PktConcert - 

A Perl OO wrapper to John Seagull's C API to the Intel Pocket Concert

=head1 SYNOPSIS

  use MP3::Player::PktConcert;
  my $pocket_concert = new MP3::Player::PktConcert;
  my $proc_port = $pocket_concert->mount();
  $pocket_concert->open();
  my @tracks = $pocket_concert->tracks();
  foreach my $track (@tracks) {
	  printf "%4d %-40s %9d\n", $track->id(), $track->name(), $track->size();
  }
  my ($free,$total) = $pocket_concert->usage();
  printf( "%d bytes free out of %d bytes total\n", $free, $total );
  $pocket_concert->close();

=head1 DESCRIPTION

MP3::Player::PktConcert is a Perl wrapper to John Seagull's C API to the
Intel PocketConcert MP3 Player. 

=head1 DEPENDENCIES

This package requires that you have built libusb and libipc. See the 
accompanying README file for more details.

=head2 Exportable constants

  IPC_CACHE_CLEAN
  IPC_CACHE_DIRTY

=head1 AUTHOR

Mike Wong <mike_w3@pacbell.net>

Copyright 2002. All Rights Reserved.

This software is free software and may be modified and/or distributed
under the same terms as Perl itself.

Intel PocketConcert is a trademark of the Intel Corporation.

=head1 SEE ALSO

L<perl>.

=cut
