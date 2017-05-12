###########################################################################
# Copyright 2004 Lab-01 LLC <http://lab-01.com/>
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Tmojo(tm) is a trademark of Lab-01 LLC.
###########################################################################

package HTML::Tmojo::HttpArgParser;

=head1 Description

HttpArgParser is a package designed for use in
Mod Perl handlers and CGI scripts

It provides an object, which, when instantiated, slurps
up all the arguments passed via the CGI or mod perl ENV,
including STDIN and MIME MULTIPART form data

Only one object should be created per HTTP POST or GET--
if you create a second one, it won't get POST parameters

Usage:

	my $http_obj = HTML::Tmojo::HttpArgParser->new();
	my %args = $http_obj->args();

	or

	my $http_obj = HTML::Tmojo::HttpArgParser->new();
	my %args = $http_obj->args(
		foo => 'array',
		bar => 'hash',
		goo => 'ref',
	);

If you want some arguments to be interpreted as hashes
or arrays, you can specify that by passing a literal hash
of argument names and types.

=cut



use strict;
use Encode;


#######################################

=head2 new:method

my $http_obj = HTML::Tmojo::HttpArgParser->new()

Parses all standard parameters in the HTTP query
string and the http POST (if there is one) and
stores them in a new object, then returns the new
object.

=cut

sub new:method {

	my ($class, @extra_settings) = @_;
	
	# make an object
	
	my %data = (
		args          => {},
		query         => {},
		post          => {},
		max_mime_size => 300_000,
		@extra_settings
	);
	
	my $self = bless (\%data, $class);
	
	# get the query parameters
	
	$self->read_get();
	
	# get a post with either regular or MIME multipart input
	
	if ($ENV{REQUEST_METHOD} eq 'POST') {
	
		if ($ENV{CONTENT_TYPE} =~ m/multipart\/form-data\;\s+boundary=[-]+(\S+)/i) {
			$self->read_mime_post($1);
		} else {
			$self->read_post($1);
		}
	
	}	
	
	return $self;

}

#######################################

=head2 args:method

Call this to retrieve the GET and POST arguments stored in the  object.

	my %args = $HttpArgParser->args();

	or

	my %args = $http_obj->args(
		foo => 'array',
		bar => 'hash',
		goo => 'ref',
	);

=cut

sub args:method {

	my ($self, %arg_specs) = @_;
	
	# Unless they asked for a hash, array, or ref, we
	# always return a scalar. The actual contents of 
	# $self->{args}{foo} is always an array
	
	my @result;
	my %union_hash = map { $_ => 1 } (keys %arg_specs, keys %{$self->{args}});
	
	foreach my $key (keys %union_hash) {
	
		# return the values as a hash ref
	
		if (lc($arg_specs{$key}) eq 'hash') {
		
			if (defined($self->{args}{$key})) {
				push @result, $key, { map { $$_ } @{$self->{args}{$key}} };
			} else {
				push @result, $key, undef;
			}
		
		# return the values as an array ref
		
		} elsif (lc($arg_specs{$key}) eq 'array') {
		
			if (defined($self->{args}{$key})) {
				push @result, $key, [ map { $$_ } @{$self->{args}{$key}} ];
			} else {
				push @result, $key, undef;
			}
		
		# return a reference to the last value
		
		} elsif (lc($arg_specs{$key}) eq 'ref') {
		
			if (not defined($self->{args}{$key})) {
				push @result, $key, \undef;
			} else {
				my $array_size = scalar(@{$self->{args}{$key}});
				push @result, $key, $self->{args}{$key}[$array_size-1];

			}
		
		# return the last value as a scalar
		
		} else {
		
			if (not defined($self->{args}{$key})) {
				push @result, $key, undef;
			} else {
				my $array_size = scalar(@{$self->{args}{$key}});
				push @result, $key, ${$self->{args}{$key}[$array_size-1]};
			}			
				
		}
		
	}
	
	return @result;

}

