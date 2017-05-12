package File::Download;

# use 'our' on v5.6.0
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

$DEBUG = 0;
$VERSION = '0.3';

use base qw(Class::Accessor);
File::Download->mk_accessors(qw(mode overwrite outfile flength size status user_agent));

# We are exporting functions
use base qw/Exporter/;

# Export list - to allow fine tuning of export table
@EXPORT_OK = qw( download );

use strict;
use LWP::UserAgent ();
use LWP::MediaTypes qw(guess_media_type media_suffix);
use URI ();
use HTTP::Date ();

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;  # autoflush

sub download {
    my $self = shift;
    my ($url) = @_;
    my $file;
    $self->{user_agent} = LWP::UserAgent->new(
	agent => "File::Download/$VERSION ",
	keep_alive => 1,
	env_proxy => 1,
	) if !$self->{user_agent};
    my $ua = $self->{user_agent};
    my $res = $ua->request(HTTP::Request->new(GET => $url),
      sub {
	  $self->{status} = "Beginning download\n";
	  unless(defined $file) {
	      my ($chunk,$res,$protocol) = @_;

	      my $directory;
	      if (defined $self->{outfile} && -d $self->{outfile}) {
		  ($directory, $self->{outfile}) = ($self->{outfile}, undef);
	      }

	      unless (defined $self->{outfile}) {
		  # find a suitable name to use
		  $file = $res->filename;
		  # if this fails we try to make something from the URL
		  unless ($file) {
		      my $req = $res->request;  # not always there
		      my $rurl = $req ? $req->url : $url;
		      
		      $file = ($rurl->path_segments)[-1];
		      if (!defined($file) || !length($file)) {
			  $file = "index";
			  my $suffix = media_suffix($res->content_type);
			  $file .= ".$suffix" if $suffix;
		      }
		      elsif ($rurl->scheme eq 'ftp' ||
			     $file =~ /\.t[bg]z$/   ||
			     $file =~ /\.tar(\.(Z|gz|bz2?))?$/
			  ) {
			  # leave the filename as it was
		      }
		      else {
			  my $ct = guess_media_type($file);
			  unless ($ct eq $res->content_type) {
			      # need a better suffix for this type
			      my $suffix = media_suffix($res->content_type);
			      $file .= ".$suffix" if $suffix;
			  }
		      }
		  }

		  # validate that we don't have a harmful filename now.  The server
		  # might try to trick us into doing something bad.
		  if ($file && !length($file) ||
		      $file =~ s/([^a-zA-Z0-9_\.\-\+\~])/sprintf "\\x%02x", ord($1)/ge)
		  {
		      die "Will not save <$url> as \"$file\".\nPlease override file name on the command line.\n";
		  }
		  
		  if (defined $directory) {
		      require File::Spec;
		      $file = File::Spec->catfile($directory, $file);
		  }
		  
		  # Check if the file is already present
		  if (-l $file) {
		      die "Will not save <$url> to link \"$file\".\nPlease override file name on the command line.\n";
		  }
		  elsif (-f _) {
		      die "Will not save <$url> as \"$file\" without verification.\nEither run from terminal or override file name on the command line.\n"
			  unless -t;
		      return 1 if (!$self->{overwrite});
		  }
		  elsif (-e _) {
		      die "Will not save <$url> as \"$file\".  Path exists.\n";
		  }
		  else {
		      $self->{status} = "Saving to '$file'...\n";
		  }
	      }
	      else {
		  $file = $self->{file};
	      }
	      open(FILE, ">$file") || die "Can't open $file: $!\n";
	      binmode FILE unless $self->{mode} eq 'a';
	      $self->{length} = $res->content_length;
	      $self->{flength} = fbytes($self->{length}) if defined $self->{length};
	      $self->{start_t} = time;
	      $self->{last_dur} = 0;
	  }
	  
	  print FILE $_[0] or die "Can't write to $file: $!\n";
	  $self->{size} += length($_[0]);
	  
	  if (defined $self->{length}) {
	      my $dur  = time - $self->{start_t};
	      if ($dur != $self->{last_dur}) {  # don't update too often
		  $self->{last_dur} = $dur;
		  my $perc = $self->{size} / $self->{length};
		  my $speed;
		  $speed = fbytes($self->{size}/$dur) . "/sec" if $dur > 3;
		  my $secs_left = fduration($dur/$perc - $dur);
		  $perc = int($perc*100);
		  $self->{status} = "$perc% of ".$self->{flength};
		  $self->{status} .= " (at $speed, $secs_left remaining)" if $speed;
	      }
	  }
	  else {
	      $self->{status} = "Finished. " . fbytes($self->{size}) . " received";
	  }
       });

    if (fileno(FILE)) {
	close(FILE) || die "Can't write to $file: $!\n";

	$self->{status} = "";  # clear text
	my $dur = time - $self->{start_t};
	if ($dur) {
	    my $speed = fbytes($self->{size}/$dur) . "/sec";
	}
	
	if (my $mtime = $res->last_modified) {
	    utime time, $mtime, $file;
	}
	
	if ($res->header("X-Died") || !$res->is_success) {
	    if (my $died = $res->header("X-Died")) {
		$self->{status} = $died;
	    }
	    if (-t) {
		if ($self->{autodelete}) {
		    unlink($file);
		}
		elsif ($self->{length} > $self->{size}) {
		    $self->{status} = "Aborted. Truncated file kept: " . fbytes($self->{length} - $self->{size}) . " missing";
		}
		return 1;
	    }
	    else {
		$self->{status} = "Transfer aborted, $file kept";
	    }
	}
	return 0;
    }
    return 1;
}

