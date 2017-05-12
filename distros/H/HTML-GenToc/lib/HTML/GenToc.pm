package HTML::GenToc;
BEGIN {
  $HTML::GenToc::VERSION = '3.20';
}
use strict;

=head1 NAME

HTML::GenToc - Generate a Table of Contents for HTML documents.

=head1 VERSION

version 3.20

=head1 SYNOPSIS

  use HTML::GenToc;

  # create a new object
  my $toc = new HTML::GenToc();

  my $toc = new HTML::GenToc(title=>"Table of Contents",
			  toc_entry=>{
			    H1=>1,
			    H2=>2
			  },
			  toc_end=>{
			    H1=>'/H1',
			    H2=>'/H2'
			  }
    );

  # generate a ToC from a file
  $toc->generate_toc(input=>$html_file,
		     footer=>$footer_file,
		     header=>$header_file
    );


=head1 DESCRIPTION

HTML::GenToc generates anchors and a table of contents for
HTML documents.  Depending on the arguments, it will insert
the information it generates, or output to a string, a separate file
or STDOUT.

While it defaults to taking H1 and H2 elements as the significant
elements to put into the table of contents, any tag can be defined
as a significant element.  Also, it doesn't matter if the input
HTML code is complete, pure HTML, one can input pseudo-html
or page-fragments, which makes it suitable for using on templates
and HTML meta-languages such as WML.

Also included in the distrubution is hypertoc, a script which uses the
module so that one can process files on the command-line in a
user-friendly manner.

=head1 DETAILS

The ToC generated is a multi-level level list containing links to the
significant elements. HTML::GenToc inserts the links into the ToC to
significant elements at a level specified by the user.

B<Example:>

If H1s are specified as level 1, than they appear in the first
level list of the ToC. If H2s are specified as a level 2, than
they appear in a second level list in the ToC.

Information on the significant elements and what level they should occur
are passed in to the methods used by this object, or one can use the
defaults.

There are two phases to the ToC generation.  The first phase is to
put suitable anchors into the HTML documents, and the second phase
is to generate the ToC from HTML documents which have anchors
in them for the ToC to link to.

For more information on controlling the contents of the created ToC, see
L</Formatting the ToC>.

HTML::GenToc also supports the ability to incorporate the ToC into the HTML
document itself via the B<inline> option.  See L</Inlining the ToC> for more
information.

In order for HTML::GenToc to support linking to significant elements,
HTML::GenToc inserts anchors into the significant elements.  One can
use HTML::GenToc as a filter, outputing the result to another file,
or one can overwrite the original file, with the original backed
up with a suffix (default: "org") appended to the filename.
One can also output the result to a string.

=head1 METHODS

Default arguments can be set when the object is created, and overridden
by setting arguments when the generate_toc method is called.
Arguments are given as a hash of arguments.

=cut

use Data::Dumper;
use HTML::SimpleParse;
use HTML::Entities;
use HTML::LinkList;

#################################################################

#---------------------------------------------------------------#
# Object interface
#---------------------------------------------------------------#

=head2 Method -- new

    $toc = new HTML::GenToc();

    $toc = new HTML::GenToc(toc_entry=>\%my_toc_entry,
	toc_end=>\%my_toc_end,
	bak=>'bak',
    	...
        );

Creates a new HTML::GenToc object.

These arguments will be used as defaults in invocations of other methods.

See L<generate_tod> for possible arguments.

=cut
sub new {
    my $invocant = shift;

    my $class = ref($invocant) || $invocant; # Object or class name
    my $self = {
	debug => 0,
	bak => 'org',
	entrysep => ', ',
	footer => '',
	inline => 0,
	header => '',
	input => '',
	notoc_match => 'class="notoc"',
	ol => 0,
	ol_num_levels => 1,
	overwrite => 0,
	outfile => '-',
	quiet => 0,
	textonly => 0,
	title => 'Table of Contents',
	toclabel => '<h1>Table of Contents</h1>',
	toc_tag => '^BODY',
	toc_tag_replace => 0,
	toc_only => 0,
	# define TOC entry elements
	toc_entry => {
	    'H1'=>1,
	    'H2'=>2,
	},
	# TOC entry element terminators
	toc_end => {
	    'H1'=>'/H1',
	    'H2'=>'/H2',
	},
	useorg => 0,
	@_
    };

    # bless self
    bless($self, $class);

    if ($self->{debug})
    {
    	print STDERR Dumper($self);
    }

    return $self;
} # new

=head2 generate_toc

    $toc->generate_toc(outfile=>"index2.html");

    my $result_str = $toc->generate_toc(to_string=>1);

Generates a table of contents for the significant elements in the HTML
documents, optionally generating anchors for them first.

B<Options>

=over

=item bak

bak => I<string>

If the input file/files is/are being overwritten (B<overwrite> is on), copy
the original file to "I<filename>.I<string>".  If the value is empty, B<no>
backup file will be created.
(default:org)

=item debug

debug => 1

Enable verbose debugging output.  Used for debugging this module;
in other words, don't bother.
(default:off)

=item entrysep

entrysep => I<string>

Separator string for non-<li> item entries
(default: ", ")

=item filenames

filenames => \@filenames

The filenames to use when creating table-of-contents links.
This overrides the filenames given in the B<input> option,
and is expected to have exactly the same number of elements.
This can also be used when passing in string-content to the B<input>
option, to give a (fake) filename to use for the links relating
to that content.

=item footer

footer => I<file_or_string>

Either the filename of the file containing footer text for ToC;
or a string containing the footer text.

=item header

header => I<file_or_string>

Either the filename of the file containing header text for ToC;
or a string containing the header text.

=item ignore_only_one

ignore_only_one => 1

If there would be only one item in the ToC, don't make a ToC.

=item ignore_sole_first

ignore_sole_first => 1

If the first item in the ToC is of the highest level,
AND it is the only one of that level, ignore it.
This is useful in web-pages where there is only one H1 header
but one doesn't know beforehand whether there will be only one.

=item inline

inline => 1

Put ToC in document at a given point.
See L</Inlining the ToC> for more information.

=item input

input => \@filenames

input => $content

This is expected to be either a reference to an array of filenames,
or a string containing content to process.

The three main uses would be:

=over

=item (a)

you have more than one file to process, so pass in multiple filenames

