package File::Archive;
use strict;
use Archive::Tar qw(0.2);
use Compress::Zlib;
$File::Archive::VERSION = '0.53';

sub new	{
	my ($class, $file) = @_;
	my $self = bless {}, $class;

	$self->{filename} = $file;

	# What type of file is it?
	my $name = $self->{filename};
	if ($name=~/\.(tar\.gz|tar\.Z|tgz)$/)	{
		$self->{type}="tarred compressed";
		$self->{type_num} = 1;
	}
	elsif ($name=~/\.(gz|Z)$/)	{
		$self->{type}="compressed";
		$self->{type_num} = 2;
	}
	elsif ($name=~/\.tar$/)	{
		$self->{type}="tarred";
		$self->{type_num} = 3;
	}
	else {
		$self->{type}="plain";
		$self->{type_num} = 4;
	}

	return $self;
}

sub catalog	{
	my ($self) = @_;
	my ($tar);

	#  What's in the file?
	if ($self->{type_num} == 4)	{
		return ($self->{filename});
	}
	elsif ($self->{type_num} == 1 || $self->{type_num} == 3) {
		$tar = Archive::Tar->new();
		return $tar->list_archive($self->{filename});
	}
	else {
		my $name = $self->{filename};
		$name =~ s/\.(Z|gz)$//;
		return $name;
	}
} #  End method catalog

sub member	{
	my ($self, $file) = @_;
	my ($contents, $tar, $gz, $line, $output);

	# What's in the files in the archive?
	if ($self->{type_num} == 4)	{
		open (FILE, $self->{filename});
		undef $/;
		$contents = <FILE>;
		close FILE;
	}
	elsif ($self->{type_num} == 1 || $self->{type_num} == 3) {
		$tar = Archive::Tar->new($self->{filename});
		$contents = $tar->get_content($file);
	}  else  {
		# Actually, there's two things here
		if ($self->{filename} =~ /\.(Z|zip|hqx|bz2?)$/)	{
			$contents = undef;
		} else { # it's a gz file
			$gz=gzopen($self->{filename}, "rb") or die
				"Can't open file: $gzerrno\n";
			while ($gz->gzreadline($line))	{
				$contents .= $line;
			} # Wend
		} # End if..else
	} # End file type test
		
	return $contents;
} # End sub member

sub type	{
	my ($self) = @_;
	return $self->{type};
}

sub filename {
	my ($self) = @_;
	return $self->{filename};
}

# get rid of annoying -w warnings
if ($^W)	{
	$File::Archive::VERSION = $File::Archive::VERSION;
}

1;
__END__

=head1 NAME

File::Archive - Figure out what is in an archive file

=head1 SYNOPSIS

  use File::Archive;
  $arch = File::Archive->new($filename);
  $name = $arch->filename;
  $filelist = $arch->catalog;
  $contents = $arch->member($file);

=head1 DESCRIPTION

Given an archive file of some kind, these methods will determine
what type of archive it is, and tell you what files are contained
in that archive. It will also give you the contents of a particular
file contained in that archive.

This was written for the Scripts section of CPAN, so that users
could upload tarballs, rather than just single-file scripts

=head1 PREREQUISITES

  Compress::Zlib
  Archive::Tar

=head1 AUTHOR

Rich Bowen, <rbowen@rcbowen.com>

=cut
