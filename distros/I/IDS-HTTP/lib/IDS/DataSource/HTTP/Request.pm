# HTTP Request
#
package IDS::DataSource::HTTP::Request;
use base qw(IDS::DataSource::HTTP);

use strict;
use warnings;
use Carp qw(cluck carp confess);
use Data::Dumper;
use Socket;
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

$IDS::DataSource::HTTP::Request::VERSION     = "2.0";

# keys is a hash to speed up the searching (use the hash instead of grep)
# note all lc, because the standard says they are case insensitive.
### Note that we assume all IDS::DataSource::HTTP:: subobjects use the
### IDS::DataSource::HTTP::Part constructor.
# Comments below refer to section numbers in RFC 2616
# ??? for a section means that it appears not to be a standard, but in
# use anyway.
%IDS::DataSource::HTTP::Request::complex_keys = (
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
    'Forwarded'			=> 'IDS::DataSource::HTTP::Via',		# ???
    'x-forwarded-for'		=> 'IDS::DataSource::HTTP::XForwarded',	# ???
		# Agent is not in 2616, but it appears to be used in a
		# similar manner to user-agent
    'agent'			=> 'IDS::DataSource::HTTP::Agent',		# ???
);

%IDS::DataSource::HTTP::Request::simple_keys = (
    'allow'			=> 1,
    'connection'		=> 1,
    'content-encoding'		=> 1,
    'content-language'		=> 1,
    'content-location'		=> 1,
    'content-range'		=> 1,
    'cookie'			=> 1,
    'if-range'			=> 1,
    'proxy-authorization'	=> 1,
    'transfer-encoding'		=> 1,
);

# break the request into the component tokens.
sub parse {
    my $self  = shift;
    unless ($self->{"data"}) {
        cluck *tokenize{PACKAGE} . "::tokenize called with no data; " .
		Dumper($self) . "\n";
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
          push @tokens, parse_kv($self, $_);
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
	if (exists($IDS::DataSource::HTTP::Request::simple_keys{lc($key)}) ||
	    exists($IDS::DataSource::HTTP::Request::complex_keys{lc($key)})) {
	    push @tokens, "Key: $key";
	    if (defined($value) and $value ne "") {
		if (exists($IDS::DataSource::HTTP::Request::complex_keys{lc($key)})) {
		    $self->{$key} = IDS::DataSource::HTTP::new($IDS::DataSource::HTTP::Request::complex_keys{lc($key)},
					      $self->{"params"}, $value);
		    push @tokens, $self->{$key}->tokens;
		} else { # assume simple key
		    push @tokens, "Value: $value";
		}
	    } else {
		$pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " missing value for '$key'\n";
		$self->warn($pmsg, \@tokens, "!missing value");
	    }
	} else {
	    push @tokens, "Unknown Key: $key";
	    # discard the value.  Is this reasonable?
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

# accessor functions
sub data {
    my $self = shift;
    return $self->{"data"};
}

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

sub tokens {
    my $self  = shift;
    my @result;

    defined($self->{"tokens"}) or $self->parse();

    # Easy cases are handled efficiently
    return $self->{"tokens"} if
	! wantarray && ${$self->{"params"}}{"with_values"} &&
	! ${$self->{"params"}}{"lc_only"};

    return @{$self->{"tokens"}} if
	wantarray && ${$self->{"params"}}{"with_values"} &&
	! ${$self->{"params"}}{"lc_only"};

    # we have handled the simple cases.  We're committed to making at
    # least one change to what we have stored.
    my @tokens = @{$self->{"tokens"}};

    map {
	s/:.*$// unless ${$self->{"params"}}{"with_values"};
	lc if ${$self->{"params"}}{"lc_only"};
    } @tokens;
    return wantarray ? @tokens : \@tokens;
}

sub kv {
    my $self  = shift;
    defined($self->{"tokens"}) or tokenize($self, {});
    return $self->{"kv"};
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

L<IDS::Algorithm>, L<IDS::DataSource>

=cut

1;