sub fbytes
{
    my $n = int(shift);
    if ($n >= 1024 * 1024) {
	return sprintf "%.3g MB", $n / (1024.0 * 1024);
    }
    elsif ($n >= 1024) {
	return sprintf "%.3g KB", $n / 1024.0;
    }
    else {
	return "$n bytes";
    }
}

sub fduration
{
    use integer;
    my $secs = int(shift);
    my $hours = $secs / (60*60);
    $secs -= $hours * 60*60;
    my $mins = $secs / 60;
    $secs %= 60;
    if ($hours) {
	return "$hours hours $mins minutes";
    }
    elsif ($mins >= 2) {
	return "$mins minutes";
    }
    else {
	$secs += $mins * 60;
	return "$secs seconds";
    }
}

1;
__END__

=head1 NAME

File::Download - Fetch large files from the web

=head1 DESCRIPTION

This Perl module is largely derived from the B<lwp-download> program 
that is installed by LWP or the libwww-perl networking package. This
module abstracts the functionality found in that perl script into a
module to provide a simpler more developer-friendly interface for 
downloading large files.

=head1 USAGE

=head2 METHODS

=over

=item B<download($url)>

This starts the download process by downloading the file located
at the specified URL. Return true if download was successful and
false otherwise.

=item B<status()>

This returns a human readable status message about the download.
It can be used to determine if the download successed or not.

=item B<user_agent()>

Get or set the current user agent that will be used in 
conjunctions with downloads.

=cut

=head2 OPTIONS

Each of the following options are also accessors on the main
File::Download object.

=over

=item B<outfile>

Optional. The name of the file you wish to save the download to.

If you do NOT specific an outfile, then the system will attempt
to determine the destination file name based upon the requested
URL.

If you specify a DIRECTORY as an outfile, then the downloaded file
will be written to that directory with the file name being derived
from the URL requested.

If you specify a FILE as an outfile, then the downloaded file will
be saved with that name. You may use both a relative or absolute
path to the file you wish to save. If a file by that name already
exists you may need to specify the C<overwrite> option (see below).

=item B<overwrite>

Optional. Boolean value which controls whether or not a previously 
downloaded file with the same file name will be overwritten.
Default false.

=item B<mode>

Optional. Allowable values include "a" for ASCII and "b" for binary
transfer modes. Default is "b".

=item B<username>

Not implemented yet.

=item B<password>

Not implemented yet.

=cut

=head1 EXAMPLE

Fetch the newest and greatest perl version:

   my $dwn = File::Download->new({
     file => $argfile,
     overwrite => 1,
     mode => ($opt{a} ? 'a' : 'b'),
   });
   print "Downloading $url\n";
   print $dwn->download($url);
   print $dwn->status();

=head1 AUTHORS and CREDITS

Gisle Aas <gisle@aas.no> - original B<lwp-download> script
Byrne Reese <byrne@majordojo.com> - perl module wrapper

=cut