=item (b)

you have one file to process, so pass in its filename as the only array item

=item (c)

you have HTML content to process, so pass in just the content as a string

=back

(default:undefined)

=item notoc_match

notoc_match => I<string>

If there are certain individual tags you don't wish to include in the
table of contents, even though they match the "significant elements",
then if this pattern matches contents inside the tag (not the body),
then that tag will not be included, either in generating anchors nor in
generating the ToC.  (default: C<class="notoc">)

=item ol

ol => 1

Use an ordered list for level 1 ToC entries.

=item ol_num_levels

ol_num_levels => 2

The number of levels deep the OL listing will go if B<ol> is true.
If set to zero, will use an ordered list for all levels.
(default:1)

=item overwrite

overwrite => 1

Overwrite the input file with the output.
(default:off)

=item outfile

outfile => I<file>

File to write the output to.  This is where the modified HTML
output goes to.  Note that it doesn't make sense to use this option if you
are processing more than one file.  If you give '-' as the filename, then
output will go to STDOUT.
(default: STDOUT)

=item quiet

quiet => 1

Suppress informative messages. (default: off)

=item textonly

textonly => 1

Use only text content in significant elements.

=item title

title => I<string>

Title for ToC page (if not using B<header> or B<inline> or B<toc_only>)
(default: "Table of Contents")

=item toc_after

toc_after => \%toc_after_data

%toc_after_data = { I<tag1> => I<suffix1>,
    I<tag2> => I<suffix2>
    };

toc_after => { H2=>'</em>' }

For defining layout of significant elements in the ToC.

This expects a reference to a hash of
tag=>suffix pairs.

The I<tag> is the HTML tag which marks the start of the element.  The
I<suffix> is what is required to be appended to the Table of Contents
entry generated for that tag.

(default: undefined)

=item toc_before

toc_before => \%toc_before_data

%toc_before_data = { I<tag1> => I<prefix1>,
    I<tag2> => I<prefix2>
    };

toc_before=>{ H2=>'<em>' }

For defining the layout of significant elements in the ToC.  The I<tag>
is the HTML tag which marks the start of the element.  The I<prefix> is
what is required to be prepended to the Table of Contents entry
generated for that tag.

(default: undefined)

=item toc_end

toc_end => \%toc_end_data

%toc_end_data = { I<tag1> => I<endtag1>,
    I<tag2> => I<endtag2>
    };

toc_end => { H1 => '/H1', H2 => '/H2' }

For defining significant elements.  The I<tag> is the HTML tag which
marks the start of the element.  The I<endtag> the HTML tag which marks
the end of the element.  When matching in the input file, case is
ignored (but make sure that all your I<tag> options referring to the
same tag are exactly the same!).

=item toc_entry

toc_entry => \%toc_entry_data

%toc_entry_data = { I<tag1> => I<level1>,
    I<tag2> => I<level2>
    };

toc_entry => { H1 => 1, H2 => 2 }

For defining significant elements.  The I<tag> is the HTML tag which marks
the start of the element.  The I<level> is what level the tag is considered
to be.  The value of I<level> must be numeric, and non-zero. If the value
is negative, consective entries represented by the significant_element will
be separated by the value set by B<entrysep> option.

=item toclabel

toclabel => I<string>

HTML text that labels the ToC.  Always used.
(default: "<h1>Table of Contents</h1>")

=item toc_tag

toc_tag => I<string>

If a ToC is to be included inline, this is the pattern which is used to
match the tag where the ToC should be put.  This can be a start-tag, an
end-tag or a comment, but the E<lt> should be left out; that is, if you
want the ToC to be placed after the BODY tag, then give "BODY".  If you
want a special comment tag to make where the ToC should go, then include
the comment marks, for example: "!--toc--" (default:BODY)

=item toc_tag_replace

toc_tag_replace => 1

In conjunction with B<toc_tag>, this is a flag to say whether the given tag
should be replaced, or if the ToC should be put after the tag.
This can be useful if your toc_tag is a comment and you don't need it
after you have the ToC in place.
(default:false)

=item toc_only

toc_only => 1

Output only the Table of Contents, that is, the Table of Contents plus
the toclabel.  If there is a B<header> or a B<footer>, these will also be
output.

If B<toc_only> is false then if there is no B<header>, and B<inline> is
not true, then a suitable HTML page header will be output, and if there
is no B<footer> and B<inline> is not true, then a HTML page footer will
be output.

(default:false)

=item to_string

to_string => 1

Return the modified HTML output as a string.  This I<does> override
other methods of output (unlike version 3.00).  If I<to_string> is false,
the method will return 1 rather than a string.

=item use_id

use_id => 1

Use id="I<name>" for anchors rather than <a name="I<name>"/> anchors.
However if an anchor already exists for a Significant Element, this
won't make an id for that particular element.

=item useorg

useorg => 1

Use pre-existing backup files as the input source; that is, files of the
form I<infile>.I<bak>  (see B<input> and B<bak>).

=back

