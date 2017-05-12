# $Id: Nested.pm 4647 2010-03-09 18:10:10Z chris $

=head1 NAME

HTML::PullParser::Nested - Wrapper around HTML::PullParser with awareness of tag nesting.


=head1 SYNOPSIS

use HTML::PullParser::Nested;

    my $p = HTML::PullParser::Nested->new(
        doc         => \ "<html>...<ul><li>abcd<li>efgh<li>wvyz</ul>...<ul><li>1<li>2<li>9</ul></html>",
        start       => "'S',tagname,attr,attrseq,text",
        end         => "'E',tagname,text",
        text        => "'T',text,is_cdata",
        );
    
    while (my $token = $p->get_token()) {
        if ($token->[0] eq "S" && $token->[1] eq "ul") {
            $p->push_nest($token);
            print "List:\n";
            while (my $token = $p->get_token()) {
                if ($token->[0] eq "S" && $token->[1] eq "li") {
                    print $p->get_token()->[1], "\n";
                }
            }
            print "\n";
            $p->pop_nest();
        }
    }


=head1 DESCRIPTION

This class is a wrapper around HTML::PullParser with awareness of the nesting
of tags.

There is a cursor, which points to the current position within the 
document.  It should be thought of as pointing to the start of the 
next token, or to 'EOL' (eof of level).

Tokens can be read sequentially, and the cursor will be advanced after 
each read.  They can also be unread, reversing any effects of their having
been read.

As noted, the class is aware of tag nesting, giving the concept of 
nesting levels.  Level 1 encompasses the whole document.  As any point
a new nesting level can be pushed on, specifying a tag type.  In effect, 
the parser then behaves as if it had instead been opened on a document
only containing the content up the closing tag.  It is then possible to
pop a nesting level, which then moves the cursor to the start of the 
closing tag and switches to the parent nesting level.

=cut


package HTML::PullParser::Nested;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;

use HTML::PullParser;

=head1 METHODS

=head2 new(file => $file, %options), new(doc => \$doc, %options)

Constructor.  %options gets passed to the encapsulated HTML::PullParser 
object and largely has the same restrictions.  As HTML::PullParser::Nested
needs to be able to process tokens returned by HTML::PullParser, there are
some restrictions on the argspecs for each token type.  Firstly, so that
the token type can be identified, either event, or distinct literal strings
must be present at the same array index in the argspec for each returned
token type.  For start and end tags, tagname must also be present somewhere.

=head2 get_token()

Read and return the next token and advance the cursor.  If the cursor 
points to eol, undef will be returned on the first read attempt, and 
an error raised thereafter.

=head2 unget_token(@tokens)

Reverse the effects of get_token().

=head2 eol()

End of level flag.  Returns true after get_token() has returned undef to 
signify end of level.

=head2 push_nest($token)

Push a new nesting level onto the stack.  $token should be on start 
tag.  The current level will now correspond of all tags up to the 
corresponding close tag.

The corresponding closing tag is determined by counting the start and 
end tags of the current nesting level.  This means that if 

    <a>
        <b>
            <a>
            <a>
            <a>
        </b>
    </a>

is encountered whilst the current nesting level is tracking <a> tags, 
the parser will end either end up 3 tags deeper or at the same depth 
depending whether push_nest(), pop_nest() are called for the <b> tag. 

It is safe to call push_nest() twice for the same tag type.

=head2 pop_nest()

Pop a nesting level from the stack.  Skips to the end of the current
nesting level if necessary.

=cut


sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};

    bless $self, $class;

    $self->_parse_argspecs(%args);
    $self->{'p'} = HTML::PullParser->new(%args);
    $self->{'nest'} = [{'tagname' => undef, 'depth' => 0}];
    
    return $self;

}

sub push_nest {
    my $self = shift;
    my $token = shift;

    my $tagname = $self->_canon_token($token)->[1];;

    unshift @{$self->{'nest'}}, {'tagname' => $tagname, 'depth' => 0};

}

