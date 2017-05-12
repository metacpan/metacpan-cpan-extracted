package HTML::ListScraper;

use warnings;
use strict;

use HTML::Parser;
use Class::Generate qw(class);

use HTML::ListScraper::Vat;
use HTML::ListScraper::Book;
use HTML::ListScraper::Sweep;

use vars qw(@ISA);

class 'HTML::ListScraper::Sequence' => {
    len => { type => '$', required => 1, readonly => 1 },
    instances => { type => '@', required => 1 }
};

class 'HTML::ListScraper::Instance' => {
    start => { type => '$', required => 1, readonly => 1 },
    match => { type => '$', required => 1, readonly => 1 },
    score => { type => '$', required => 0, readonly => 1 },
    tags => { type => '@', required => 1 }
};

@ISA = qw(HTML::Parser);

our $VERSION = '0.08';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    $self->{book} = HTML::ListScraper::Book->new();
    $self->{min_count} = 2;

    $self->handler('start' => 'on_start', 'self, tagname, attr');
    $self->handler('text' => 'on_text', 'self, dtext');
    $self->handler('end' => 'on_end', 'self, tagname');

    return $self;
}

sub min_count {
    my $self = shift;

    if (@_) {
        if ($_[0] < 2) {
	    die "minimal sequence count must be at least 2";
	}

        $self->{min_count} = $_[0];
    }

    return $self->{min_count};
}

sub shapeless {
    my $self = shift;

    if (@_) {
        $self->{book}->shapeless($_[0]);
    }

    return $self->{book}->shapeless;
}

sub is_unclosed_tag {
    my ($self, $name) = @_;

    return $self->{book}->is_unclosed_tag($name);
}

sub get_all_tags {
    my $self = shift;

    return $self->{book}->get_all_tags();
}

sub get_sequences {
    my $self = shift;

    my @sequences;
    my $vat = HTML::ListScraper::Vat->new($self->{book}, $self->{min_count});
    my $foam = $vat->create_sequence;
    if ($foam) {
        foreach my $handle ($foam->get_sequences) {
	    my $occ = $foam->get_occurence($handle);
	    push @sequences, $self->_make_sequence($occ);
	}
    }

    return sort {
        $a->len <=> $b->len;
    } @sequences;
}

sub find_sequences {
    my $self = shift;

    my @sequences;
    my $vat = HTML::ListScraper::Vat->new($self->{book}, $self->{min_count});
    my $foam = $vat->create_sequence;
    if ($foam) {
        foreach my $sign ($foam->get_sequences) {
	    my $occ = $foam->get_occurence($sign);
	    push @sequences, $self->_make_approx_seq($sign, $occ);
	}
    }

    return sort {
        $a->len <=> $b->len;
    } @sequences;
}

sub _get_known_occ {
    my ($self, $needle) = @_;

    my $len = length($needle);

    my $haystack = join '', $self->{book}->get_internal_sequence;

    my $occ = undef;
    my $pos = index($haystack, $needle);
    while ($pos >= 0) {
        if (!defined($occ)) {
	    $occ = HTML::ListScraper::Occurence->new($len, $pos);
	} else {
	    $occ->append_pos($pos);
	}

        $pos = index($haystack, $needle, $pos + $len);
    }

    return $occ;
}

sub get_known_sequence {
    my $self = shift;

    my $len = scalar(@_);
    if ($len < 2) {
        die "need at least 2 items to look for";
    }

    my $needle = '';
    foreach (@_) {
        my $internal = $self->{book}->get_internal_name($_);
	if (!defined($internal)) { # sequence not found if item not found
	    return undef;
	}

	$needle .= $internal;
    }

    my $occ = $self->_get_known_occ($needle);
    return !defined($occ) ? undef : $self->_make_sequence($occ);
}

