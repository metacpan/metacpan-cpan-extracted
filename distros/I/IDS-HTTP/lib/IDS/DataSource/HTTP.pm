package IDS::DataSource::HTTP;
use base qw(IDS::DataSource);

=head1 IDS::DataSource::HTTP

=head2 Introduction

This class is a subclass of IDS::DataSource, and meets its interface
specification.

All real uses will be through subclasses.

We expect descendents to:

=over

=item *

Whenever a string is loaded, parse then (no lazy evaluation).
This is because *we* have the function to return the tokens.

=item *

Parameters relating to parsing are in the "params" entry, which
is a hash reference.  It is initialized here.

=item *

An optional initializer follows the parameters to new.

=item *

Elements of self:

=over

=item data

the data that caused the parse that we have

=item tokens 

The results of the parse

=item params 

parameters that may affect parsing

=back

=item *

The subclass must implement the following functions:
parse, empty

=back

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);
use IO::Handle;

$IDS::DataSource::HTTP::VERSION     = "2.0";

use IDS::DataSource::HTTP::Accept;
use IDS::DataSource::HTTP::Authorization;
use IDS::DataSource::HTTP::Agent;
use IDS::DataSource::HTTP::CacheControl;
use IDS::DataSource::HTTP::Charset;
use IDS::DataSource::HTTP::Cookie;
use IDS::DataSource::HTTP::Date;
use IDS::DataSource::HTTP::EmailAddr;
use IDS::DataSource::HTTP::Encoding;
use IDS::DataSource::HTTP::ETag;
use IDS::DataSource::HTTP::Expectation;
use IDS::DataSource::HTTP::Host;
use IDS::DataSource::HTTP::Int;
use IDS::DataSource::HTTP::Language;
use IDS::DataSource::HTTP::MethodLine;
use IDS::DataSource::HTTP::RetryAfter;
use IDS::DataSource::HTTP::Range;
use IDS::DataSource::HTTP::IfRange;
use IDS::DataSource::HTTP::Referer;
use IDS::DataSource::HTTP::URI;
use IDS::DataSource::HTTP::URIAuthority;
use IDS::DataSource::HTTP::Via;
use IDS::DataSource::HTTP::IfModifiedSince;
use IDS::DataSource::HTTP::XForwarded;

=over

=item load(source)

load exactly one request from a file, IO::Handle, or supplied string.
If a string is used, it is up to the caller to ensure that more than
one request is not in the string.

=back

=cut

sub load {
    my $self  = shift;
    my $source = shift;
    defined($source) or
        confess *load{PACKAGE} . "::load called without a source\n";

    $self->empty();
    if ($source =~ /\n/) {
	${$self->{"params"}}{"source"} = "Supplied string";
	$self->{"data"} = $source;
	$self->cleanup;
    } elsif (-f $source) {
	${$self->{"params"}}{"source"} = $source;
	my $fh = new IO::File("< $source");
	defined($fh) or carp "Unable to open $source: $!";
	$self->read_session($fh);
    } elsif ($source->isa("IO::Handle")) {
	${$self->{"params"}}{"source"} = "IO::handle";
	$self->read_session($source);
    } else {
        confess *load{PACKAGE} . "::load: I do not know what to do with '$source'\n";
    }
    $self->parse;
    $self->{"todel"} = undef;
}

=over

=item cleanup

Clean data to prepare for tokenizing.

=back

=cut

sub cleanup {
    my $self = shift;
    $self->{"data"} =~ s/\r//g;
    $self->{"data"} =~ s/\s+$//s; # any spaces at the end (is this valid?)
    $self->{"data"} =~ s/\n\s+/ /g;  # fix continuation lines

    # some %-escaped chars back to normal
    $self->{"data"} =~ s/%7E/~/g;
    #$self->{"data"} =~ s/%20/ /g;
    return $self;
}

=over

=item read_session(filehandle)

Read an HTTP session (up to EOF or a blank line) from the filehandle
passed as an argument.

=back

=cut