=cut
sub generate_toc ($%) {
    my $self = shift;
    my %args = (
	make_anchors=>1,
	make_toc=>1,
	input=>undef,
	filenames=>undef,
	bak=>$self->{bak},
	debug=>$self->{debug},
	useorg=>$self->{useorg},
	use_id=>$self->{use_id},
	notoc_match=>$self->{notoc_match},
	toc_entry=>$self->{toc_entry},
	toc_end=>$self->{toc_end},
	overwrite=>$self->{overwrite},
	ol=>$self->{ol},
	ol_num_levels=>$self->{ol_num_levels},
	entrysep=>$self->{entrysep},
	ignore_only_one=>$self->{ignore_only_one},
	@_
    );

    if ($args{debug})
    {
    	print STDERR Dumper(\%args);
    }
    if (!$args{input}) 
    {
	warn "generate_toc: no input given\n";
	return '';
    }
    #
    # get the input
    #
    my @filenames = ();
    my @input = ();
    if (ref $args{input} eq "ARRAY")
    {
	@filenames = @{$args{input}};
	my $i = 0;
	my $fh_needs_closing = 0;
	foreach my $fn (@filenames)
	{
	    my $infn = $fn;
	    my $bakfile = $fn . "." . $args{bak};
	    if ($args{useorg}
		&& $args{bak}
		&& -e $bakfile)
	    {
		# use the old backup files as source
		$infn = $bakfile;
	    }
	    my $fh = undef;
	    # using '-' means STDIN
	    if ($infn eq '-')
	    {
		$fh = *STDIN;
		$fh_needs_closing = 0;
	    }
	    else
	    {
		open ($fh, $infn) ||
		    die "Error: unable to open ", $infn, ": $!\n";
		$fh_needs_closing = 1;
	    }

	    my $content = '';
	    {
		local $/;   # slurp entire file
		$content = <$fh>;
		close ($fh) if ($fh_needs_closing);
	    }
	    $input[$i] = $content;

	    $i++;
	}
    }
    else
    {
	$filenames[0] = '';
	$input[0] = $args{input};
    }
    # overwrite the filenames array if a replacement
    # was passed in and has the same length
    if (defined $args{filenames}
	&& @{$args{filenames}}
	&& $#{$args{filenames}} == $#{filenames}
	)
    {
	@filenames = @{$args{filenames}};
    }

    #
    # make the anchors
    #
    if ($args{make_anchors})
    {
	my $i = 0;
	foreach my $fn (@filenames)
	{
	    my $html_str = $input[$i];
	    $input[$i] = $self->make_anchors(%args,
		filename=>$fn,
		input=>$html_str);
	    $i++;
	}
    }

    #
    # make the ToC
    #
    my $toc_str = '';
    if ($args{make_toc})
    {
	my %labels = ();
	my @list_of_lists = ();
	my $i = 0;
	for (my $i = 0; $i < @filenames; $i++)
	{
	    my @the_list = $self->make_toc_list(%args,
		first_file=>$filenames[0],
		labels=>\%labels,
		filename=>$filenames[$i],
		input=>$input[$i]);
	    if (!($args{ignore_only_one}
		and @the_list <= 1))
	    {
		push @list_of_lists, @the_list;
	    }
	}
	if (@list_of_lists > 0)
	{
	    #
	    # create the appropriate format
	    #
	    my %formats = ();
	    # check for non-list entries, flagged by negative levels
	    while (my ($key, $val) = each %{$args{toc_entry}})
	    {
		if ($val < 0)
		{
		    $formats{abs($val) - 1} = {};
		    $formats{abs($val) - 1}->{tree_head} = '<ul><li>';
		    $formats{abs($val) - 1}->{tree_foot} = "\n</li></ul>\n";
		    $formats{abs($val) - 1}->{item_sep} = $args{entrysep};
		    $formats{abs($val) - 1}->{pre_item} = '';
		    $formats{abs($val) - 1}->{post_item} = '';
		}
	    }
	    # check for OL
	    if ($args{ol})
	    {
		$formats{0} = {};
		$formats{0}->{tree_head} = '<ol>';
		$formats{0}->{tree_foot} = "\n</ol>";
		if ($args{ol_num_levels} > 0)
		{
		    $formats{$args{ol_num_levels}} = {};
		    $formats{$args{ol_num_levels}}->{tree_head} = '<ul>';
		    $formats{$args{ol_num_levels}}->{tree_foot} = "\n</ul>";
		}
	    }
	    $toc_str = HTML::LinkList::link_tree(
						 %args,
						 link_tree=>\@list_of_lists,
						 labels=>\%labels,
						 formats=>\%formats,
						);
	}
    }

    #
    # put the output
    #
    my $ret = $self->output_toc(
	%args,
	toc=>$toc_str,
	input=>\@input,
	filenames=>\@filenames,
    );

    return $ret;

} # generate_toc

=head1 INTERNAL METHODS

These methods are documented for developer purposes and aren't intended
to be used externally.

=head2 make_anchor_name

    $toc->make_anchor_name(content=>$content,
	anchors=>\%anchors);

Makes the anchor-name for one anchor.
Bases the anchor on the content of the significant element.
Ensures that anchors are unique.

=cut

sub make_anchor_name ($%) {
    my $self = shift;
    my %args = (
	content=>'', # will be overwritten by one of @_
	anchors=>undef,
	@_
    );
    my $name = $args{content};  # the anchor name will most often be very close to the token content

    if ($name !~ /^\s*$/) {
        # generate a SEO-friendly anchor right from the token content
	# The allowed character set is limited first by the URI specification
	# for fragments, http://tools.ietf.org/html/rfc3986#section-2:
	# characters then by the limitations of the values of 'id' and 'name'
	# attributes: http://www.w3.org/TR/REC-html40/types.html#type-name
        # Eventually, the only punctuation allowed in id values is [_.:-]

	# we need to replace [#&;] only when they are NOT part of an HTML
	# entity. decode_entities saves us from crafting a nasty regexp
        decode_entities($name);
	# MediaWiki also uses the period, see
	# http://en.wikipedia.org/wiki/Hierarchies#Ethics.2C_behavioral_psychology.2C_philosophies_of_identity
	$name =~ s/([^\s\w_.:-])/'.'.sprintf('%02X', ord($1))/eg;

	$name =~ s/\s+/_/g;
	# "ID and NAME tokens must begin with a letter ([A-Za-z])"
	$name =~ s/^[^a-zA-Z]+//;
    }
    else
    {
	$name = 'id';
    }
    $name = 'id' if $name eq '';

    # check if it already exists; if so, add a number
    my $anch_num = 1;
    my $word_name = $name;
    my $name_key = lc $name;
    # Reference: http://www.w3.org/TR/REC-html40/struct/links.html#h-12.2.1
    # Anchor names must be unique within a document. Anchor names that differ
    # only in case may not appear in the same document.
    while (defined $args{anchors}->{$name_key}
	   && $args{anchors}->{$name_key})
    {
	$name = $word_name . "_$anch_num";
	$name_key = lc $name;
	$anch_num++;
    }

    return $name;
} # make_anchor_name

=head2 make_anchors

    my $new_html = $toc->make_anchors(input=>$html,
	notoc_match=>$notoc_match,
	use_id=>$use_id,
	toc_entry=>\%toc_entries,
	toc_end=>\%toc_ends,
	);

Makes the anchors the given input string.
Returns a string.

=cut