sub find_known_sequence {
    my $self = shift;

    my $len = scalar(@_);

    if ($len < 2) {
        die "need at least 2 items to look for";
    }

    my @tags = @_;

    my $sign = '';
    foreach (@tags) {
        my $iname = $self->{book}->intern_name($_);
	$sign .= $iname;
    }

    my $occ = $self->_get_known_occ($sign);
    if ($occ) {
        return $self->_make_approx_seq($sign, $occ);
    } else {
	return $self->_make_whole_seq($sign);
    }
}

sub _make_approx_seq {
    my ($self, $sign, $occ) = @_;

    my $len = $occ->len;
    my $edge;
    my @instances;
    foreach my $pos ($occ->positions) {
        my $gap;
	if (!defined($edge)) {
	    $gap = 0;
	} elsif ($pos >= $edge + $len) {
	    $gap = $edge + $len;
	}

	if (defined($gap)) {
	    push @instances,
	        $self->_make_approx_inst($sign, $gap, $pos);

	    my @tags = $self->{book}->get_tags($pos, $len);
	    push @instances,
	        HTML::ListScraper::Instance->new(start => $pos,
		    match => 'exact', tags => \@tags);
	    $edge = $pos;
	}
    }

    if (!defined($edge)) {
        die "no occurence";
    }

    my $iseq = $self->{book}->get_internal_sequence;
    my $end = scalar(@$iseq);
    push @instances,
        $self->_make_approx_inst($sign, $edge + $len, $end);

    return HTML::ListScraper::Sequence->new(len => $len,
        instances => \@instances);
}

sub _make_whole_seq {
    my ($self, $sign) = @_;

    my $iseq = $self->{book}->get_internal_sequence;
    my $end = scalar(@$iseq);
    my @instances = $self->_make_approx_inst($sign, 0, $end);

    my $seq = undef;
    if (scalar(@instances)) {
        $seq = HTML::ListScraper::Sequence->new(len => length($sign),
            instances => \@instances);
    }

    return $seq;
}

sub _make_approx_inst {
    my ($self, $sign, $begin, $end) = @_;

    my $size = $end - $begin;
    if ($size < 2) {
        return ();
    }

    my $sweep = HTML::ListScraper::Sweep->new(
        book => $self->{book}, sign => $sign,
        begin => $begin, end => $end);
    my $dust = $sweep->create_dust;
    my @instances;
    foreach my $align ($dust->get_alignments) {
        my @tags;
	foreach my $pos ($align->positions) {
	    my $t = $self->{book}->get_tag($pos);
	    push @tags, $t;
	}

	my $start = $tags[0]->index;
	push @instances,
	    HTML::ListScraper::Instance->new(start => $start,
		match => 'approx', score => $align->score,
		tags => \@tags);
    }

    return @instances;
}

sub _make_sequence {
    my ($self, $occ) = @_;

    my $len = $occ->len;
    my $edge;
    my @instances;
    foreach my $pos ($occ->positions) {
	if (!defined($edge) || ($pos >= $edge + $len)) {
	    my @tags = $self->{book}->get_tags($pos, $len);
	    push @instances,
	        HTML::ListScraper::Instance->new(start => $pos,
		    match => 'exact', tags => \@tags);
	    $edge = $pos;
	}
    }

    return HTML::ListScraper::Sequence->new(len => $len,
        instances => \@instances);
}

sub _is_tag {
    my ($self, $tag) = @_;

    return $tag =~ m/^[a-z0-9-:]+$/i;
}

sub on_start {
    my ($self, $rtag, $attr) = @_;

    my $tag = $rtag;
    $tag =~ s/\s*\/$//;

    if (!$self->_is_tag($tag)) {
        $self->{book}->append_text($tag);
	return;
    }

    if (exists($attr->{href}) && $attr->{href}) {
	$self->{book}->push_link($tag, $attr->{href});
    } else {
	$self->{book}->push_item($tag);
    }

    if ($tag ne $rtag) { # empty tag - close it
        $self->on_end($tag);
    }
}