sub read_session {
    my $self  = shift;
    my $fh = shift or 
        cluck *read_session{PACKAGE} .
	      "::read_session called without a filehandle";

    my $data = "";
    my @lines = ();
    my $first = 1;
    while (<$fh>) { # note last below as an alternate exit for loop
	push @lines, $_;

	if ($first) {
	    next if /^[\r\n]+$/; # skip blank lines at the beginning  A
				 # kludge, but appears to be necesary
				 # for some POST methods
	    $first = 0;
	} else {
	    last if /^[\r\n]+$/;
	}
	s/\r//g; # delete all CRs

        $data .= $_;
    }
    $self->{"lines"} = \@lines;
    my $m = "read_session: loop end eof? " . $fh->eof;
    $self->mesg(2, $m);
    $self->mesg(2, "read_session: end of loop data '$data'");

    $data =~ s/ +$//; # remove final spaces (if any)
    $data =~ s/\n\s+/ /mg;  # fix continuation lines

    if ($data =~ /^POST|PROPFIND/m) { # try to deal properly with POST/PROPFIND data
	if ($data =~ /Content-Length: (\d+)/) {
	    my ($postdata, $content_len);
	    $content_len = $1;
	    read $fh, $postdata, $content_len;
	    $self->{"postdata"} = $postdata;
	    my $msg = join('', "read_session: postdata ($content_len bytes) is: '$postdata' ", length($postdata), " chars");
	    $self->mesg(1, $msg);
	} else { # Nope, weird request.
	    $self->mesg(1, "read_session: no Content-Length in POST/PROPFIND request");
	    $self->mesg(1, "read_session: data '$data'");
	    my $msg = join('', "read_session: remaining data: '", <$fh>, "'");
	    $self->mesg(1, $msg);
	    #$fh->close; ### can we recover from this?
	}
    }

    if ($data) {
	$self->{"data"} = $data;
	$self->cleanup;
	return 1;
    } else {
	$self->warn(${$self->{"params"}}{"source"} . ": data was empty", [],"");
	return 0;
    }
}

=over

=item read_next(filehandle)

Read the next request.  We are expecting a list of files on the
filehandle passed in.  We will either read the next request from the from the
currently-open file, or open the next file in the list, as needed.

=back

=cut

# This function has to keep track of state, making it more complex than
# a loop in a caller.
sub read_next {
    my $self  = shift;
    my $fname_fh = shift;
    defined($fname_fh) or
        cluck *read_next{PACKAGE} . "::read_next called without a filehandle";
    
    my $fh = $self->{"current_fh"};

    # reset everything for the new request
    $self->empty();

    my $ret;
    do {
	# See if we are done.
	return undef if $fname_fh->eof && (!defined($fh) || $fh->eof);

	# while we need another file and we have files in the list;
	# will run 0 times if there is more to read from the current
	# file.
	while (! (defined($fh) && ! $fh->eof) && ! $fname_fh->eof) {
	    $self->mesg(1, "Processed " . $self->{"fname"} . "\n")
	        if exists($self->{"fname"}) && defined($self->{"fname"});
	    $fh = $self->open_next($fname_fh); #resets fname and session count
	}
	# see if we ran out of filenames 
	return undef unless defined($fh);

	$self->{"session"}++;
	${$self->{"params"}}{"source"} = $self->{"fname"} . " request " .
	                                 $self->{"session"};
	$ret = $self->read_session($fh);
    } until ($ret);
    $self->{"current_fh"} = $fh;
    $self->parse;
    return 1;
}

# open_next is a utility function used by read_files; should not be
# called outside of this object
sub open_next {
    my $self  = shift;
    my $fname_fh = shift;
    my $fname;

    # handle missing files
    do {
	# skip blank or commented lines
	do {
	    $fname = $fname_fh->getline;
	    last unless $fname;
	    chomp $fname;
	    # support comments in input
	    $fname =~ s/\s*#.*$//;
	} while (! $fname_fh->eof && $fname =~ /^$/);
	$self->{"fname"} = $fname;
	$self->{"session"} = 0;
	$self->{"current_fh"} = new IO::File "$fname" or
	    warn "Unable to open $fname: $!\n";
    } while (! $self->{"current_fh"});
    $self->mesg(1, "Opened $fname");
    return $self->{"current_fh"};
}

