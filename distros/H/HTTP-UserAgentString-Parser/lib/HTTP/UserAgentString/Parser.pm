package HTTP::UserAgentString::Parser;

=head1 NAME

HTTP::UserAgentStringParser - User-Agent string parser

=head1 SYNOPSIS

 my $p = HTTP::UserAgentString::Parser->new();
 my $ua = $p->parse("Opera/9.80 (X11; Linux x86_64; U; en) Presto/2.9.168 Version/11.50");

 if ($ua->isRobot) {
 	print "It's a robot: ", $ua->name, "\n";
 } else {
 	print "It's a browser: ", $ua->name, " - version: ", $ua->version, "\n";
 }

=head1 DESCRIPTION

C<HTTP::UserAgentString::Parser> is a Perl API for user-agent-string.info.  It 
can be used to parse user agent strings and determine whether the agent is a robot, 
a normal browser, mobile browser, e-mail client.  It can also tell browser version, 
company that makes it, home page URL.  In most of the cases it can also tell in which 
OS the browser is running.

HTTP::UserAgentString::Parser will download the .ini file provided by user-agent-string.info 
which contains all the information to do the parsing.  The file will be cached by default
for 7 days.  After that time, it will check whether a new version was released.  The
default cache time can be modified, as well as the cache path (default is /tmp).  A
cache reload can also be forced.

In order to parse a string, a parse() method is provided which returns an object
of classes HTTP::UserAgentString::Browser or HTTP::UserAgentString::Robot.  Both classes 
have accesors to determine agent capabilities.  In case the string does not match any known 
browser or robot, undef() is returned.

=head1 CONSTRUCTOR

$p = HTTP::UserAgentString::Parser->new(%opts)

Valid options are:

 cache_max_age: in seconds (default is 7 days)
 cache_dir: path must be writeable - default is /tmp
 parse_cache_size: size of parsing cache in number of elements.  Default is 100_000

=head1 METHODS

=over 4

=item $agent = $p->parse($string)

Parses a User-Agent string and returns a HTTP::UserAgentString::Browser or 
HTTP::UserAgentString::Robot object, or undef() if no matches where found.

=item $p->updateDB($force)

Updates the cache file from user-agent-string.info.  If force is false or undef(), the
check is only executed if the cache file has expired.  If force is true, the method
checks whether there is a new file and downloads it accordingly.

=item $p->getCurrentVersion()

Retrieves the current database version from user-agent-string.info.  Returns the version
number or undef() if an error occurs.

=item $p->getCachedVersion()

Returns the version of the cached .ini file, or undef() if there is no cached file.

=item $p->cache_file()

Local path to the cached .ini file.

=item $p->version_file()

Local path to file that contains the version of the cached .ini file.

=back

=head1 SEE ALSO

See L<HTTP::UserAgentString::Browser> and L<HTTP::UserAgentString::Robot> for description
of the objects returned by parse().