#######################################

=head2 args_query:method

Call this to retrieve ONLY the QUERY arguments stored in the object
(this ignores the POST arguments)

	my %query_args = $HttpArgParser->args_query();

	or

	my %query_args = $HttpArgParser->args_query(
		foo => 'array',
		bar => 'hash',
		goo => 'ref',
	);

=cut

sub args_query:method {

	my ($self, %arg_specs) = @_;
	
	# Unless they asked for a hash, array, or ref, we
	# always return a scalar. The actual contents of 
	# $self->{query}{foo} is always an array
	
	my @result;
	my %union_hash = map { $_ => 1 } (keys %arg_specs, keys %{$self->{query}});
	
	foreach my $key (keys %union_hash) {
	
		# return the values as a hash ref
	
		if (lc($arg_specs{$key}) eq 'hash') {
		
			if (defined($self->{query}{$key})) {
				push @result, $key, { map { $$_ } @{$self->{query}{$key}} };
			} else {
				push @result, $key, undef;
			}
		
		# return the values as an array ref
		
		} elsif (lc($arg_specs{$key}) eq 'array') {
		
			if (defined($self->{query}{$key})) {
				push @result, $key, [ map { $$_ } @{$self->{query}{$key}} ];
			} else {
				push @result, $key, undef;
			}
		
		# return a reference to the last value
		
		} elsif (lc($arg_specs{$key}) eq 'ref') {
		
			if (not defined($self->{query}{$key})) {
				push @result, $key, \undef;
			} else {
				my $array_size = scalar(@{$self->{query}{$key}});
				push @result, $key, $self->{query}{$key}[$array_size-1];

			}
		
		# return the last value as a scalar
		
		} else {
		
			if (not defined($self->{query}{$key})) {
				push @result, $key, undef;
			} else {
				my $array_size = scalar(@{$self->{query}{$key}});
				push @result, $key, ${$self->{query}{$key}[$array_size-1]};
			}			
				
		}
		
	}
	
	return @result;

}


#######################################

=head2 args_post:method

Call this to retrieve ONLY the QUERY arguments stored in the object
(this ignores the POST arguments)

	my %query_args = $http_obj->query_args();

	or

	my %query_args = $http_obj->query_args(
		foo => 'array',
		bar => 'hash',
		goo => 'ref',
	);

=cut

sub args_post:method {

	my ($self, %arg_specs) = @_;
	
	# Unless they asked for a hash, array, or ref, we
	# always return a scalar. The actual contents of 
	# $self->{post}{foo} is always an array
	
	my @result;
	my %union_hash = map { $_ => 1 } (keys %arg_specs, keys %{$self->{post}});
	
	foreach my $key (keys %union_hash) {
	
		# return the values as a hash ref
	
		if (lc($arg_specs{$key}) eq 'hash') {
		
			if (defined($self->{post}{$key})) {
				push @result, $key, { map { $$_ } @{$self->{post}{$key}} };
			} else {
				push @result, $key, undef;
			}
		
		# return the values as an array ref
		
		} elsif (lc($arg_specs{$key}) eq 'array') {
		
			if (defined($self->{post}{$key})) {
				push @result, $key, [ map { $$_ } @{$self->{post}{$key}} ];
			} else {
				push @result, $key, undef;
			}
		
		# return a reference to the last value
		
		} elsif (lc($arg_specs{$key}) eq 'ref') {
		
			if (not defined($self->{post}{$key})) {
				push @result, $key, \undef;
			} else {
				my $array_size = scalar(@{$self->{post}{$key}});
				push @result, $key, $self->{post}{$key}[$array_size-1];

			}
		
		# return the last value as a scalar
		
		} else {
		
			if (not defined($self->{post}{$key})) {
				push @result, $key, undef;
			} else {
				my $array_size = scalar(@{$self->{post}{$key}});
				push @result, $key, ${$self->{post}{$key}[$array_size-1]};
			}			
				
		}
		
	}
	
	return @result;

}