=over

=item data()

Return the data used for the tokens we have.  If called in array mode,
we return the individual lines, otherwise the join of those line.

=back

=cut

sub data {
    my $self = shift;
    return wantarray ? @{$self->{"lines"}} : $self->{"data"};
}

=over

=item postdata()

Return the data part of a POST request.  Only has meaning in a POST
request.

=back

=cut

sub postdata {
    my $self = shift;

    return $self->{"postdata"};
}

# other, undocumented accessor functions

sub path {
    my $self  = shift;
    return $self->{"methodline"}->path;
}

sub method {
    my $self  = shift;
    return $self->{"methodline"}->method;
}

sub host {
    my $self  = shift;
    return $self->{"kv"}{"Host"};
}

sub kv {
    my $self  = shift;
    defined($self->{"tokens"}) or tokenize($self, {});
    return $self->{"kv"};
}

=over

=item source()
=item source(value)

Set and/or get the data source.

=back

=cut

sub source {
    my $self = shift;
    if (defined($_[0])) {
        my $old = ${$self->{"params"}}{"source"};
	${$self->{"params"}}{"source"} = $_[0];
	return $old;
    } else {
	return ${$self->{"params"}}{"source"};
    }
}

=over

=item tokens()

Return the tokens that result from parsing the structure.  The tokens
can be returned as an array or a reference to the internal array holding
them (for efficiency).  Modify this referenced array at your own risk.

Note that this function can remove values.
Note that this function can convert everything to lower case.
Both of these options are controlled by parameters, and neither affects
the internal version of the tokens.

=back

=cut

sub tokens {
    my $self  = shift;
    my @result;

    defined($self->{"tokens"}) or $self->parse; # just in case
    defined($self->{"tokens"}) or 
         return [];
#        confess *tokens{PACKAGE} .  "::tokens parsing produced no tokens!";

    # Easy cases are handled efficiently
    if (${$self->{"params"}}{"with_values"} && ! ${$self->{"params"}}{"lc_only"}) {
	return wantarray ? @{$self->{"tokens"}} : $self->{"tokens"};
    }

    # we have handled the simple cases.  We're committed to making at
    # least one change to what we have stored.
    my @tokens = @{$self->{"tokens"}};

    map {
        s/:.*$// unless ${$self->{"params"}}{"with_values"};
	lc if ${$self->{"params"}}{"lc_only"};
    } @tokens;
    return wantarray ? @tokens : \@tokens;
}

=over

=item expand_pct(data)

Expand the %-substitutions.  This function currently does not handle
unicode and &-expansions.  Should it?

=back

=cut

sub expand_pct {
    my $self = shift;
    my $data = shift;

    while ($data =~ /%([0-9A-Fa-f]{2})/) {
        $data =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/e;
    }
    return $data;
}

