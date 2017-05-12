package Locale::PO::Callback;

# TO DO:
#  - support encodings other than UTF-8

use strict;
use warnings;

use POSIX qw(strftime);

our $VERSION = 0.04;

sub new {
    my ($class, $callback) = @_;
    my $self = {
	callback => $callback,
    };

    return bless($self, $class);
}

sub read_string {
    my ($self, $string) = @_;

    $self->read($string, 1);
}

sub read_file {
    my ($self, $filename) = @_;

    $self->read($filename, 0);
}

sub read {
    my ($self, $filename, $is_string) = @_;

    if ($is_string) {
	open PO, '<', \$filename or die "Couldn't read string: $!";
    } else {
	open PO, "<$filename" or die "Couldn't open $filename: $!";
    }

    binmode PO, ":utf8";

    # Every line in a .po file is either:
    #  * a comment, applying to the next stanza
    #    (Some comments may have machine-readable meanings,
    #     but they remain comments)
    #  * a command, part of a stanza
    #  * a continuation of a previous command
    #  * something else, which should be passed through
    #
    # The first stanza may map the empty string to a non-empty
    # string, and if so it is magic and defines headers.

    my $empty_stanza = sub {
	{
	    comments => '',
	};
    };

    my $escaper = sub {
	my %escapes = (
	    'n' => "\n",
	    't' => "\t",
	    );
	my ($char) = @_;

	return $escapes{$char} if defined $escapes{$char};
	return $char;
    };

    my $unstring = sub {
	my ($str) = @_;
	$str =~ s/^"//;
	$str =~ s/"$//;
	$str =~ s/\\(.)/$escaper->($1)/ge;
	
	return $str;
    };

    my $first = 1;

    my $stanza = $empty_stanza->();

    # Which command a continuation is a continuation of.
    my $continuing = 'msgstr';

    my $handle_stanza = sub {
	if ($first) {

	    if ($stanza->{'msgid'} eq '') {
		# good, that's what we expected
		$stanza->{'type'} = 'header';
		$stanza->{'headers'} = {};
		$stanza->{'header_order'} = [];
		# FIXME allow for continuation lines
		# although nobody ever uses them
		for my $line (split /\n/, $stanza->{'msgstr'}) {
		    $line =~ /^(.*): (.*)$/;
		    $stanza->{'headers'}->{lc $1} = $2;
		    push @{ $stanza->{'header_order'} }, $1;
		}
		delete $stanza->{'msgid'};
		delete $stanza->{'msgstr'};
	    } else {
		# Oh dear, no header.  Fake one.
		$self->{callback}->({
		    type => 'header',
		    headers => {},
		    header_order => [],
				    });
	    }

	    $first = 0;
	} else {
	    $stanza->{'type'} = 'translation';
	    $stanza->{'locations'} = [];
	    $stanza->{'flags'} = {};
	    $stanza->{'comments'} = '' unless defined $stanza->{'comments'};

	    my @comments;

	    for my $comment (split /\n/, $stanza->{'comments'}) {
		if ($comment =~ /^#: (.*):(\d*)$/) {
		    push @{ $stanza->{'locations'} }, [$1, $2];
		} elsif ($comment =~ /^#, (.*)$/) {
		    my $flags = $1;
		    $flags =~ s/\s*,\s*/,/g;
		    for my $flag (split m/,/, $flags) {
			$stanza->{'flags'}->{lc $flag} = 1;
		    }
		} else {
		    push @comments, $comment;
		}
	    }

	    # Anything we didn't handle goes back in the comments field.
	    $stanza->{'comments'} = join("\n", @comments);
	}

	if (defined $stanza->{'msgid'} ||
	    defined $stanza->{'msgstr'} ||
	    defined $stanza->{'msgstr[0]'} ||
	    defined $stanza->{'headers'}
	    ) {
	    $self->{callback}->($stanza);
	}
    };

    while (<PO>) {
	chomp;
	if (/^$/) {
	    $handle_stanza->();
	    $stanza = $empty_stanza->();
	} elsif (/^#/) {
	    $stanza->{comments} .= $_ . "\n";
	} elsif (/^"/) {
	    $stanza->{$continuing} .= $unstring->($_);
	} elsif (/^([^ ]*) (".*)/) {
	    $stanza->{$1} = $unstring->($2);
	    $continuing = $1;
	} else {
	    $self->{callback}->({other => $_, type => 'other'});
	}
    }
    $handle_stanza->();
    close PO or die "Couldn't close $filename: $!";
}

sub create_empty {
    my ($self) = @_;

    my @fields = (
	['Project-Id-Version' => 'PACKAGE VERSION'],
	['PO-Revision-Date' => _today()],
	# FIXME: take this from the environment,
	# if it's available?
	['Last-Translator' => 'FULL NAME <EMAIL@ADDRESS>'],
	['Language-Team' => 'LANGUAGE <LL@li.org>'],
	['MIME-Version' => '1.0'],
	['Content-Type' => 'text/plain; charset=UTF-8'],
	['Content-Transfer-Encoding' => '8bit'],
	);

    my @fieldnames;
    my %fields;

    for (@fields) {
	push @fieldnames, $_->[0];
    }

    for (@fields) {
	$fields{lc $_->[0]} = $_->[1];
    }

    $self->{callback}->({type => 'header',
			 headers => \%fields,
			 header_order => \@fieldnames,
			});
}

sub rebuilder {
    my ($callback) = @_;

    $callback = sub { print $_[0]; } unless $callback;

    return sub {
	my ($stanza) = @_;

	my $output_line = sub {
	    my ($keyword) = @_;
	    my $text = $stanza->{$keyword};
	    my $max_width = 79;

	    return '' unless defined $text;

	    $text =~ s/\\/\\\\/g;
	    $text =~ s/\t/\\t/g;
	    $text =~ s/\n/\\n/g;
	    $text =~ s/\"/\\"/g;

	    # Test the simple case first
	    if (length($keyword) + 4 + length($text) <= $max_width) {
		return "$keyword \"$text\"\n";
	    }

	    my $result = "$keyword \"\"\n";

	    my @words;

	    while ($text) {
		$text =~ s/^(\S*\s*)//;
		push @words, $1;
	    }

	    my $temp = '';
    
	    for (@words) {
		if (length($temp . $_) >= $max_width) {
		    if ($temp) {
			$result .= "\"$temp\"\n";
			$temp = $_;
		    } else {
			$result .= "\"$_\"\n";
		    }
		} else {
		    $temp .= $_;
		}
	    }

	    $result .= "\"$temp\"\n" if $temp;
	    
	    return $result;
	};

	my $result = '';

	if ($stanza->{'type'} eq 'translation') {
	    $result .= $stanza->{'comments'}."\n" if $stanza->{'comments'};
	    for my $flag (keys %{$stanza->{'flags'}}) {
		$result .= "#, $flag\n";
	    }
	    for my $location (@{$stanza->{'locations'}}) {
		$result .= "#: $location->[0]:$location->[1]\n";
	    }
	    $result .= $output_line->('msgctxt');
	    $result .= $output_line->('msgid');
	    $result .= $output_line->('msgid_plural');
	    for my $msgstr (grep { /^msgstr/ } sort keys %$stanza) {
		$result .= $output_line->($msgstr);
	    }
	    $result .= "\n";
	} elsif ($stanza->{'type'} eq 'header') {
	    $result .= $stanza->{'comments'} if $stanza->{'comments'};
	    $result .= "msgid \"\"\n";
	    $result .= "msgstr \"\"\n";
	    my %seen;
	    for my $header (@{$stanza->{'header_order'}}) {
		my $value = $stanza->{'headers'}->{lc $header};
		$result .= "\"$header: $value\\n\"\n";
		$seen{lc $header} = 1;
	    }
	    for my $header (keys %{$stanza->{'headers'}}) {
		$header = lc $header;
		next if defined $seen{$header};
		my $value = $stanza->{'headers'}->{$header};
		$header =~ s/\b(.)/\u$1/g; # titlecase
		$result .= "\"$header: $value\\n\"\n";
	    }
	    $result .= "\n";
	} elsif ($stanza->{'type'} eq 'other') {
	    $result .= '# (other:) '.$stanza->{'other'}."\n";
	} else {
	    die "Unknown type $stanza->{'type'}";
	}

	$callback->($result);
    };
}

sub _today {
    return strftime("%Y-%m-%d %H:%M %z", localtime);
}

sub set_date {
    my ($callback) = @_;

    return sub {
	my ($param) = @_;

	if ($param->{'type'} eq 'header') {
	    my $date_found = defined $param->{'headers'}->{'po-revision-date'};

	    $param->{'headers'}->{'po-revision-date'} = _today();

	    push @{$param->{'header_order'}}, 'PO-Revision-Date'
		unless $date_found;
	}

	$callback->($param);
    };
}

1;

=head1 NAME

Locale::PO::Callback - parse gettext source files

=head1 AUTHOR

Thomas Thurman <thomas@thurman.org.uk>

=head1 SYNOPSIS

  use Locale::PO::Callback;

  sub callback {
     # ...
  }

  my $lpc = Locale::PO::Callback->new(\&callback);
  $lpc->read('test.po');

=head1 DESCRIPTION

This module parses the .po files used by GNU gettext
to hold translation catalogues.  It takes one parameter,
a coderef, and calls it repeatedly with a description of
every item in the file.  This enables chains of filters
to be produced, as is commonly done with XML processing.

=head1 METHODS

=head2 new(callback)

Creates an object.  The callback parameter is a coderef
which will be called with a description of every item
in the file.

=head2 read_file(filename)

Reads and parses a file.

=head2 read_string(string)

Parses a string.

=head2 read(filename_or_string, is_string)

Reads and parses a file or a string, depending on the is_string
argument.

=head2 create_empty()

Behaves as though we had just read in an empty file,
with default headers.

=head1 OTHER THINGS

=head2 rebuilder(coderef)

Given a coderef, this function returns a function which
can be passed as a callback to this class's constructor.
The coderef will be called with strings which, if concatenated,
make a .po file equivalent to the source .po file.

In pipeline terms, this function produces sinks.

=head2 set_date(coderef)

Given a coderef, this function returns a function which
can be passed as a callback to this class's constructor.
The function will pass its parameters through to the
coderef unchanged, except for headers, when the file date
will be changed to the current system date.

In pipeline terms, this function produces filters.

=head1 PARAMETERS TO THE CALLBACK

=head2 type

"header", "translation", or "other" (which last should never
appear in ordinary use).

=head2 comments

An arrayref of comments which appear before this item.

=head2 flags

A hashref of the flags of this item (such as "fuzzy").

=head2 locations

An arrayref of arrayrefs, the first item being a filename
and the second being a line number.

=head2 msgid

The source message, in its singular form.

=head2 msgid_plural

The source message, in its plural form.
This is usually empty.

=head2 msgstr

The translation, if any,
unless this translation has plural forms,
in which case see the next entry.

=head2 msgstr[0] (etc)

Variations on the translation for different plural forms.

=head2 msgctxt

The "context" of the translation.
Rarely filled in.

=head2 headers

A hashref of headers, mapping fieldnames to values.
The keys are lowercased.

=head2 header_order

An arrayref of the header fieldnames, in the casing and order
in which they were found.

=head1 FUTURE EXPANSION

We need to support encodings other than UTF-8.

This documentation was written in a bit of a rush.

=head1 COPYRIGHT

This Perl module is copyright (C) Thomas Thurman, 2010.
This is free software, and can be used/modified under the same terms as
Perl itself.