sub on_text {
    my ($self, $text) = @_;

    $self->{book}->append_text($text);
}

sub on_end {
    my ($self, $tag) = @_;

    if (!$self->_is_tag($tag)) {
        $self->{book}->append_text($tag);
	return;
    }

    $self->{book}->push_item("/$tag");
}

1;

__END__

=head1 NAME

HTML::ListScraper - generic web page scraping support

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

 use HTML::ListScraper;

 $scraper = HTML::ListScraper->new( api_version => 3,
		      		    marked_sections => 1 );
 # set up $scraper options...

 $scraper->parse($html);
 $scraper->eof;

 @seq = $scraper->find_sequences;
 $seq = shift @seq;
 if ($seq) { # is-a HTML::ListScraper::Sequence
     foreach $inst ($seq->instances) { # is-a HTML::ListScraper::Instance
         foreach $tag ($inst->tags) { # is-a HTML::ListScraper::Tag
             print "<", $tag->name, ">\n";
             print $tag->text, "\n";
         }
     }
 }

=head1 DESCRIPTION

While Perl has good support and is often used for extracting
machine-friendly data from HTML pages, most scripts used for that task
are ad-hoc, parsing just one site's HTML and depending on superficial,
transient details of its structure - and are therefore brittle and
labor-intensive to maintain. This module tries to support more generic
scraping for a class of pages: those whose most important part is a
list of links.

C<HTML::ListScraper> is a subclass of L<HTML::Parser>, building on its
ability to convert an octet stream - whether strictly valid HTML or
something just vaguely similar to it - to tags and text. HTML parsing
works the same as with C<HTML::Parser>, except you don't need to
register your own HTML event handlers.

When the document is parsed, call C<find_sequences> to find out which
tags in the document repeat, one after the other, more than once
(attributes, text and comments are ignored for this comparison). Since
there'll probably be quite a lot of such sequences,
C<HTML::ListScraper> tries to find the "longest one repeating most
often", specifically, it maximizes C<log(number of non-overlapping
runs)*log(number of tags in the sequence)>. There can obviously be
more than one such sequence, which is why the method returns an array
(and the array can also be empty - see below). Your application can
then iterate over the returned structure to find items of interest.

This module includes a script, C<scrape>, displaying the sequences
found by C<HTML::ListScraper>, so that you can see which items your
application needs - and if they aren't there, you can try to tweak
C<HTML::ListScraper>'s settings with the various C<scrape> switches to
make it find more.

C<HTML::ListScraper> methods are as follows:

=head2 new

C<HTML::ListScraper>'s constructor. Passes all its parameters to the
superclass and registers C<HTML::Parser>'s event handlers C<start>,
C<text> and C<end>.

=head2 min_count

Numeric threshold for the frequency of found sequences -
C<get_sequences> returns only those which repeat at least C<min_count>
times. Call without arguments to get the current value, with an
argument to set it. Default (as well as the minimal allowed value) is
2.

=head2 shapeless

By default, C<get_sequences> returns only "well-shaped" sequences,
whose every opening tag is followed by the appropriate closing tag,
with an exception for those tags whose closing tag is optional -
i.e. C<< <div><br></div> >> is well-shaped but neither C<< <div><br>
>> nor C<< <br></div> >> is. Tags which don't need a closing tag are
those identified by C<is_unclosed_tag>. Closing tags are paired with
the nearest opening tag with the same name which hasn't been paired
yet. A well-shaped sequence is basically an HTML fragment - like a
tree, except it doesn't have to have a single root.

Well-shaped sequences should be fine when processing valid HTML, but
since this module doesn't restrict itself to valid HTML, that isn't
always good enough. Setting C<shapeless> to a true value removes this
filtering and makes all sequences eligible.

=head2 is_unclosed_tag