# keys is a hash to speed up the searching (use the hash instead of grep)
# note all lc, because the standard says they are case insensitive.
### Note that we assume all IDS::DataSource::HTTP:: subobjects use the
### IDS::DataSource::HTTP::Part constructor.
# Comments below refer to section numbers in RFC 2616
# ??? for a section means that it appears not to be a standard, but in
# use anyway.
%IDS::DataSource::HTTP::complex_keys = (
    'accept'			=> 'IDS::DataSource::HTTP::Accept',		# 14.1
    'accept-charset'		=> 'IDS::DataSource::HTTP::Charset',		# 14.2
    'accept-encoding'		=> 'IDS::DataSource::HTTP::Encoding',	# 14.3
    'accept-language'		=> 'IDS::DataSource::HTTP::Language',	# 14.4
	    # 14.5 Accept-Ranges is server->client
	    # 14.6 Age is server or proxy->client
	    # 14.7 Allow is server->client
    'authorization'		=> 'IDS::DataSource::HTTP::Authorization',	# 14.8
    'cache-control'		=> 'IDS::DataSource::HTTP::CacheControl',	# 14.9
	    # 14.10 Connection; simple and already handled by key+value
	    # 14.11 Content-Encoding; simple and already handled by key+value
	    # 14.12 Content-Language; simple and already handled by key+value
    'content-length'		=> 'IDS::DataSource::HTTP::Int',		# 14.13
	    # 14.14 Content-Location likely to be server->client
    'content-md5'		=> 'IDS::DataSource::HTTP::MD5',		# 14.15
	    # 14.16 Content-Range is server->client
    'content-type'		=> 'IDS::DataSource::HTTP::Accept',		# 14.17
    'date'			=> 'IDS::DataSource::HTTP::Date',		# 14.18
    'etag'			=> 'IDS::DataSource::HTTP::ETag',		# 14.19
    'expect'			=> 'IDS::DataSource::HTTP::Expectation',	# 14.20
    'expires'			=> 'IDS::DataSource::HTTP::Date',		# 14.21
    'from'			=> 'IDS::DataSource::HTTP::EmailAddr',	# 14.22
		# for host, we accept more than the standard, since
		# authority may include user info
    'host'			=> 'IDS::DataSource::HTTP::URIAuthority',	# 14.23
    'if-match'			=> 'IDS::DataSource::HTTP::ETag',		# 14.24
    'since'			=> 'IDS::DataSource::HTTP::Date',		# 14.25
    'if-none-match'		=> 'IDS::DataSource::HTTP::ETag',		# 14.26
    'if-range'			=> 'IDS::DataSource::HTTP::IfRange',		# 14.27
    'if-modified-since'		=> 'IDS::DataSource::HTTP::IfModifiedSince',	# 14.28
    'if-unmodified-since'	=> 'IDS::DataSource::HTTP::Date',		# 14.28
    'unless-modified-since'	=> 'IDS::DataSource::HTTP::Date',		# 14.28
    'unless-unmodified-since'	=> 'IDS::DataSource::HTTP::Date',		# 14.28
    'last-modified'		=> 'IDS::DataSource::HTTP::Date',		# 14.29
    'location'			=> 'IDS::DataSource::HTTP::URI',		# 14.30
    'max-forwards'		=> 'IDS::DataSource::HTTP::Int',		# 14.31
	    # ### Do we need 14.32 Pragma?
	    # 14.33 Proxy-Authenticate is proxy->client
	    # 14.34 Proxy-Authorization is client->proxy
    'range'			=> 'IDS::DataSource::HTTP::Range',		# 14.35
    'referer'			=> 'IDS::DataSource::HTTP::Referer',		# 14.36
    'retry-after'		=> 'IDS::DataSource::HTTP::RetryAfter',	# 14.37
	    # 14.38 Server is server->client
    'te'			=> 'IDS::DataSource::HTTP::Encoding',	# 14.39
	    # ### might need 14.40 Trailer 
    'transfer-encoding'		=> 'IDS::DataSource::HTTP::Encoding',	# 14.41
	    # ### need 14.42 Upgrade (although unlikely to see)
    'user-agent'		=> 'IDS::DataSource::HTTP::Agent',		# 14.43
	    # 14.44 Vary is server->
    'via'			=> 'IDS::DataSource::HTTP::Via',		# 14.45
	    # ### might need 14.46 Warning ?
	    # 14.47 WWW-Authenticate is server->client

    'cookie'			=> 'IDS::DataSource::HTTP::Cookie',		# RFC 2965
    'charset'			=> 'IDS::DataSource::HTTP::Charset',		# ???
    'encoding'			=> 'IDS::DataSource::HTTP::Encoding',	# ???
    'forwarded'			=> 'IDS::DataSource::HTTP::Via',		# ???
    'x-forwarded-for'		=> 'IDS::DataSource::HTTP::XForwarded',	# ???
		# Agent is not in 2616, but it appears to be used in a
		# similar manner to user-agent
    'agent'			=> 'IDS::DataSource::HTTP::Agent',		# ???
);