=head1 COPYRIGHT

 Copyright (c) 2011 Nicolas Moldavsky (http://www.e-planning.net/)
 This is free software. You can redistribute it or modify it under the terms of the
 Perl license

=cut

use strict;
use Carp ();
use LWP::UserAgent;
use File::Spec;
use Digest::MD5;
use HTTP::UserAgentString::Browser;
use HTTP::UserAgentString::Robot;
use HTTP::UserAgentString::OS;

our $VERSION = '0.6.1';

my @REQUIRED_SECS = qw(robots os browser browser_type browser_reg browser_os os_reg);

my $REGEX_SECS = { 'browser_reg' => 1, 'os_reg' => 1 };

my $INI_URL = 'http://user-agent-string.info/rpc/get_data.php?key=free&format=ini';
my $VER_URL = 'http://user-agent-string.info/rpc/get_data.php?key=free&format=ini&ver=y';
my $MD5_URL = 'http://user-agent-string.info/rpc/get_data.php?format=ini&md5=y';

my $DEFAULT_CACHE_DIR = '/tmp';
my $DEFAULT_CACHE_MAX_AGE = 7 * 86400;

my $DEFAULT_PARSE_CACHE_SIZE = 100000;

my $INI_FILE = 'uas.ini';
my $VER_FILE = 'uas.version';

sub cache_dir($) { $_[0]->{cache_dir} }
sub parse_cache_count($) { $_[0]->{parse_cache_count} }
sub cache_max_age($) { $_[0]->{cache_max_age} }

sub cache_file($) {
	my $self = shift;
	return File::Spec->catfile($self->cache_dir, $INI_FILE);
}
sub version_file($) {
	my $self = shift;
	return File::Spec->catfile($self->cache_dir, $VER_FILE);
}

sub getCurrentVersion($) {
	my $self = shift;
	my $lwp = LWP::UserAgent->new();	
	$lwp->env_proxy();
	my $res = $lwp->get($VER_URL);
	if ($res->is_success) {
		return $res->content;
	} else {
		Carp::carp( "Can't get current file version from $VER_URL: " . $res->status_line . "\n");
		return undef();
	}
}

sub getCachedVersion($) {
	my $self = shift;
	my $path = $self->version_file;
	if (-f $path) {
		if (open(my $fh, "<", $path)) {
			my $version = <$fh>;
			close($fh);
			return $version;
		} else {
			Carp::carp("Can't open $path: $!\n");
			return undef();
		}
	} else {
		return undef();
	}
}


sub _writeCacheFile($$$) {
	my ($self, $filename, $content) = @_;

	if (open(my $fh, ">", $filename)) {
		if (print $fh $content) {
			if (close($fh)) {
				return 1;
			} else {
				Carp::carp("Can't close $filename: $!\n");
				return 0;
			}
		} else {
			Carp::carp("Can't write to $filename: $!\n");
			return 0;
		}
	} else {
		Carp::carp("Can't open $filename for writing: $!\n");
		return 0;
	}
}

sub _updateCache($$$) {
	my ($self, $inidata, $version) = @_;

	return ($self->_writeCacheFile($self->cache_file, $inidata) and $self->_writeCacheFile($self->version_file, $version));
}

sub _downloadDB($$) {
	my ($self, $current_version) = @_;
	my $lwp = LWP::UserAgent->new();	
	$lwp->env_proxy();
	my $res_ini = $lwp->get($INI_URL);
	if ($res_ini->is_success) {
		my $inidata = $res_ini->content;
		my $res_md5 = $lwp->get($MD5_URL);
		if ($res_md5->is_success) {
			my $expected_hash = $res_md5->content;
			my $ctx = Digest::MD5->new();
			$ctx->add($inidata);
			my $hash = $ctx->hexdigest();
			if ($hash eq $expected_hash) {
				# Write files to disk
				return $self->_updateCache($inidata, $current_version);
			} else {
				Carp::carp("MD5 digest does not match - expected=$expected_hash; calculate=$hash\n");
				return 0;
			}
		} else {
			Carp::carp("Can't get MD5 from $MD5_URL: " . $res_md5->status_line . "\n");
			return 0;
		}
	} else {
		Carp::carp("Can't get .ini from $INI_URL: " . $res_ini->status_line . "\n");
		return 0;
	}
}

sub updateDB($;$) {
	my ($self, $force) = @_;

	# Check if cache file needs to be updated according to max_age

	my $cache_file = $self->cache_file;

	my $do_check;
	if (! -f $cache_file) {
		$do_check = 1;
	} else {
		my @stat = stat($cache_file);
		if (@stat) {
			my $mtime = $stat[9];
			my $limit = time() - $self->cache_max_age;
			$do_check = ($mtime < $limit);
		} else {
			Carp::carp("Can't stat() $cache_file: $!\n");
			return undef();
		}
	}

	if ($do_check or $force) {
		my $current_version = $self->getCurrentVersion();
		my $cache_version = $self->getCachedVersion();
		if (defined($current_version) and ((! defined($cache_version)) or ($current_version gt $cache_version))) {
			return $self->_downloadDB($current_version);
		} else {
			return -1;
		}
	} else {
		return -1;
	}
}


sub _compileRegexes($$) {
	my ($self, $regexes) = @_;

	foreach my $ir (@$regexes) {
		my $r = $ir->[0];
		my $regex = eval "qr" . $r;
		if (defined($regex)) {
			$ir->[2] = $r;
			$ir->[0] = $regex;
		} else {
			Carp::carp("Invalid regex: " . $ir->[0] . "($@)\n");
			return 0;
		}
	}

	return  1;
}

sub _loadDB($) {
	my $self = shift;
	my $file = $self->cache_file;
	if (open(my $fh, "<", $file)) {
		my $cursec;
		my $nline = 1;
		my $lastvalues;
		my $lastid;
		while (<$fh>) {
			$nline++;
			next if (/^;/);
			chop;
			if (/^\[([\w_]+)\]\s*$/) {
				if (defined($lastvalues)) {
					push(@{$self->{$cursec}}, $lastvalues);
				}
				$cursec = $1;
				$lastid = undef();
				$lastvalues = undef();
			} elsif (/^(\d+)\[\] = "(.*)"\s*$/) {
				my ($id, $value) = ($1, $2);
				if ($REGEX_SECS->{$cursec}) {
					if (defined($lastid) and ($id == $lastid)) {
						push(@$lastvalues, $value);
					} else {
						push(@{$self->{$cursec}}, $lastvalues) if (defined($lastid));
						$lastid = $id;
						$lastvalues = [ $value ];	
					}
				} else {
					push(@{$self->{$cursec}[$id]}, $value);
				}
			} else {	
				Carp::carp("Invalid format in line $nline: $_\n");
				return 0;
			}
		}
		if (defined($lastvalues)) {
			push(@{$self->{$cursec}}, $lastvalues);
		}
		close($fh);

		# Check that we have all required sections
		foreach my $sec (@REQUIRED_SECS) {
			my $a = $self->{$sec};
			if (! defined($a) or (! @$a)) {
				Carp::carp("Section $a is not present in $file");
				return 0;
			}
		}

		# Compile regexes
		foreach my $key (keys %$REGEX_SECS) {
			$self->_compileRegexes($self->{$key}) or return 0;
		}


		# Index for robots
		$self->{robot_index} = {};
		my @r;
		foreach my $robot (grep { defined($_) } @{$self->{robots}}) {
			my $os_id = $robot->[7];
			my $os;
			if ($os_id and defined($self->{os}[$os_id])) {
				$os = HTTP::UserAgentString::OS->new($self->{os}[$os_id]);
			}
			my $bot = HTTP::UserAgentString::Robot->new($robot, $os);
			push(@r, $bot);
			$self->{robot_index}{$robot->[0]} = $bot;
		}
		$self->{robots} = \@r;

		$self->{parse_cache} = {};
		$self->{parse_cache_count} = 0;

		return 1;
	} else {
		Carp::carp("Can't open $file for reading: $!\n");
		return 0;
	}
}

sub new($;%) {
	my ($pkg, %opts) = @_;

	foreach my $key (qw(cache_max_age parse_cache_size)) {
		my $val = $opts{$key};
		if (defined($val) and ($val !~ /^\d+$/)) {
			Carp::carp("$key must be an integer!\n");
			return undef();
		}
	}
	
	if ($opts{cache_dir}) {
		if (! -d $opts{cache_dir}) {
			Carp::carp($opts{cache_dir} . " is not a valid directory: $!");
			return undef();
		}
	}

	my $self = bless({
		cache_dir => $opts{cache_dir} || $DEFAULT_CACHE_DIR,
		cache_max_age => $opts{cache_max_age} || $DEFAULT_CACHE_MAX_AGE,
		parse_cache_size => defined($opts{parse_cache_size}) ? $opts{parse_cache_size} : $DEFAULT_PARSE_CACHE_SIZE
		}, $pkg);

	if ($self->updateDB and $self->_loadDB()) {
		return $self;
	} else {
		return undef();
	}
}

sub robots($) { $_[0]->{robots} }
sub browser_reg($) { $_[0]->{browser_reg} }
sub os_reg($) { $_[0]->{os_reg} }

sub getBrowser($$) {
	my ($self, $browser_id) = @_;
	my $bos = $self->{browser_os}[$browser_id];
	my $os;
	$os = $self->getOS($bos->[0]) if (defined($bos));
	return HTTP::UserAgentString::Browser->new($self->{browser}[$browser_id], "", "", $os);
}

sub getOS($$) {
	my ($self, $os_id) = @_;
	return HTTP::UserAgentString::OS->new($self->{os}[$os_id]);
}

# Real parsing with no cache checking
sub _parse($$) {
	my ($self, $string) = @_;

	# First we check whether it is a robot
	if (defined(my $robot = $self->{robot_index}{$string})) {
		return $robot;
	}

	# Now we check browser regexes
	my $idx = 0;
	foreach my $br (grep { defined($_) } @{$self->{browser_reg}}) {
		my ($regex, $browser_id) = @$br;
		if ($string =~ $regex) {
			my $version = $1;
			my $browser = $self->{browser}[$browser_id];
			my $typeDesc;
			my $type = $browser->[0];
			if (defined($self->{browser_type}[$type])) {
				$typeDesc = $self->{browser_type}[$type][0];
			}
			my $bos = $self->{browser_os}[$browser_id];
			my $os_id;
			$os_id = $bos->[0] if (defined($bos));
			my $os;

			if (! defined($os_id)) {
				# Use regexes to search lookup OS
				OS: foreach my $or (grep { defined($_) } @{$self->{os_reg}}) {
					my ($osregex, $id) = @$or;
					if ($string =~ $osregex) {
						$os_id = $id;
						last OS;
					}
				}
			}

			if (defined($os_id) and defined($self->{os}[$os_id])) {
				$os = HTTP::UserAgentString::OS->new($self->{os}[$os_id]);
			}
		
			return HTTP::UserAgentString::Browser->new($browser, $typeDesc, $version, $os);
		}
		$idx++;
	}

	return undef();
}

sub parse($$) {
	my ($self, $string) = @_;

	my $obj;
	if (exists $self->{parse_cache}{$string}) {
		$obj = $self->{parse_cache}{$string};
	} else {
		$obj = $self->_parse($string);
		# Cache it if we have enough space
		if ($self->{parse_cache_count} < $self->{parse_cache_size}) {
			$self->{parse_cache_count}++;
			$self->{parse_cache}{$string} = $obj;
		}
	}

	return $obj;
}

1;