#######################################

=head2 arg_count:method

You can call this method with an argument name to
find out how many total arguments of that name
were submitted:

	my $count = $http_obj->arg_count('password');

=cut

sub arg_count:method {

	my ($self, $arg) = @_;
	
	unless (defined $self->{args}{$arg}) { return 0; }
	return scalar(@{$self->{args}{$arg}});

}



#######################################

=head2 arg_headers:method

When a mime-multipart post was submitted, you can
call this method with an argument name to get back
all the headers that came with for that argument
parsed as a literal hash. Like this:

	my %file_headers = $http_obj->arg_headers('file');

=cut

sub arg_headers:method {

	my ($self, $arg) = @_;
	
	unless (defined $self->{arg_headers}{$arg}) {
		return;
	}
	
	return ( %{$self->{arg_headers}{$arg}} );

}



#######################################

=head2 read_get:method

Called internally, reads the arguments from the query string
and adds them to $self->{args}{...}

=cut

sub read_get:method {

	my $self = $_[0];

	# split up and parse the query
	
	foreach my $pair (split /&/, $ENV{QUERY_STRING}) {
		my ($name, $value) = map { $self->url_decode($_) } split(/=/, $pair);
		unless ($value eq '') {
			push @{$self->{args}{$name}}, \$value;
			push @{$self->{query}{$name}}, \$value;
		}	
	}

}


#######################################

=head2 read_post:method

Called internally, reads the arguments from STDIN
and adds them to $self->{args}{...}

=cut

sub read_post:method {

	my $self = $_[0];
	
	# split up and parse the POST
	
	read STDIN, my $input, $ENV{CONTENT_LENGTH};

	foreach my $pair (split /&/, $input) {
		my ($name, $value) = map { $self->url_decode($_) } split(/=/, $pair);
		unless ($value eq '') {
			push @{$self->{args}{$name}}, \$value;
			push @{$self->{post}{$name}}, \$value;
		}
	}

}


#######################################

=head2 read_mime_post:method

Called internally, reads the arguments from STDIN,
translates them from mime/multipart
and adds them to $self->{args}{...}

=cut

sub read_mime_post:method {

	my ($self, $mime_boundary) = @_;
	
	my $boundary_regex = qr/[-]+${mime_boundary}[ \r\n\t]*/;
	
	read STDIN, my $input, $ENV{CONTENT_LENGTH};
	
	# chop up the mime parts
	
	foreach my $chunk (split $boundary_regex, $input) {
	
		# snag the attributes
		
		my %headers;
		
		for ($chunk) {

			s/^\s+//s;
		
			while (s/^([-a-zA-Z0-9]+)\:\s*([^\n\r]+)(\r\n|\n)//) {
				$headers{lc($1)} = $2;
			}
			
			s/^\s+//s;
			s/\s+$//s;
		
		}
		
		if (length($chunk) > $self->{max_mime_size}) {
			$chunk = substr($chunk, $self->{max_mime_size});
		}
	
		if ($headers{'content-disposition'} =~ m/form-data\;\s*name\=\"(\w+)\"/) {
			push @{$self->{args}{$1}}, \$chunk;
			push @{$self->{post}{$1}}, \$chunk;
			$self->{arg_headers}{$1} = \%headers;
		}
	}

}


#######################################

=head2 url_decode

decodes a urlencoded string, replacing '+' with ' '
and %XX with the provided hex value we don;t bother to export this
stupid function, BTW

=cut

sub url_decode {
	
	my ($self, $string) = @_;
	
	for ($string) {
		$string =~ tr/+/ /;
		$string =~ s/%([\da-f][\da-f])/chr(hex($1))/egi;
	}
	
	if ($self->{charset} ne '') {
		return decode($self->{charset}, $string);
	}
	else {
		return $string;
	}
}


#it's a library!

1;