%IDS::DataSource::HTTP::simple_keys = (
    'allow'			=> 1,
    'connection'		=> 1,
    'content-encoding'		=> 1,
    'content-language'		=> 1,
    'content-location'		=> 1,
    'content-range'		=> 1,
    'if-range'			=> 1,
    'proxy-authorization'	=> 1,
    'transfer-encoding'		=> 1,
);

# break the request into the component tokens.
sub parse {
    my $self  = shift;
    unless ($self->{"data"}) {
        cluck "Warning: " . *tokenize{PACKAGE} . "::tokenize called with no data.";
	$self->{"tokens"} = [];
	return $self;
    }
    if ($self->{"data"} =~ /^$/) {
	return $self->mesg(0, "Empty data from " . ${$self->{"params"}}{"source"});
    }

    my @tokens = ();

    my @lines = split /\n/, $self->{"data"};
    chomp(@lines);
    $self->mesg(1, *parse{PACKAGE} . "::parse: Line is '$lines[0]'");
    $self->{"methodline"} = new IDS::DataSource::HTTP::MethodLine($self->{"params"}, $lines[0]);
    push @tokens, $self->{"methodline"}->tokens();

    map { $self->mesg(1, *parse{PACKAGE} . "::parse: Line is '$_'");
          push @tokens, $self->parse_kv($_);
	} @lines[1..$#lines];

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

sub parse_kv {
    my $self = shift;
    my $line = shift;
    my $pmsg;
    my @tokens = ();

    my $kvpat = qr/([^:]+):(\s*(.*))?/;
    if ($line =~ /$kvpat/) {
	my $key = $1;
	my $value = $3;
	$self->mesg(3, *parse{PACKAGE} . "::parse_kv: key '$key' value '$value'");
	$self->{"kv"}{$key} = $value;
	if (exists($IDS::DataSource::HTTP::simple_keys{lc($key)})) {
	    push @tokens, "Key: $key";
	    if (defined($value) and $value ne "") {
		push @tokens, "Value: $value";
	    } else {
		$pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " missing value for '$key'\n";
		$self->warn($pmsg, \@tokens, "!missing value");
	    }
	} elsif (exists($IDS::DataSource::HTTP::complex_keys{lc($key)})) {
	    $self->mesg(3, *parse{PACKAGE} . "::parse_kv: complex key " . lc($key));
	    push @tokens, "Key: $key";
	    if (defined($value) and $value ne "") {
		$self->{$key} = IDS::DataSource::HTTP::Part::new($IDS::DataSource::HTTP::complex_keys{lc($key)},
					  $self->{"params"}, $value);
		push @tokens, $self->{$key}->tokens;
	    } else {
		$pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " missing value for '$key'\n";
		$self->warn($pmsg, \@tokens, "!missing value");
	    }
	} else {
	    push @tokens, "Unknown Key: $key";
	    ### discard the value.  Is this reasonable?
	}
    } elsif ($line =~ /^$/) {
	push @tokens, "End-of-request";
    } else {
	$pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " Unknown line '$line'\n";
	$self->warn($pmsg, \@tokens, "!unknown line");
    }

    return @tokens;
}

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"}, $self->{"methodline"},
          $self->{"kv"}, $self->{"Referer"},
          $self->{"Accept"}, $self->{"AcceptLanguage"}, $self->{"Date"},
          $self->{"User-Agent"}, $self->{"Agent"};
}

=head2 Functions required by IDS::DataSource

=over

=item default_parameters()

Sets all of the default values for the parameters.  Normally called by
new() or one of its descendents.

=back

=cut

sub default_parameters {
    my $self = shift;
    my %params = (
    # general parameters
    # source			# filled in by IDS::DataSource::HTTP::read_session,
    				# it is the source of data,
    				# used when producing error/warn msgs
    "msg_fh" => $self->fh_or_stdout,# Where warning messages go; nowhere if undef
    "return_warnings" => 1,	# Warnings are tokens
    "print_warnings" => 0,	# Print warning messages (to msg_fh)
    "verbose" => 0,		# Print extra information; larger means more
    
    # what to return as tokens
    "with_values" => 1,         # whether to put values in the parsed http
    "lc_only" => 1, 	        # whether to map all of the http to lower case
    "file_types_only" => 1,     # return only file types, not names
    "file_name_lengths" => 1,   # return filename length of unknown file types
    # various data validation options
    "recognize_hostnames" => 1, # return simply if a hostname is valid or not
    "recognize_ipaddr" => 1,    # return simply if an addr is valid or not
    "lookup_hosts" => 0,        # lookup hosts and addrs to ensure DNS entries?
    "recognize_dates" => 1,     # return simply if a date is valid or not
    "handle_PHPSESSID" => 1,	# validate PHP Session ID to avoid hash
    "handle_EntityTag" => 1,	# validate Entity Tags to avoid hashes
    "recognize_qvalues" => 1,	# validate qvalue; otherwise, return value
    "email_user_length_only" => 1, # only return the email address length, 
                  		# not value
    "cookie_values" => 0,       # whether or not to include cookie values
    );
    $self->{"params"} = \%params;
    $self->{"try_deleting"} = [ qw(Referer Cookie Accept-Language
                                   Accept-Charset Accept) ];
    $self->{"todel"} = undef;
}

=over

=item param_options()

Command-line option specifiers for our parameters for GetOpt::Long.

=back

=cut

sub param_options {
    my $self = shift;

    return (
    "values!"              => \${$self->{"params"}}{"with_values"},
    "lc!"                  => \${$self->{"params"}}{"lc_only"},
    "file_types_only!"     => \${$self->{"params"}}{"file_types_only"},
    "file_name_lengths!"   => \${$self->{"params"}}{"file_name_lengths"},
    "http_verbose=i"       => \${$self->{"params"}}{"verbose"},
    "return_warnings!"	   => \${$self->{"params"}}{"return_warnings"},
    "print_warnings!"	   => \${$self->{"params"}}{"print_warnings"},
    "recognize_hostnames!" => \${$self->{"params"}}{"recognize_hostnames"}, 
    "recognize_ipaddr!"    => \${$self->{"params"}}{"recognize_ipaddr"},    
    "lookup_hosts!"        => \${$self->{"params"}}{"lookup_hosts"},        
    "recognize_dates!"     => \${$self->{"params"}}{"recognize_dates"},     
    "handle_PHPSESSID!"    => \${$self->{"params"}}{"handle_PHPSESSID"},	
    "handle_EntityTag!"    => \${$self->{"params"}}{"handle_EntityTag"},	
    "recognize_qvalues!"   => \${$self->{"params"}}{"recognize_qvalues"},	
    "email_user_length_only!" => \${$self->{"params"}}{"email_user_length_only"},
    "alternate_delete=s@"  => $self->{"try_deleting"},
    "cookie_values!"       => \${$self->{"params"}}{"cookie_values"},
    );
}

=over

=item alternate()

Try deleting lines and re-parsing.  We have to keep track of state.
Note that the various reading functions will reset the state.

This function returns either a new IDS::DataSource::HTTP object or
undef.  If called after it returns undef, it will start the process
over.

=back

=cut

sub alternate {
    my $self = shift;
    my (@todel, @lines, $hdr, $http);

    # keep track of state with $self->{"todel"}, which is a reference to
    # a list.  If this value is undefined, then this is the first time.
    if (! defined(${$self->{"todel"}})) {
	@todel = @{$self->{"try_deleting"}};
    } elsif (! @{${$self->{"todel"}}}) {
	undef ${$self->{"todel"}};
        return undef; # nothing more to do
    } else {
        @todel = @{${$self->{"todel"}}}
    }

    do {
	$hdr = pop @todel;
	@lines = grep { !/^$hdr: /i } @{$self->{"lines"}};
    } while (@todel && $#lines == $#{$self->{"lines"}});
    ${$self->{"todel"}} = \@todel;

    # did we achieve anything with the deleting?
    if ($#lines == $#{$self->{"lines"}}) {
        undef ${$self->{"todel"}};
	return undef;
    }

    $http = new IDS::DataSource::HTTP;
    $http->load(join("\r\n", @lines));
    return ("Without $hdr", $http);
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

=cut

1;
