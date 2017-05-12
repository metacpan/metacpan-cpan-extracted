package Image::Nikon::Index;

#use 5.018002;
use strict;
use warnings;
use Image::ExifTool;

our @ISA = qw();
our $VERSION = '0.01';

# methods
sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = {
		folder => ".", # present working directory
		prefix => $args{'prefix'} || undef,
		suffix => $args{'suffix'} || undef,
		exif   => Image::ExifTool->new,
		tags   => [ 'SubSecDateTimeOriginal', 'ModifyDate' ],
		tree   => undef,
			# tree => {
			#	date => {
			#		key => {
			#			name=>'original name',
			#			code=>'new date code',
			#			index=>'sequence number',
			#		},
			#	},
			# }
		files => undef,
		inityear=> $args{'initialyear'} || 2011,
		debug => $args{'debug'} || 1,
	};
	bless $self, $class;
	return $self;
}

# list directory and populate files
sub _list {
	my ($self)=(@_);
	my @files;

	# always open current directory
	opendir DIR, $self->{'folder'} || die "$!\n";
	@files = readdir DIR;
	closedir DIR;
	chomp @files;

	@files = grep { !/^\.+/ } @files; # ignore hidden files, starting with dot
	@files = grep { /^$self->{'prefix'}/ } @files if defined $self->{'prefix'}; # match prefix
	@files = grep { /$self->{'suffix'}$/ } @files if defined $self->{'suffix'}; # match extension
	$self->{'files'} = \@files;
}

# extract file name and process
sub _file {
	my ($self, %opts)=(@_);
	my %dummy;
	my $f = $opts{'file'};
	my $t = $self->{'exif'};

	$t->ExtractInfo ( $f, \%dummy ) || return; # if not an image, skip.
	#my $value = $t->GetValue('SubSecDateTimeOriginal', 1) || return; # if not an image, skip.
	my $value = $t->GetValue($self->{'tags'}->[0], 1) || return; # if not an image, skip.
	my ($date, $time) = split /\s+/, $value, 2 || die $!;
	my $datestr = $self->_date ($date);

	$date =~ s/\://g;
	$time =~ s/\:|\.//g;
	$time = $date.$time;

	my ($updated) = $t->GetValue($self->{'tags'}->[1], 1);
	$updated =~ s/\:|\s+//g;

	$f =~ s/\_//g;
	$f =~ s/\./\_/g;

	$self->{'tree'}->{$date}->{$time.$updated.$f}->{'name'} = $opts{'file'};
	$self->{'tree'}->{$date}->{$time.$updated.$f}->{'code'} = $datestr;
}

# changing date format
sub _date {
	my ($self, $datestr) = (@_);
	my ($y, $m, $d) = split /:/, $datestr;
	
	$datestr =~ s/^\s+|\s+$//g;
	($y, $m, $d) = split /:/, $datestr;
	$y = chr ( $y - $self->{'inityear'} + ord('A') );
	$datestr = sprintf "%s%1X%02d", $y, $m, $d;
	return $datestr;
}

# indexing
sub _index {
	my ($self, %opts) = (@_);
	my $hash = $opts{'hash'};
	my $i = 1;

	foreach my $key ( sort keys %{$hash} ) {
		$hash->{$key}->{'index'} = sprintf "%03d", $i;
		$i++;
	}
}

# file extension
sub _ext {
	my ($self, $name) = (@_);
	my ($junk, $x) = split /\./, $name;
	return $x;
}

# print all files - key, oldname, newname
sub print {
	my ($self) = (@_);
	my $hash;
	my $newname;

	foreach my $date ( keys %{$self->{'tree'}} ) { 
		print "__".$date."__\n" if $self->{'debug'};
		$hash = $self->{'tree'}->{$date};

		foreach my $key ( sort keys %{$hash} ) {
			$newname = $hash->{$key}->{'code'}."_".$hash->{$key}->{'index'}.".".$self->_ext($hash->{$key}->{'name'});
			print sprintf "  %-45s %-15s %-15s\n", $key, $hash->{$key}->{'name'}, " ".$newname;
		}
	}
}

# rename of each file
sub _rename {
	my ($self, %opts) =(@_);
	rename ($opts{'oldname'}, $opts{'newname'});
}

# mass rename
sub transform {
	my ($self) =(@_);
	my $hash;
	my $newname;

	foreach my $date ( keys %{$self->{'tree'}} ) {
		$hash = $self->{'tree'}->{$date};
		foreach my $key ( sort keys %{$hash} ) {
			$newname = $hash->{$key}->{'code'}."_".$hash->{$key}->{'index'}.".".$self->_ext($hash->{$key}->{'name'});
			print $hash->{$key}->{'name'}." ".$newname."\n" if $self->{'debug'};
			$self->_rename ( oldname=>$hash->{$key}->{'name'}, newname=>$newname );
		}
	}
}

sub process {
	my ($self) = (@_);
	my $list = $self->_list;
	my $hash;

	# create node for each file
	foreach my $f ( @{$list} ) {
		$self->_file (file=>$f);
	}

	# do indexing for each available date
	foreach my $date ( keys %{$self->{'tree'}} ) {
		$hash = $self->{'tree'}->{$date};
		$self->_index (hash=>$hash);
	}
	return $self;
}


1;
__END__

=head1 NAME

Image::Nikon::Index - Perl package for indexing Nikon camera image files

=head1 SYNOPSIS

  use Image::Nikon::Index;
  use Getopt::Long;
  
  my %opts;
  GetOptions ( \%opts, 'folder=s', 'prefix=s', 'suffix=s', 'transform' );
  
  my %args;
  chdir $opts{'folder'} if defined $opts{'folder'};
  
  $args{'prefix'} = $opts{'prefix'} if defined $opts{'prefix'};
  $args{'suffix'} = $opts{'suffix'} if defined $opts{'suffix'};
  
  my $nikon = Image::Nikon::Index->new ( %args );
  $nikon->process->print;
  
  $nikon->transform if defined $opts{'transform'};

=head1 DESCRIPTION

Image::Nikon::Index is a simple package to restructure Nikon format
camera generated image files, which takes up a naming format easy
for indexing and archiving. The package changes default file names
into a format containing date in compact form and indexed in order
of when the photos have been taken.

For a photo taken on 2015 Jun 12 at 8:35:20, which may have been
subsequently modified at a later date or time, the name update is
as below:

  original name: DSC_2019.NEF
  date and time: 2015 Jun 12 at 8:35:20
  subtime  mexp: 30
  updated  time: 2015 Jun 12 at 18:20:10
  image newname: E612_SERIAL.NEF
  
Now, that SERIAL is generated by sorting based on date and time
for which the key is 2015061208352020150612182010, consisting of
original date, time, updated date, time. For frequent use without 
checking what is being changed and how, the following could be handy:

  use Image::Nikon::Index;
  
  chdir $ARGV[0] if defined $ARGV[0];
  my $nikon = Image::Nikon::Index->new (prefix=>'DSC', suffix=>'NEF');
  $nikon->process->transform;
  exit (0);

=head1 SEE ALSO

  Image::ExifTool

=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