Test for tag names with optional closing tag. Takes a tag name,
returns true for tags declared in HTML 4.01 Transitional DTD as having
either optional or no closing tag. Note that subclassing this method
I<won't> change C<HTML::ListScraper> behavior - it delegates to a real
implementation deep in this module's guts, which are not documented
here.

=head2 get_all_tags

Accessor for the document's tag sequence maintained by
C<HTML::ListScraper>, used mainly for debugging. Takes no arguments,
returns an array (array reference if called in a scalar context) of
L<HTML::ListScraper::Tag> objects.

=head2 get_sequences

The core of C<HTML::ListScraper>. Takes no arguments, returns an array
of L<HTML::ListScraper::Sequence> objects. The sequences are sorted by
length (shortest first).

"Sequences" with just 1 tag and sequences which don't repeat are never
returned; depending on the value of C<min_count> and C<shapeless>,
C<get_sequences> may also ignore other ones (see C<min_count> and
C<shapeless>).

=head2 find_sequences

A generalization of C<get_sequences>. Like C<get_sequences>,
C<find_sequences> takes no arguments and returns an array of
L<HTML::ListScraper::Sequence> objects - the same sequences, in fact,
as C<get_sequences>, but with potentially more instances. In addition
to the exact matches, C<find_sequences> tries to find "approximate"
instance matches, that is, tag sequences with a non-zero but low edit
distance from the exact sequence.

The alignment uses L<Algorithm::NeedlemanWunsch> (q.v.) in its local
mode, with fixed scores whose particular values hopefully don't matter
much (see the source of C<HTML::ListScraper::Sweep> if you're really
interested in them). Approximate instances are sought between the
exact ones, from the most similar to a cut-off point of low
similarity.

Found approximate instances are identified by
C<HTML::ListScraper::Instance::match> value C<approx>. their score is
available as the value of C<HTML::ListScraper::Instance::score>. That
value isn't always defined, though: if the C<shapeless> flag isn't
set, approximate tag sequences are made to look like valid HTML
fragments by removing unpaired tags. Since that obviously damages the
score, no score is returned for such cut-up instances.

=head2 get_known_sequence

When the "longest sequence repeating most often" found by
C<HTML::ListScraper> isn't quite the sought one, you can specify
exactly which one you want by calling C<get_known_sequence> instead of
C<get_sequences>. C<get_known_sequence> takes a list of tag names
spelled using the same convention as L<HTML::ListScraper::Tag>,
i.e. in lowercase, without angle brackets and with closing tags having
'/' as the first character. If the parsed document doesn't contain the
specified sequence, C<get_known_sequence> returns C<undef>. Otherwise,
it returns an instance of L<HTML::ListScraper::Sequence>.

=head2 find_known_sequence

A generalization of C<get_known_sequence>. Like C<get_known_sequence>,
C<find_known_sequence> takes a list of tag names and finds both exact
and approximate matches for it. If the parsed document doesn't contain
at least one at least approximately matching tag sequences,
C<find_known_sequence> returns C<undef>. Otherwise, it returns an
instance of L<HTML::ListScraper::Sequence>.

=head2 on_start

Attribute start handler. Registered with signature C<self, tagname,
attr>, although the only attribute preserved by C<HTML::ListScraper>
is C<href>. For ultimate flexibility in preprocessing the input HTML,
you can subclass this method, but do call the base version at least
conditionally. Note that if you want to just ignore some tags, there
are simpler ways, i.e. C<HTML::Parser::ignore_tags>.

=head2 on_text

Text handler. Registered with signature C<self, dtext>. For ultimate
flexibility in preprocessing the input HTML, you can subclass this
method, but do call the base version at least conditionally.

=head2 on_end

Attribute end handler. Registered with signature C<self, tagname>. For
ultimate flexibility in preprocessing the input HTML, you can subclass
this method.

=head1 BUGS

Requires too much configuration.

=head1 AUTHOR

Vaclav Barta, C<< <vbar@comp.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2015 Vaclav Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