sub pop_nest {
    my $self = shift;

    my $nest = $self->{'nest'}->[0];

    if (scalar @{$self->{'nest'}} == 1) {
	croak "nesting level underflow";
    }

    if ($nest->{'depth'} >= 0) {
	while ($self->get_token()) { }
	die "Assert failed" unless ($nest->{'depth'} == -1);
    }

    shift  @{$self->{'nest'}};

}

sub eol {
    my $self = shift;

    my $nest = $self->{'nest'}->[0];

    return $nest->{'depth'} == -1;

}

sub get_token {
    my $self = shift;

    my $nest = $self->{'nest'}->[0];

    if ($nest->{'depth'} == -1) { croak "read past eol"; }

    my $token = $self->{'p'}->get_token();
    my $canon = $self->_canon_token($token);

    if (scalar @{$self->{'nest'}} == 1) {
	if (!defined $canon) {
	    $nest->{'depth'}--;
	    die "Assert failed" unless ($nest->{'depth'} == -1);
	}
    } else {
	if (!defined $canon) {
	    croak "tokens don't nest correctly";
	} elsif ($canon->[0] =~ m/^(?:start|end)$/) {
	    if ($canon->[1] eq $nest->{'tagname'}) {
		if ($canon->[0] eq "start") {
		    $nest->{'depth'}++;
		} else {
		    $nest->{'depth'}--;
		    if ($nest->{'depth'} == -1) {
			$self->{'p'}->unget_token($token); # Leave token for parent level;
			$token = undef; $canon = undef;
		    }
		}
	    }
	}
    }

    return $token;

}

sub unget_token {
    my $self = shift;

    my $nest = $self->{'nest'}->[0];

    while (@_) { # Need to recognise undef items in arg list.
	my $token = shift;
	my $canon = $self->_canon_token($token);
	if (scalar @{$self->{'nest'}} == 1) {
	    if (!defined $canon) {
		$nest->{'depth'}++;
		die "Assert failed" unless ($nest->{'depth'} == 0);
	    }	    
	} else {
	    if (!defined $canon) {
		$nest->{'depth'}++;
		die "Assert failed" unless ($nest->{'depth'} == 0);
		next; # Don't want to add token back onto stack, that was done in get_token()
	    
	    } elsif ($canon->[0] =~ m/^(?:start|end)$/) {
		if ($canon->[1] eq $nest->{'tagname'}) {
		    if ($canon->[0] eq "start") {
			$nest->{'depth'}--;
			if ($nest->{'depth'} == -1) {
			    croak "nesting tag underflow";
			}
		    } else {
			$nest->{'depth'}++;
		    }
		}
	    }
	}

	$self->{'p'}->unget_token($token);

    }

}