sub make_anchors ($%) {
    my $self = shift;
    my %args = (
	input=>'',
	notoc_match=>$self->{notoc_match},
	use_id=>$self->{use_id},
	toc_entry=>$self->{toc_entry},
	toc_end=>$self->{toc_end},
	debug=>$self->{debug},
	quiet=>$self->{quiet},
	@_
    );
    my $html_str = $args{input};

    print STDERR "Making anchors for ", $args{filename}, "...\n"
	if (!$args{quiet} && $args{filename});

    my @newhtml = ();
    my %anchors = ();
    # Note that the keys to the anchors hash should be lower-cased
    # since anchor names that differ only in case are not allowed.

    # parse the HTML
    my $hp = new HTML::SimpleParse();
    $hp->text($html_str);
    $hp->parse();

    my $tag;
    my $endtag;
    my $level = 0;
    my $tmp;
    my $adone = 0;
    my $name = '';
    # go through the HTML
    my $tok;
    my $next_tok;
    my $i;
    my $notoc = $args{notoc_match};
    my @tree = $hp->tree();
    while (@tree) {
	$tok = shift @tree;
	$next_tok = $tree[0];
	if ($tok->{type} ne 'starttag')
	{
	    push @newhtml, $hp->execute($tok);
	    next;
	}
	# assert: we have a start tag
	$level = 0;
	
	# check if tag included in TOC (significant element)
	foreach my $key (keys %{$args{toc_entry}}) {
	    if ($tok->{content} =~ /^$key/i
		&& (!$notoc
		    || $tok->{content} !~ /$notoc/)) {
		$tag = $key;
		# level of significant element
		$level = abs($args{toc_entry}->{$key});
		# End tag of significant element
		$endtag = $args{toc_end}->{$key};
		last;
	    }
	}
	# if $level is not set, we didn't find a Significant tag
	if (!$level) {
	    push @newhtml, $hp->execute($tok);
	    next;
	}
	# assert: current tag is a Significant tag

	#
	# Add A element or ID to document
	#
	my $name_in_anchor = 0;
	$adone = 0;
	$name = '';
	my $sig_tok = $tok;
	if ($tag =~ /title/i) {		# TITLE tag is a special case
	    $adone = 1;
	}
	if ($args{use_id})
	{
	    # is there an existing ID?
	    if ($sig_tok->{content} =~ /ID\s*=\s*(['"])/i) {
		my $q = $1;
		($name) = $sig_tok->{content} =~ m/ID\s*=\s*$q([^$q]*)$q/i;
		if ($name)
		{
		    $anchors{lc $name} = $name;
		    push @newhtml, $hp->execute($sig_tok);
		    $adone = 1;
		}
		else # if the ID has no name, remove it!
		{
		    $sig_tok->{content} =~ s/ID\s*=\s*$q$q//i;
		}
	    }
	}
	else # not adding ID, move right along
	{
	    push @newhtml, $hp->execute($tok);
	}
	# Find the "name" of the significant element
	# Don't consume the tree, because ID behaves differently from A
	my $i = 0;
	while (!$name && $i < @tree)
	{
	    $tok = $tree[$i];
	    $next_tok = $tree[$i + 1];
	    if ($tok->{type} eq 'text') {
		$name = $self->make_anchor_name(content=>$tok->{content},
		    anchors=>\%anchors);
	    # Anchor
	    } elsif (!$adone && $tok->{type} eq 'starttag'
		&& $tok->{content} =~ /^A/i)
	    {
		if ($tok->{content} =~ /NAME\s*=\s*(['"])/i) {
		    my $q = $1;
		    ($name) = $tok->{content} =~ m/NAME\s*=\s*$q([^$q]*)$q/i;
		    $name_in_anchor = 1;
		} elsif ($next_tok->{type} eq 'text') {
		    $name = $self->make_anchor_name(content=>$next_tok->{content},
			anchors=>\%anchors);
		}
	    } elsif ($tok->{type} eq 'starttag'
		    || $tok->{type} eq 'endtag')
	    {	# Tag
		last if $tok->{content} =~ m|$endtag|i;
	    }
	    $i++;
	}
	# assert: there is a name, or there is no name to be found
	if (!$name)
	{
	    # make up a name
	    $name = $self->make_anchor_name(content=>"TOC",
		anchors=>\%anchors);
	}
	if (!$adone && $args{use_id})
	{
	    if (!$name_in_anchor)
	    {
		$anchors{lc $name} = $name;
		# add the ID
		$sig_tok->{content} .= " id='$name'";
		push @newhtml, $hp->execute($sig_tok);
		$adone = 1;
	    }
	    else
	    {
		# we have an already-named anchor, so don't add an ID
		push @newhtml, $hp->execute($sig_tok);
	    }
	}
	
	while (@tree) {
	    $tok = shift @tree;
	    $next_tok = $tree[0];
	    # Text
	    if ($tok->{type} eq 'text') {
		if (!$adone && $tok->{content} !~ /^\s*$/) {
		    $anchors{lc $name} = $name;
		    # replace the text with an anchor containing the text
		    push(@newhtml, qq|<a name="$name">$tok->{content}</a>|);
		    $adone = 1;
		} else {
		    push @newhtml, $hp->execute($tok);
		}
	    # Anchor
	    } elsif (!$adone && $tok->{type} eq 'starttag'
		&& $tok->{content} =~ /^A/i)
	    {
		# is there an existing NAME anchor?
		if ($name_in_anchor) {
		    $anchors{lc $name} = $name;
		    push @newhtml, $hp->execute($tok);
		} else {
		    # add the current name anchor
		    $tmp = $hp->execute($tok);
		    $tmp =~ s/^(<A)(.*)$/$1 name="$name" $2/i;
		    push @newhtml, $tmp;
		    $anchors{lc $name} = $name;
		}
		$adone = 1;
	    } elsif ($tok->{type} eq 'starttag'
		    || $tok->{type} eq 'endtag')
	    {	# Tag
		push @newhtml, $hp->execute($tok);
		last if $tok->{content} =~ m|$endtag|i;
	    }
	    else {
		push @newhtml, $hp->execute($tok);
	    }
	}
    }
    my $out = join('', @newhtml);

    return $out;
} # make_anchors

=head2 make_toc_list

    my @toc_list = $toc->make_toc_list(input=>$html,
	labels=>\%labels,
	notoc_match=>$notoc_match,
	toc_entry=>\%toc_entry,
	toc_end=>\%toc_end,
	filename=>$filename);

Makes a list of lists which represents the structure and content
of (a portion of) the ToC from one file.
Also updates a list of labels for the ToC entries.

=cut

sub make_toc_list ($%) {
    my $self = shift;
    my %args = (
	input=>'',
	filename=>'',
	labels=>undef,
	notoc_match=>$self->{notoc_match},
	toc_entry=>$self->{toc_entry},
	toc_end=>$self->{toc_end},
	inline=>$self->{inline},
	debug=>$self->{debug},
	toc_before=>$self->{toc_before},
	toc_after=>$self->{toc_after},
	textonly=>$self->{textonly},
	ignore_sole_first=>$self->{ignore_sole_first},
	ignore_only_one=>$self->{ignore_only_one},
	@_
    );
    my $html_str = $args{input};
    my $infile = $args{filename};
    my $labels = $args{labels};

    my $toc_str = "";
    my @toc = ();
    my @list_of_paths = ();
    my %level_count = ();

    # parse the HTML
    my $hp = new HTML::SimpleParse();
    $hp->text($html_str);
    $hp->parse();

    my $noli;
    my $prevnoli;
    my $before = "";
    my $after = "";
    my $tag;
    my $endtag;
    my $level = 0;
    my $levelopen;
    my $tmp;
    my $content;
    my $adone = 0;
    my $name = "NOTOC"; # if no anchor is found...
    my $is_title;
    my $found_title = 0;
    my $notoc = $args{notoc_match};
    # go through the HTML
    my $tok;
    my @tree = $hp->tree();
    while (@tree) {
	$tok = shift @tree;
	$level = 0;
	$is_title = 0;
	$tag = '';
	if ($tok->{type} eq 'starttag')
	{
	    # check if tag included in TOC
	    foreach my $key (keys %{$args{toc_entry}}) {
		if ($tok->{content} =~ /^$key/i
		    && (!$notoc
			|| $tok->{content} !~ /$notoc/)) {
		    $tag = $key;
		    if ($args{debug}) {
			print STDERR "============\n";
			print STDERR "key = $key ";
			print STDERR "tok->content = '", $tok->{content}, "' ";
			print STDERR "tag = $tag";
			print STDERR "\n============\n";
		    }
		    # level of significant element
		    $level = abs($args{toc_entry}->{$key});
		    # no <li> used in ToC listing
		    $noli = $args{toc_entry}->{$key} < 0;
		    # End tag of significant element
		    $endtag = $args{toc_end}->{$key};
		    if (defined $args{toc_before}->{$key}) {
			$before = $args{toc_before}->{$key};
		    } else {
			$before = "";
		    }
		    if (defined $args{toc_after}->{$key}) {
			$after = $args{toc_after}->{$key};
		    } else {
			$after = "";
		    }
		}
	    }
	}
	if (!$level) {
	    next;
	}
	if ($args{debug}) {
	    print STDERR "Chosen tag:$tag\n";
	}
	# assert: we are at a Significant tag

	# get A element or ID from document
	# This assumes that there is one there
	$content = '';
	$adone = 0;
	if ($tag =~ /title/i) {		# TITLE tag is a special case
	    if ($found_title) {
		# don't need to find a title again, we found it
		next;
	    } else {
		$is_title = 1;  $adone = 1;
		$found_title = 1;
	    }
	}
	if ($args{debug}) {
	    print STDERR "is_title:$is_title\n";
	}
	# check for an ID before we skip this tag
	if ($tok->{content} =~ /ID\s*=\s*(['"])/i) {
	    my $q = $1;
	    ($name) = $tok->{content} =~ m/ID\s*=\s*$q([^$q]*)$q/i;
	    $adone = 1;
	}
	while (@tree) {
	    $tok = shift @tree;
	    # Text
	    if ($tok->{type} eq 'text') {
		$content .= $tok->{content};
		if ($args{debug}) {
		    print STDERR "tok-content = ", $tok->{content}, "\n";
		    print STDERR "content = $content\n";
		}
	    # Anchor
	    } elsif (!$adone && $tok->{type} eq 'starttag'
		&& $tok->{content} =~ /^A/i)
	    {
		if ($tok->{content} =~ /NAME\s*=\s*(['"])/i) {
		    my $q = $1;
		    ($name) = $tok->{content} =~ m/NAME\s*=\s*$q([^$q]*)$q/i;
		    $adone = 1;
		}
	    } elsif ($tok->{type} eq 'starttag'
		    || $tok->{type} eq 'endtag')
	    {	# Tag
		if ($args{debug}) {
		    print STDERR "file = ", $infile,
			" tag = $tag, endtag = '$endtag",
			"' tok-type = ", $tok->{type},
			" tok-content = '", $tok->{content}, "'\n";
		}
		last if $tok->{content} =~ m#$endtag#i;
		$content .= $hp->execute($tok)
		    unless $args{textonly}
			|| $tok->{content} =~ m#/?(hr|p|a|img)#i;
	    }

	}
	if ($args{debug}) {
	    print STDERR "Chosen content:'$content'\n";
	}

	if ($content =~ /^\s*$/) {	# Check for empty content
	    warn "Warning: A $tag in $infile has no content;  $tag skipped\n";
	    next;
	} else {
	    $content =~ s/^\s+//;	# Strip beginning whitespace
	    $content =~ s/\s+$//;	# Strip end whitespace
	    $content = $before . $content . $after;
	}
	# figure out the anchor link needed
	my $link = '';
	if ($args{inline} and $args{first_file} eq $infile)
	{
	    $link = (!$is_title ? qq|#$name| : '');
	}
	else
	{
	    $link .= join('',
			 qq|$infile|,
			 !$is_title ? qq|#$name| : '');
	}
	# Assert: we know the info about this TOC entry
	push @list_of_paths, {
	    level=>$level,
	    path=>$link,
	    };
	$labels->{$link} = $content;
	$level_count{$level}++;

	$name = 'NOTOC';
	$prevnoli = $noli;
    } # while tree

    # If we want to ignore the first H1 if there's only one of them 
    # if the first item is a level-0 item
    # and there is only one of them
    # then remove it and readjust levels
    if ($args{ignore_sole_first}
	and $level_count{"1"} == 1
	and $list_of_paths[0]->{level} == 1)
    {
	shift @list_of_paths;
	for (my $i = 0; $i < @list_of_paths; $i++)
	{
	    $list_of_paths[$i]->{level}--;
	}
    }
    elsif ($args{ignore_only_one}
	   and @list_of_paths == 1)
    {
	return ();
    }

    my @list_of_lists = ();
    @list_of_lists = $self->build_lol(
	paths=>\@list_of_paths);

    return @list_of_lists;
} # make_toc_list

=head2 build_lol

Build a list of lists of paths, given a list
of hashes with info about paths.

=cut
sub build_lol {
    my $self = shift;
    my %args = (
	paths=>undef,
	depth=>1,
	prepend_list=>undef,
	append_list=>undef,
	@_
    );
    my $paths_ref = $args{paths};
    my $depth = $args{depth};

    my @list_of_lists = ();
    while (@{$paths_ref})
    {
	my $toc_entry = $paths_ref->[0];
	my $path_depth = $toc_entry->{level};
	my $path = $toc_entry->{path};
	if ($path_depth == $depth)
	{
	    shift @{$paths_ref}; # use this path
	    push @list_of_lists, $path;
	}
	elsif ($path_depth > $depth)
	{
	    push @list_of_lists, [$self->build_lol(
		%args,
		prepend_list=>undef,
		append_list=>undef,
		paths=>$paths_ref,
		depth=>$path_depth,
		)];
	}
	elsif ($path_depth < $depth)
	{
	    return @list_of_lists;
	}
    }
    # prepend the given list to the top level
    if (defined $args{prepend_list} and @{$args{prepend_list}})
    {
	# if the list of lists is a single item which is a list
	# then add the extra list to that item
	if ($#list_of_lists == 0
	    and ref($list_of_lists[0]) eq "ARRAY")
	{
	    unshift @{$list_of_lists[0]}, @{$args{prepend_list}};
	}
	else
	{
	    unshift @list_of_lists, @{$args{prepend_list}};
	}
    }
    # append the given list to the top level
    if (defined $args{append_list} and @{$args{append_list}})
    {
	# if the list of lists is a single item which is a list
	# then add the extra list to that item
	if ($#list_of_lists == 0
	    and ref($list_of_lists[0]) eq "ARRAY")
	{
	    push @{$list_of_lists[0]}, @{$args{append_list}};
	}
	else
	{
	    push @list_of_lists, @{$args{append_list}};
	}
    }
    return @list_of_lists;
} # build_lol

=head2 output_toc

    $self->output_toc(toc=>$toc_str,
	input=>\@input,
	filenames=>\@filenames);

Put the output (whether to file, STDOUT or string).
The "output" in this case could be the ToC, the modified
(anchors added) HTML, or both.

=cut
sub output_toc ($%) {
    my $self = shift;
    my %args = (
		toc=>'',
		input=>undef,
		filenames=>undef,
		bak=>$self->{bak},
		useorg=>$self->{useorg},
		inline=>$self->{inline},
		overwrite=>$self->{overwrite},
		to_string=>$self->{to_string},
		header=>$self->{header},
		footer=>$self->{footer},
		toc_only=>$self->{toc_only},
		title=>$self->{title},
		toclabel=>$self->{toclabel},
		outfile=>$self->{outfile},
		debug=>$self->{debug},
		quiet=>$self->{quiet},
		@_
	       );

    #
    # Output to the files if we were making anchors
    #
    if ($args{make_anchors}
	&& !$args{to_string}
	&& $args{overwrite})
    {
	my $ofh;
	# start from 1 if we're going to be inlining the toc
	# in the first file and not to an output file
	my $start_from = (($args{make_toc}
			   && $args{inline}
			   && !$args{outfile})
			  ? 1 : 0);
	for (my $i=$start_from; $i < @{$args{filenames}}; $i++)
	{
	    my $filename = $args{filenames}->[$i];
	    my $bakfile = $filename . "." . $args{bak};
	    if ($args{bak}
		&& !($args{useorg} && -e $bakfile))
	    {
		# copy the file to a backup
		print STDERR "Backing up ", $filename, " to ",
		      $bakfile, "\n"
			  unless $args{quiet};
		cp($filename, $bakfile);
	    }
	    open($ofh, "> $filename")
		|| die "Error: unable to open ", $filename, ": $!\n";
	    print STDERR "Overwriting ToC to ", $filename, "\n"
		unless $args{quiet};
	    print $ofh $args{input}->[$i];
	    close($ofh);
	}
    }

    #
    # Construct and output the ToC
    #
    my $output = '';
    if ($args{make_toc})
    {
	if ($args{toc})
	{
	    my @toc = ();
	    # put the header at the start of the ToC if there is one
	    if ($args{header}) {
		if (-f $args{header})
		{
		    open(HEADER, $args{header})
			|| die "Error: unable to open ", $args{header}, ": $!\n";
		    push @toc, <HEADER>;
		    close (HEADER);
		}
		else # not a file
		{
		    push @toc, $args{header};
		}
	    }
	    # if we are outputing a standalone page,
	    # then make sure it can stand
	    elsif (!$args{toc_only}
		   && !$args{inline}) {

		push @toc, qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML//EN">\n|,
		     "<html>\n",
		     "<head>\n";
		push @toc, "<title>", $args{title}, "</title>\n"  if $args{title};
		push @toc, "</head>\n",
		     "<body>\n";
	    }

	    # start the ToC with the ToC label
	    if ($args{toclabel}) {
		push @toc, $args{toclabel};
	    }

	    # and the actual ToC
	    push @toc, "\n", $args{toc}, "\n";

	    # add the footer, if there is one
	    if ($args{footer}) {
		if (-f $args{footer})
		{
		    open(FOOTER, $args{footer})
			|| die "Error: unable to open ", $args{footer}, ": $!\n";
		    push @toc, <FOOTER>;
		    close (FOOTER);
		}
		else
		{
		    push @toc, $args{footer};
		}
	    }
	    # if we are outputing a standalone page,
	    # then make sure it can stand
	    elsif (!$args{toc_only}
		   && !$args{inline}) {

		push @toc, "</body>\n", "</html>\n";
	    }

	    $output = join '', @toc;
	}
	else
	{
	    $output = "\n";
	}
    }
    elsif ($args{make_anchors} && (!$args{overwrite} || $args{to_string}))
    {
	# if we're just making anchors, and we aren't overwriting
	# the original file, we need to output it
	$output = $args{input}->[0];
    }

    if ($output)
    {
	#
	#  Sent the outfile to its final destination
	#
	my $file_needs_closing = 0;
	my $ofh;
	if ($args{to_string})
	{
	    $ofh = undef;
	}
	elsif ($args{outfile} && $args{outfile} ne "-") {
	    open($ofh, "> " . $args{outfile})
		|| die "Error: unable to open ", $args{outfile}, ": $!\n";
	    $file_needs_closing = 1;
	}
	elsif (!$args{overwrite}) {
	    $ofh = *STDOUT;
	    $file_needs_closing = 0;
	}
	if ($args{inline}) {
	    # create the modified version of the first set of input
	    my $first_file = $args{filenames}->[0];
	    my $bakfile = $first_file . "." . $args{bak};
	    $output = $self->put_toc_inline(%args,
					    toc_str=>$output,
					    in_string=>$args{input}->[0],
					    filename=>$args{filenames}->[0],
					   );

	    if ($args{to_string})
	    {
		# just send to string, don't print anything
		if ($args{debug})
		{
		    print STDERR "======== to_string output_toc ========\n";
		    print STDERR $output;
		    print STDERR "========----------------------========\n";
		}
	    }
	    elsif ($args{overwrite}) {
		if ($args{bak}
		    && !($args{useorg} && -e $bakfile))
		{
		    # copy the file to a backup
		    print STDERR "Backing up ", $first_file, " to ",
			  $bakfile, "\n"
			      unless $args{quiet};
		    cp($first_file, $bakfile);
		}
		open($ofh, "> $first_file")
		    || die "Error: unable to open ", $first_file, ": $!\n";
		$file_needs_closing = 1;
		print STDERR "Overwriting ToC to ", $first_file, "\n"
		    unless $args{quiet};
		print $ofh $output;
	    }
	    elsif ($args{outfile}
		   && $args{outfile} ne "-") {
		print STDERR "Writing Inline ToC to ", $args{outfile}, "\n"
		    unless $args{quiet};
		print $ofh $output;
	    }
	    elsif ($args{outfile})
	    {
		print $ofh $output;
	    }
	} else {
	    if ($args{to_string})
	    {
		# just send to string, don't print anything
	    }
	    elsif ($args{outfile} && $args{outfile} ne "-") {
		print STDERR "Writing ToC to ", $args{outfile}, "\n"
		    unless $args{quiet};
		print $ofh $output;
	    }
	    else
	    {
		print $ofh $output;
	    }
	}
	if ($file_needs_closing) {
	    close($ofh);
	}
    }

    if ($args{to_string})
    {
	return $output;
    }
    else
    {
	return 1;
    }
} # output_toc

=head2 put_toc_inline

    my $newhtml = $toc->put_toc_inline(toc_str=>$toc_str,
	filename=>$filename, in_string=>$in_string);

Puts the given toc_str into the given input string;
returns a string.

=cut

sub put_toc_inline ($) {
    my $self = shift;
    my %args = (
	toc_str=>'',
	filename=>'',
	in_string=>'',
	toc_tag=>$self->{toc_tag},
	toc_tag_replace=>$self->{toc_tag_replace},
	@_
    );
    my $toc_str = $args{toc_str};
    my $infile = $args{filename};

    my $html_str = "";

    if ($args{in_string}) # use input string, not file
    {
	$html_str = $args{in_string};
    }
    else
    {
	local $/;
	open (FILE, $infile) ||
	    die "Error: unable to open ", $infile, ": $!\n";

	$html_str = <FILE>;
	close (FILE);
    }


    # parse the file
    my $hp = new HTML::SimpleParse();
    $hp->text($html_str);
    $hp->parse();

    my $toc_tag = $args{toc_tag};
    my @newhtml = ();

    my $toc_done = 0;
    # go through the HTML
    my $tok;
    my $i;
    my @tree = $hp->tree();
    while (@tree) {
	$tok = shift @tree;
	# look for the ToC tag in tags or comments
	if ($tok->{type} eq 'starttag'
	    || $tok->{type} eq 'endtag'
	    || $tok->{type} eq 'comment')
	{
	    if (!$toc_done
		&& $tok->{content} =~ m|$toc_tag|i) {
		# some tags need to be preserved, with the ToC put after,
		# while others need to be replaced
		if (!$args{toc_tag_replace}) {
		    push @newhtml, $hp->execute($tok);
		}
		# put the ToC in
		push @newhtml, $toc_str;
		$toc_done = 1;
	    }
	    else {
		push @newhtml, $hp->execute($tok);
	    }
	}
	else
	{
	    push @newhtml, $hp->execute($tok);
	    next;
	}
    }

    return join('', @newhtml);
}

=head2 cp

    cp($src, $dst);

Copies file $src to $dst.
Used for making backups of files.

=cut

sub cp ($$) {
    my($src, $dst) = @_;
    open (SRC, $src) ||
	die "Error: unable to open ", $src, ": $!\n";
    open (DST, "> $dst") ||
	die "Error: unable to open ", $dst, ": $!\n";
    print DST <SRC>;
    close(SRC);
    close(DST);
}

1;

=head1 FILE FORMATS

=head2 Formatting the ToC

The B<toc_entry> and other related options give you control on how the
ToC entries may look, but there are other options to affect the final
appearance of the ToC file created.

With the B<header> option, the contents of the given file (or string)
will be prepended before the generated ToC. This allows you to have
introductory text, or any other text, before the ToC.

=over

=item Note:

If you use the B<header> option, make sure the file specified
contains the opening HTML tag, the HEAD element (containing the
TITLE element), and the opening BODY tag. However, these
tags/elements should not be in the header file if the B<inline>
option is used. See L</Inlining the ToC> for information on what
the header file should contain for inlining the ToC.

=back

With the B<toclabel> option, the contents of the given string will be
prepended before the generated ToC (but after any text taken from a
B<header> file).

With the B<footer> option, the contents of the file will be appended
after the generated ToC.

=over

=item Note:

If you use the B<footer>, make sure it includes the closing BODY
and HTML tags (unless, of course, you are using the B<inline> option).

=back

If the B<header> option is not specified, the appropriate starting
HTML markup will be added, unless the B<toc_only> option is specified.
If the B<footer> option is not specified, the appropriate closing
HTML markup will be added, unless the B<toc_only> option is specified.

If you do not want/need to deal with header, and footer, files, then
you are allowed to specify the title, B<title> option, of the ToC file;
and it allows you to specify a heading, or label, to put before ToC
entries' list, the B<toclabel> option. Both options have default values.

If you do not want HTML page tags to be supplied, and just want
the ToC itself, then specify the B<toc_only> option.
If there are no B<header> or B<footer> files, then this will simply
output the contents of B<toclabel> and the ToC itself.

=head2 Inlining the ToC

The ability to incorporate the ToC directly into an HTML document
is supported via the B<inline> option.

Inlining will be done on the first file in the list of files processed,
and will only be done if that file contains an opening tag matching the
B<toc_tag> value.

If B<overwrite> is true, then the first file in the list will be
overwritten, with the generated ToC inserted at the appropriate spot.
Otherwise a modified version of the first file is output to either STDOUT
or to the output file defined by the B<outfile> option.

The options B<toc_tag> and B<toc_tag_replace> are used to determine where
and how the ToC is inserted into the output.

B<Example 1>

    $toc->generate_toc(inline=>1,
		       toc_tag => 'BODY',
		       toc_tag_replace => 0,
		       ...
		       );

This will put the generated ToC after the BODY tag of the first file.
If the B<header> option is specified, then the contents of the specified
file are inserted after the BODY tag.  If the B<toclabel> option is not
empty, then the text specified by the B<toclabel> option is inserted.
Then the ToC is inserted, and finally, if the B<footer> option is
specified, it inserts the footer.  Then the rest of the input file
follows as it was before.

B<Example 2>

    $toc->generate_toc(inline=>1,
		       toc_tag => '!--toc--',
		       toc_tag_replace => 1,
		       ...
		       );

This will put the generated ToC after the first comment of the form
<!--toc-->, and that comment will be replaced by the ToC
(in the order
    B<header>
    B<toclabel>
    ToC
    B<footer>)
followed by the rest of the input file.

=over

=item Note:

The header file should not contain the beginning HTML tag
and HEAD element since the HTML file being processed should
already contain these tags/elements.

=back

=head1 NOTES

=over

=item *

HTML::GenToc is smart enough to detect anchors inside significant
elements. If the anchor defines the NAME attribute, HTML::GenToc uses
the value. Else, it adds its own NAME attribute to the anchor.
If B<use_id> is true, then it likewise checks for and uses IDs.

=item *

The TITLE element is treated specially if specified in the B<toc_entry>
option. It is illegal to insert anchors (A) into TITLE elements.
Therefore, HTML::GenToc will actually link to the filename itself
instead of the TITLE element of the document.

=item *

HTML::GenToc will ignore a significant element if it does not contain
any non-whitespace characters. A warning message is generated if
such a condition exists.

=item *

If you have a sequence of significant elements that change in a slightly
disordered fashion, such as H1 -> H3 -> H2 or even H2 -> H1, though
HTML::GenToc deals with this to create a list which is still good HTML, if
you are using an ordered list to that depth, then you will get strange
numbering, as an extra list element will have been inserted to nest the
elements at the correct level.

For example (H2 -> H1 with ol_num_levels=1):

    1. 
	* My H2 Header
    2. My H1 Header

For example (H1 -> H3 -> H2 with ol_num_levels=0 and H3 also being
significant):

    1. My H1 Header
	1. 
	    1. My H3 Header
	2. My H2 Header
    2. My Second H1 Header

In cases such as this it may be better not to use the B<ol> option.

=back

=head1 CAVEATS

=over

=item *

Version 3.10 (and above) generates more verbose (SEO-friendly) anchors
than prior versions. Thus anchors generated with earlier versions will
not match version 3.10 anchors.

=item *

Version 3.00 (and above) of HTML::GenToc is not compatible with
Version 2.x of HTML::GenToc.  It is now designed to do everything
in one pass, and has dropped certain options: the B<infile> option
is no longer used (it has been replaced with the B<input> option);
the B<toc_file> option no longer exists; use the B<outfile> option
instead; the B<tocmap> option is no longer supported.  Also the old
array-parsing of arguments is no longer supported.  There is no longer
a B<generate_anchors> method; everything is done with B<generate_toc>.

It now generates lower-case tags rather than upper-case ones.

=item *

HTML::GenToc is not very efficient (memory and speed), and can be
slow for large documents.

=item *

Now that generation of anchors and of the ToC are done in one pass,
even more memory is used than was the case before.  This is more notable
when processing multiple files, since all files are read into memory
before processing them.

=item *

Invalid markup will be generated if a significant element is
contained inside of an anchor. For example:

    <a name="foo"><h1>The FOO command</h1></a>

will be converted to (if H1 is a significant element),

    <a name="foo"><h1><a name="The">The</a> FOO command</h1></a>

which is illegal since anchors cannot be nested.

It is better style to put anchor statements within the element to
be anchored. For example, the following is preferred:

    <h1><a name="foo">The FOO command</a></h1>

HTML::GenToc will detect the "foo" name and use it.

=item *

name attributes without quotes are not recognized.

=back

=head1 BUGS

Tell me about them.

=head1 REQUIRES

The installation of this module requires C<Module::Build>.  The module
depends on C<HTML::SimpleParse>, C<HTML::Entities> and C<HTML::LinkList> and uses
C<Data::Dumper> for debugging purposes.  The hypertoc script depends on
C<Getopt::Long>, C<Getopt::ArgvFile> and C<Pod::Usage>.  Testing of this
distribution depends on C<Test::More>.

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1)
htmltoc(1)
hypertoc(1)

=head1 AUTHOR

Kathryn Andersen     (RUBYKAT)	http://www.katspace.org/tools/hypertoc/

Based on htmltoc by Earl Hood       ehood AT medusa.acs.uci.edu

Contributions by Dan Dascalescu, <http://dandascalescu.com>

=head1 COPYRIGHT

Copyright (C) 1994-1997  Earl Hood, ehood AT medusa.acs.uci.edu
Copyright (C) 2002-2008 Kathryn Andersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut