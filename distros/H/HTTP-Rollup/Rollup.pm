package HTTP::Rollup;

require 5.005;

use strict;
use CGI::Util qw( unescape );
use Exporter;

use vars qw($VERSION @ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(RollupQueryString);

$VERSION = '0.8';

my $DEFAULT_DELIMITER = "&";

# Turn on special checking for Doug MacEachern's modperl
my $MOD_PERL = 0;
if (exists $ENV{MOD_PERL}) {
    if ($ENV{MOD_PERL_API_VERSION} == 2) {
        $MOD_PERL = 2;
        require Apache2::RequestUtil;
        require APR::Table;
    } else {
        $MOD_PERL = 1;
        require Apache;
    }
}

=head1 NAME

HTTP::Rollup - translate an HTTP query string to a hierarchical structure

=head1 SYNOPSIS

 use HTTP::Rollup qw(RollupQueryString);

 my $rollup = new HTTP::Rollup;

 my $hashref = $rollup->RollupQueryString($query_string);

=head1 DESCRIPTION

Given input text of the format:

  employee.name.first=Jane
  employee.name.last=Smith
  employee.address=123%20Main%20St.
  employee.city=New%20York
  id=444
  phone=(212)123-4567
  phone=(212)555-1212
  @fax=(212)999-8877

Construct an output data structure like this:

  $hashref = {
    employee => {
		  name => {
			   "first" => "Jane",
			   "last" => "Smith",
			  },
		  address => "123 Main St.",
		  city => "New York"
		},
    phone => [
	       "(212)123-4567",
	       "(212)555-1212"
	     ],
    fax => [
	     "(212)999-8877"
	   ],
    id => 444
  };

This is intended as a drop-in replacement for the HTTP query string
parsing implemented in CGI.pm, adding the ability to assemble a nested
data structure (CGI.pm constructs purely flat structures).

e.g. given the sample input above, CGI.pm would produce:

  $hashref = {
    "employee.name.first" => [ "Jason" ],
    "employee.name.last" => [ "Smith" ],
    "employee.name.address" => [ "123 Main St." ],
    "employee.name.city" => [ "New York" ],
    "phone" => [ "(212)123-4567", "(212)555-1212" ],
    "@fax"=> [ "(212)999-8877" ],
    "id" => [ 444 ]
  };

If no $query_string parameter is provided, HTTP::Rollup will attempt to find
the input in the same manner used by CGI.pm (the internal _query_string
function is pretty much cloned from CGI.pm).

HTTP::Rollup runs under both CGI or mod_perl contexts, and from the
command line (reads from @ARGV or stdin).

=head1 FEATURES

=over

=item *

Data nesting using dot notation

=item *

Recognizes a list if there is more than one value with the same name

=item *

Lists can be forced with a leading @-sign, to allow for lists that could
have just one element (eliminating ambiguity between scalar and single-
element list).  The @ will be stripped.

=back

=head1 FUNCTIONS

=item new([ FORCE_LIST => 1 ], [ DELIM => ";" ])

The FORCE_LIST switch causes CGI.pm-style behavior, as above,
for backward compatibility.

The DELIM option specifies the input field delimiter.  This is not
auto-detected.  Default is the standard ampersand, though semicolon has
been proposed as a replacement to avoid conflict with the ampersand used
for character entities.

Specifying "\n" for the delimiter is helpful for parsing parameters on stdin.

=item RollupQueryString()

Workhorse function.

=begin testing

use lib "./blib/lib";
use HTTP::Rollup qw(RollupQueryString);
use Data::Dumper;

my $s1 = "one=abc&two=def&three=ghi";
my $r1 = new HTTP::Rollup;
my $hr = $r1->RollupQueryString($s1); # default delimiter
ok ($hr->{one} eq "abc");
ok ($hr->{two} eq "def");
ok ($hr->{three} eq "ghi");

my $string = <<_END_;
employee.name.first=Jane
employee.name.last=Smith
employee.address=123%20Main%20St.
employee.city=New%20York
id=444
phone=(212)123-4567
phone=(212)555-1212
\@fax=(212)999-8877
_END_

my $r2 = new HTTP::Rollup(DELIM => "\n");
my $hashref = $r2->RollupQueryString($string);
ok($hashref->{employee}->{name}->{first} eq "Jane",
   "2-nested scalar");
ok($hashref->{employee}->{city} eq "New York",
   "1-nested scalar, with unescape");
ok($hashref->{id} eq "444",
   "top-level scalar");
ok($hashref->{phone}->[1] eq "(212)555-1212",
   "auto-list");
ok($hashref->{fax}->[0] eq "(212)999-8877",
   "\@-list");

my $string2 = "employee.name.first=Jane;employee.name.last=Smith;employee.address=123%20Main%20St.;employee.city=New%York;id=444;phone=(212)123-4567;phone=(212)555-1212;\@fax=(212)999-8877";

my $r3 = new HTTP::Rollup(DELIM => ";");
$hashref = $r3->RollupQueryString($string2);
ok($hashref->{employee}->{name}->{first} eq "Jane",
   "nested scalar");
ok($hashref->{id} eq "444",
   "top-level scalar");
ok($hashref->{phone}->[1] eq "(212)555-1212",
   "auto-list");
ok($hashref->{fax}->[0] eq "(212)999-8877",
   "\@-list");

my $r4 = new HTTP::Rollup(FORCE_LIST => 1, DELIM => "\n");
my $hashref2 = $r4->RollupQueryString($string);
ok($hashref2->{'employee.name.first'}->[0] eq "Jane",
   "nested scalar");
ok($hashref2->{id}->[0] eq "444",
   "top-level scalar");
ok($hashref2->{phone}->[1] eq "(212)555-1212",
   "auto-list");
ok($hashref2->{'@fax'}->[0] eq "(212)999-8877",
   "\@-list");

=end testing

=cut

my %legal_parameters = (
			FORCE_LIST => 1,
			DELIM => 1,
		       );
sub new {
    my $cl  = shift;
    my $class = ref($cl) || $cl;
    my %params = @_;

    my $self = {};
    bless $self, $class;

    for my $param (keys %params) {
	if ($legal_parameters{$param}) {
	    $self->{$param} = $params{$param};
	} else {
	    print STDERR __PACKAGE__, ": illegal config parameter $param\n";
	}
    }

    return $self;
}

sub RollupQueryString {
    my $self = shift;
    my $input = shift;

    my $delimiter = $self->{DELIM} || $DEFAULT_DELIMITER;

    if (!defined $input) {
	$input = _query_string();
    }

    my $root = {};

    return $root if !$input;

    # query strings are name-value pairs delimited by & or by newline or semicolon
    foreach my $nvp (split(/$delimiter/, $input)) {
	last if $nvp eq "=";	# sometimes appears as query string terminator

      PARSE:
	my ($name, $value) = split /=/, $nvp;
	my @levels = split /\./, $name;
	$value = CGI::Util::unescape($value);

	if ($self->{FORCE_LIST}) {
	    # always use a list, for CGI.pm-style behavior
	    if (ref $root->{$name}) {
		# there's already a list there
		push @{$root->{$name}}, $value;
	    } else {
		$root->{$name} = [ $value ];
	    }
	    next;
	}

      TRAVERSE:
	my $node = $root;
	my $leaf;
	for ($leaf = shift @levels;
	     scalar(@levels) >= 1;
	     $leaf = shift @levels) {
	    $node->{$leaf} = {}
	      unless defined $node->{$leaf};	# vivify
	    $node = $node->{$leaf};
	}

      SAVE:
	if (ref $node->{$leaf}) {
	    # there's already a list there
	    $leaf =~ s/^@//;
	    push @{$node->{$leaf}}, $value;
	} elsif (defined $node->{$leaf}) {
	    # scalar now, convert to a list
	    $node->{$leaf} = [ $node->{$leaf}, $value ];
	} elsif ($leaf =~ /^\@/) {
	    # leading @ forces list
	    $leaf =~ s/^@//;
	    $node->{$leaf} = [ $value ];
	} else {
	    $node->{$leaf} = $value;
	}
    }

    return $root;
}


# Most of the following was copied from CGI.pm (some version <2.8).
# Frozen here to avoid breakage on CGI changes, and to allow local
# alterations (e.g. support for PUT).

sub _query_string {
    my $meth = $ENV{'REQUEST_METHOD'};
    my $query_string;

    if (!defined $meth) {
	# no REQUEST_METHOD, so must be command-line usage

	return _read_from_cmdline();
    }

    if ($meth =~ /^(GET|HEAD)$/o) {
	if ($MOD_PERL == 1) {
	    return Apache->request->args;
	} elsif ($MOD_PERL ==2) {
	    return Apache2::RequestUtil->request->args;
	} else {
	    # CGI mode, not mod_perl
	    return $ENV{QUERY_STRING} ||  $ENV{REDIRECT_QUERY_STRING};
	}
    }

    # this is a POST

    my $content_length = $ENV{CONTENT_LENGTH} || 0;

    _read_from_client(\*STDIN,
		      \$query_string,
		      $content_length,
		      0)
      if $content_length > 0;

    # Have our cake and eat it too! (see CGI.pm)
    # Append query string contents to the POST data.
    if ($ENV{QUERY_STRING}) {
	$query_string .= (length($query_string) ? '&' : '') . $ENV{QUERY_STRING};
    }
    return $query_string;
}

sub _read_from_client {
    my($fh, $buff, $len, $offset) = @_;
    local $^W=0;                # prevent a warning
    return undef unless defined($fh);
    return read($fh, $$buff, $len, $offset);
}

# Note: multiple parameters on cmdline are always linked with ampersand;
# so better not change DELIM for this input style.

sub _read_from_cmdline {
    my($input,@words);
    my($query_string);

    if (@ARGV) {
	@words = @ARGV;
    } else {
	my @lines;
	chomp(@lines = <STDIN>); # remove newlines
	$input = join(" ",@lines);
	@words = _shellwords($input);    
    }
    foreach (@words) {
	s/\\=/%3D/g;
	s/\\&/%26/g;	    
    }

    if ("@words"=~/=/) {
	$query_string = join('&',@words);
    } else {
	$query_string = join('+',@words);
    }

    return $query_string;
}

# Taken from shellwords.pl in the Perl 5.6 distribution.
#
# Usage:
#	@words = &shellwords($line);
#	or
#	@words = &shellwords(@lines);
#	or
#	@words = &shellwords;		# defaults to $_ (and clobbers it)

sub _shellwords {
    local ($_) = join('', @_) if @_;
    my (@words, $snippet, $field);

    s/^\s+//;
    if ($_ ne '') {
	$field = '';
	for (;;) {
	    if (s/^"(([^"\\]|\\.)*)"//) {
		($snippet = $1) =~ s#\\(.)#$1#g;
	    }
	    elsif (/^"/) {
		die "Unmatched double quote: $_\n";
	    }
	    elsif (s/^'(([^'\\]|\\.)*)'//) {
		($snippet = $1) =~ s#\\(.)#$1#g;
	    }
	    elsif (/^'/) {
		die "Unmatched single quote: $_\n";
	    }
	    elsif (s/^\\(.)//) {
		$snippet = $1;
	    }
	    elsif (s/^([^\s\\'"]+)//) {
		$snippet = $1;
	    }
	    else {
		s/^\s+//;
		last;
	    }
	    $field .= $snippet;
	}
	push(@words, $field);
    }
    @words;
}

1;

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