# HTML::PullParser allows the client to supply an argspec, specifying what data about a token should be
# returned by get_token().  We want to preserve this flexibility, but also need to be able to process
# start and end tags returned by get_token().  We therefore parse the argspecs supplied by the client 
# to try to find a way to turn this format into a canonical token with argspec "event,tagname" for
# start / end tags (and "'other'" for other tokens).
sub _parse_argspecs {
    my $self = shift;
    my %args = @_;
    if (!defined $args{'start'} || !defined $args{'end'}) { croak "need argspec for start and end"; }

    # Firstly, for each token type, get the array index of (if present) event, tagname and literal string (plus the string content)
    my $argspec_info = {};
    foreach (qw(start end text process comment declaration)) {
	if (defined $args{$_}) {
	    $argspec_info->{$_} = $self->_parse_argspec($args{$_});
	}
    }

    # Now try to find an array index corresponding to either event or a literal string for each token type.
    my $arg_idx = { map {$_ => -1} qw(event_idx string_idx)  };
    foreach my $event (keys %$argspec_info) {
	foreach ( qw(event_idx string_idx) ) {
	    if (defined $arg_idx->{$_} && $arg_idx->{$_} == -1) {
		$arg_idx->{$_} = $argspec_info->{$event}->{$_};
	    } elsif ( defined $arg_idx->{$_} && (!defined $argspec_info->{$event}->{$_} || $arg_idx->{$_} != $argspec_info->{$event}->{$_}) ) {
		$arg_idx->{$_} = undef;
	    }
	}
    }


    # Finally, store the info require to identify each token type (and tag name).
    $self->{'arg_info'} = {};

    # We can now identidy the token type either by event, or by the literal string.
    if (defined $arg_idx->{'event_idx'}) {
	$self->{'arg_info'}->{'event_idx'} = $arg_idx->{'event_idx'};
    } elsif (defined $arg_idx->{'string_idx'}) {
	my %strs = map {$argspec_info->{$_}->{'string'} => 1} keys %$argspec_info;
	if (keys %strs != keys %$argspec_info) { croak "'string' must be unique across all argspecs"; }
	$self->{'arg_info'}->{'string_idx'} = $arg_idx->{'string_idx'};
	$self->{'arg_info'}->{'start_string'} = $argspec_info->{'start'}->{'string'};
	$self->{'arg_info'}->{'end_string'} = $argspec_info->{'end'}->{'string'};
    } else {
	croak "need either event or 'string' at a consistent index across all argspecs"
    }

    # For start and end tags, we also need the tagname.
    if (defined $argspec_info->{'start'}->{'tagname_idx'} && defined defined $argspec_info->{'end'}->{'tagname_idx'} ) {
	$self->{'arg_info'}->{'start_tagname_idx'} = $argspec_info->{'start'}->{'tagname_idx'};
	$self->{'arg_info'}->{'end_tagname_idx'} = $argspec_info->{'end'}->{'tagname_idx'};
    } else {
	croak "need tagname in argspec for start and end tags";
    }

}

# Get the array index of (if present) event, tagname and literal string (plus the string content)
sub _parse_argspec {
    my $self = shift;
    my @argspec = split(/,/, shift);

    my $i;
    my ($event_idx, $tagname_idx, $string_idx, $string);

    for ($i = 0; $i < @argspec; $i++) {
	if ($argspec[$i] eq "event" && !defined $event_idx) {
	    $event_idx = $i;
	} elsif ($argspec[$i] eq "tagname" && !defined $tagname_idx) {
	    $tagname_idx = $i;
	} elsif ((my ($str) = $argspec[$i] =~ m/^'(.+)'$/) && !defined $string_idx) {
	    $string_idx = $i;
	    $string = $str;
	}
    }

    return {'event_idx' => $event_idx, 'tagname_idx' => $tagname_idx, 'string_idx' => $string_idx, 'string' => $string};

}

# For start + end tags, return result in the form "event,tagname".  For other tokens, uses the form "'other'"
sub _canon_token {
    my $self = shift;
    my $token = shift;
    my $canon = [];

    if (!defined $token) {
	return undef;
    } elsif (defined $self->{'arg_info'}->{'event_idx'}) {
	$canon->[0] = $token->[$self->{'arg_info'}->{'event_idx'}];
	if ($canon->[0] !~ m/^(?:start|end)$/) { $canon->[0] = "other";	} # Flatten other token types to 'other' for consistency with detection based upon string.
    } elsif (defined $self->{'arg_info'}->{'string_idx'}) {
	if ($token->[$self->{'arg_info'}->{'string_idx'}] eq $self->{'arg_info'}->{'start_string'}) {
	    $canon->[0] = "start";
	} elsif ($token->[$self->{'arg_info'}->{'string_idx'}] eq $self->{'arg_info'}->{'end_string'}) {
	    $canon->[0] = "end";
	} else {
	    $canon->[0] = "other";
	}
    }

    if ($canon->[0] eq "start") {
	$canon->[1] = $token->[$self->{'arg_info'}->{'start_tagname_idx'}];
    } elsif ($canon->[0] eq "end") {
	$canon->[1] = $token->[$self->{'arg_info'}->{'end_tagname_idx'}];
    }

    return $canon;
}

1;

=head1 SEE ALSO

L<HTML::PullParser>


=head1 AUTHOR

Christopher Key <cjk32@cam.ac.uk>


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010 Christopher Key <cjk32@cam.ac.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
