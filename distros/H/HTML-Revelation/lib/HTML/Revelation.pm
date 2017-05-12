package HTML::Revelation;

use strict;
use warnings;

our @accessors =      (qw/caption class2depth class_name comment css_output_file css_url empty html_output_file input_file/);
use accessors::classic qw/caption class2depth class_name comment css_output_file css_url empty html_output_file input_file/;

use File::Spec;
use HTML::Entities::Interpolate;
use HTML::Tagset;
use HTML::TreeBuilder;
use List::Cycle;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Revelation ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.03';

# -----------------------------------------------

sub add_caption
{
	my($self, $output) = @_;

	my(@comment);

	push @comment, qq|<div align = "center" class = "c0003">|;
	push @comment, qq|<table>|;

	if ($self -> comment() )
	{
		push @comment, '<tr><td>Comment:</td><td>' . $self -> comment() . '</td></tr>';
	}

	push @comment, '<tr><td>Input file:</td><td>' . $self -> input_file() . '</td></tr>';
	push @comment, '<tr><td>HTML output file:</td><td>' . $self -> html_output_file() . '</td></tr>';
	push @comment, '<tr><td>CSS output file:</td><td>' . $self -> css_output_file() . '</td></tr>';
	push @comment, '<tr><td>Creator:</td><td>' . __PACKAGE__ . " V $VERSION</td></tr>";
	push @comment, '</table>';
	push @comment, '</div>';
	push @comment, qq|<div style="padding-bottom: 1em"></div>|;

	push @$output, @comment;

} # End of add_caption.

# -----------------------------------------------

sub build_css_file
{
	my($self)  = @_;
	my(@color) = split(/\n/, $self -> load_colors() );

	# Discard dark colors.

	shift @color for 1 .. 220;

	my($cycle)      = List::Cycle -> new({values => \@color});
	my($class)      = 'c0000';
	my($class_name) = $self -> class_name();
	my($depth)      = $self -> class2depth();
	my($output)     = [];

	my($color);
	my($padding);

	while ($class lt $class_name)
	{
		$class++;

		$color   = $cycle -> next();
		$padding = 4 * $$depth{$class};

		push @$output, <<EOS;
.$class
{
  background-color: $color;
  border-style: solid;
  border-width: 1px;
  padding-left: ${padding}px;
  padding-right: ${padding}px;
}

EOS
	}

	return $output;

} # End of build_css_file.

# -----------------------------------------------

sub empty_tag
{
	my($self, $tag_name) = @_;

	return ${$self -> empty()}{$tag_name} || 0;

} # End of empty_tag.

# -----------------------------------------------

sub format_attributes
{
	my($self, $node) = @_;
	my(%attr)        = $node -> all_attr();

	my(@s);

	push @s, map{qq|$_ = "$attr{$_}"|} grep{! /^_/} sort keys %attr;

	my($s) = join(', ', @s) || '';
	$s     = " $s" if ($s);

	return $s;

} # End of format_attributes.

# -----------------------------------------------

sub load_colors
{
	my($self) = @_;

	return <<EOS;
000000
000080
00008B
0000CD
0000EE
0000FF
006400
00688B
008000
008080
00868B
008B00
008B45
008B8B
009ACD
00B2EE
00BFFF
00C5CD
00CD00
00CD66
00CDCD
00CED1
00E5EE
00EE00
00EE76
00EEEE
00F5FF
00FA9A
00FF00
00FF7F
00FFFF
030303
050505
080808
0A0A0A
0D0D0D
0F0F0F
104E8B
121212
141414
171717
1874CD
191970
1A1A1A
1C1C1C
1C86EE
1E90FF
1F1F1F
20B2AA
212121
228B22
242424
262626
27408B
292929
2B2B2B
2E2E2E
2E8B57
2F4F4F
303030
32814B
32CD32
333333
363636
36648B
383838
3A5FCD
3B3B3B
3CB371
3D3D3D
404040
40E0D0
4169E1
424242
436EEE
43CD80
454545
458B00
458B74
4682B4
473C8B
474747
483D8B
4876FF
48D1CC
4A4A4A
4A708B
4B0082
4D4D4D
4EEE94
4F4F4F
4F94CD
525252
528B8B
53868B
545454
548B54
54FF9F
551A8B
556B2F
575757
595959
5C5C5C
5CACEE
5D478B
5E5E5E
5F9EA0
607B8B
616161
636363
63B8FF
6495ED
666666
668B8B
66CD00
66CDAA
68228B
68838B
6959CD
696969
698B22
698B69
6A5ACD
6B6B6B
6B8E23
6C7B8B
6CA6CD
6E6E6E
6E7B8B
6E8B3D
707070
708090
737373
757575
76EE00
76EEC6
778899
787878
79CDCD
7A378B
7A67EE
7A7A7A
7A8B8B
7AC5CD
7B68EE
7CCD7C
7CFC00
7D26CD
7D7D7D
7E7E7E
7EC0EE
7F7F7F
7FFF00
7FFFD4
800000
800080
808000
808080
828282
836FFF
838B83
838B8B
8470FF
858585
878787
87CEEB
87CEFA
87CEFF
8968CD
8A2BE2
8A8A8A
8B0000
8B008B
8B0A50
8B1A1A
8B1C62
8B2252
8B2323
8B2500
8B3626
8B3A3A
8B3A62
8B3E2F
8B4500
8B4513
8B4726
8B475D
8B4789
8B4C39
8B5742
8B5A00
8B5A2B
8B5F65
8B636C
8B6508
8B668B
8B6914
8B6969
8B7355
8B7500
8B7765
8B795E
8B7B8B
8B7D6B
8B7D7B
8B7E66
8B814C
8B8378
8B8386
8B864E
8B8682
8B8878
8B8970
8B8989
8B8B00
8B8B7A
8B8B83
8C8C8C
8DB6CD
8DEEEE
8EE5EE
8F8F8F
8FBC8F
90EE90
912CEE
919191
9370DB
9400D3
949494
969696
96CDCD
97FFFF
98F5FF
98FB98
9932CC
999999
9A32CD
9AC0CD
9ACD32
9AFF9A
9B30FF
9BCD9B
9C9C9C
9E9E9E
9F79EE
9FB6CD
A020F0
A0522D
A1A1A1
A2B5CD
A2CD5A
A3A3A3
A4D3EE
A52A2A
A6A6A6
A8A8A8
A9A9A9
AB82FF
ABABAB
ADADAD
ADD8E6
ADFF2F
AEEEEE
AFEEEE
B03060
B0B0B0
B0C4DE
B0E0E6
B0E2FF
B22222
B23AEE
B2DFEE
B3B3B3
B3EE3A
B452CD
B4CDCD
B4EEB4
B5B5B5
B8860B
B8B8B8
B9D3EE
BA55D3
BABABA
BBFFFF
BC8F8F
BCD2EE
BCEE68
BDB76B
BDBDBD
BEBEBE
BF3EFF
BFBFBF
BFEFFF
C0C0C0
C0FF3E
C1CDC1
C1CDCD
C1FFC1
C2C2C2
C4C4C4
C6E2FF
C71585
C7C7C7
C9C9C9
CAE1FF
CAFF70
CCCCCC
CD0000
CD00CD
CD1076
CD2626
CD2990
CD3278
CD3333
CD3700
CD4F39
CD5555
CD5B45
CD5C5C
CD6090
CD6600
CD661D
CD6839
CD6889
CD69C9
CD7054
CD8162
CD8500
CD853F
CD8C95
CD919E
CD950C
CD96CD
CD9B1D
CD9B9B
CDAA7D
CDAD00
CDAF95
CDB38B
CDB5CD
CDB79E
CDB7B5
CDBA96
CDBE70
CDC0B0
CDC1C5
CDC5BF
CDC673
CDC8B1
CDC9A5
CDC9C9
CDCD00
CDCDB4
CDCDC1
CFCFCF
D02090
D15FEE
D1C166
D1D1D1
D1EEEE
D2691E
D2B48C
D3D3D3
D4D4D4
D6D6D6
D8BFD8
D9D9D9
DA70D6
DAA520
DB7093
DBDBDB
DC143C
DCDCDC
DDA0DD
DEB887
DEDEDE
E066FF
E0E0E0
E0EEE0
E0EEEE
E0FFFF
E3E3E3
E5E5E5
E6E6FA
E8E8E8
E9967A
EBEBEB
EDEDED
EE0000
EE00EE
EE1289
EE2C2C
EE30A7
EE3A8C
EE3B3B
EE4000
EE5C42
EE6363
EE6A50
EE6AA7
EE7600
EE7621
EE7942
EE799F
EE7AE9
EE8262
EE82EE
EE9572
EE9A00
EE9A49
EEA2AD
EEA9B8
EEAD0E
EEAEEE
EEB422
EEB4B4
EEC591
EEC900
EECBAD
EECFA1
EED2EE
EED5B7
EED5D2
EED8AE
EEDC82
EEDD82
EEDFCC
EEE0E5
EEE5DE
EEE685
EEE8AA
EEE8CD
EEE9BF
EEE9E9
EEEE00
EEEED1
EEEEE0
F08080
F0E68C
F0F0F0
F0F8FF
F0FFF0
F0FFFF
F2F2F2
F4A460
F5DEB3
F5F5DC
F5F5F5
F5FFFA
F7F7F7
F8F8FF
FA8072
FAEBD7
FAF0E6
FAFAD2
FAFAFA
FCFCFC
FDF5E6
FF0000
FF00FF
FF1493
FF3030
FF34B3
FF3E96
FF4040
FF4500
FF6347
FF69B4
FF6A6A
FF6EB4
FF7256
FF7F00
FF7F24
FF7F50
FF8247
FF82AB
FF83FA
FF8C00
FF8C69
FFA07A
FFA500
FFA54F
FFAEB9
FFB5C5
FFB6C1
FFB90F
FFBBFF
FFC0CB
FFC125
FFC1C1
FFD39B
FFD700
FFDAB9
FFDEAD
FFE1FF
FFE4B5
FFE4C4
FFE4E1
FFE7BA
FFEBCD
FFEC8B
FFEFD5
FFEFDB
FFF0F5
FFF5EE
FFF68F
FFF8DC
FFFACD
FFFAF0
FFFAFA
FFFF00
FFFFE0
FFFFF0
FFFFFF
EOS

} # End of load_colors.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless({}, $class);

	# Set defaults.

	$self -> caption(0);
	$self -> class2depth({});
	$self -> class_name('c0000');
	$self -> comment('');
	$self -> css_output_file('');
	$self -> css_url('');
	$self -> empty
	({
	 area => 1,
	 base => 1,
	 basefont => 1,
	 br => 1,
	 col => 1,
	 embed => 1,
	 frame => 1,
	 hr => 1,
	 img => 1,
	 input => 1,
	 isindex => 1,
	 link => 1,
	 meta => 1,
	 param => 1,
	 wbr => 1,
	});
	$self -> html_output_file('');
	$self -> input_file('');

	# Process user options.

	my($attr_name);

	for $attr_name (@accessors)
	{
		if (exists($arg{$attr_name}) )
		{
			$self -> $attr_name($arg{$attr_name});
		}
	}

	if (! $self -> css_output_file() )
	{
		die 'CSS output file not specifed';
	}

	if (! $self -> css_url() )
	{
		die 'CSS URL not specifed';
	}

	if (! $self -> html_output_file() )
	{
		die 'HTML output file not specifed';
	}

	if (! -f $self -> input_file() )
	{
		die 'Cannot find input file: ' . $self -> input_file();
	}

	$$self{'_empty'} =
	{
	 area => 1,
	 base => 1,
	 basefont => 1,
	 br => 1,
	 col => 1,
	 embed => 1,
	 frame => 1,
	 hr => 1,
	 img => 1,
	 input => 1,
	 isindex => 1,
	 link => 1,
	 meta => 1,
	 param => 1,
	 wbr => 1,
	};

	return $self;

} # End of new.

# -----------------------------------------------

sub process
{
	my($self, $css_url, $depth, $node, $output) = @_;

	$depth++;

	# If ref $node is true, this node has children, so we're going to recurse.

	if (ref $node)
	{
		my($tag)       = lc $node -> tag();
		my($empty_tag) = $self -> empty_tag($tag);

		my($content);

		# If the tag can appear in the body, apply makeup aka markup.

		if ($HTML::Tagset::isBodyElement{$tag})
		{
			# Fabricate a CSS class name for this node,
			# and stash it away for when we generate the CSS file.

			my($class_name) = $self -> class_name();

			$class_name++;

			$self -> class_name($class_name);

			my($hash_ref)           = $self -> class2depth();
			$$hash_ref{$class_name} = $depth;

			$self -> class2depth($hash_ref);

			# Start a div for this node.

			my($s) = $self -> format_attributes($node);

			if ($empty_tag)
			{
				$s .= ' /';
			}

			push @$output, qq|<div class = "$class_name">$Entitize{"<$tag$s>"}|;

			# Process this node's children.

			for $content ($node -> content_list() )
			{
				$self -> process($css_url, $depth, $content, $output);
			}

			$s = '</div>';

			if (! $empty_tag)
			{
				$s = qq|$Entitize{"</$tag>"}$s|;
			}

			push @$output, $s;
		}
		else
		{
			# It's the head-type tag, so just output it. This includes the real body tag.

			push @$output, "<$tag" . ($empty_tag ? ' /' : '') . '>';

			# Add commentry, if desired, just after we output the real body tag.

			if ($tag eq 'body')
			{
				if ($self -> caption() )
				{
					$self -> add_caption($output);
				}

				# Output a fake (i.e. visible) body tag.

				my($s) = $self -> format_attributes($node);

				push @$output, $Entitize{"<body$s>"};
			}

			# Process this node's children.

			for $content ($node -> content_list() )
			{
				$self -> process($css_url, $depth, $content, $output);
			}

			# Output the CSS link just before we output </head>.

			if ($tag eq 'head')
			{
				push @$output, qq|<link rel = "stylesheet" type = "text/css" href = "$css_url" />|;
			}

			if (! $empty_tag)
			{
				push @$output, "</$tag>";
			}
		}
	}
#	else
#	{
#		# This would include the input text in the output.
#
#		push @$output, $node;
#	}

} # End of process.

# -----------------------------------------------

sub run
{
	my($self)       = @_;
	my($root)       = HTML::TreeBuilder -> new();
	my($input_file) = $self -> input_file();
	my($result)     = $root -> parse_file($input_file) || die "Can't parse: $input_file";
	my($depth)      = 0;
	my($output)     = [];

	# Build the HTML output.

	$self -> process($self -> css_url(), $depth, $root, $output);
	$root -> delete();

	push @$output, $Entitize{'</body>'};

	# Write the HMTL file.

	my($html_output_file) = $self -> html_output_file();

	open(OUT, "> $html_output_file") || die "Can't open(> $html_output_file): $!";
	print OUT join("\n", @$output), "\n";
	close OUT;

	# Write the CSS file.

	$output              = $self -> build_css_file();
	my($css_output_file) = $self -> css_output_file();

	open(OUT, "> $css_output_file") || die "Can't open(> $css_output_file): $!";
	print OUT map{"$_\n"} @$output;
	close OUT;

} # End of run.

# -----------------------------------------------

1;

=pod

=head1 NAME

HTML::Revelation - Reveal HTML document structure in a myriad of colors

=head1 Synopsis

	#!/usr/bin/perl

	use strict;
	use warnings;

	use HTML::Revelation;

	# -------------------

	my($reveal) = HTML::Revelation -> new
	(
	 caption          => 1,
	 comment          => "DBIx::Admin::CreateTable's POD converted to HTML with my pod2html.pl",
	 css_output_file  => 'CreateTable.css',
	 css_url          => '/',
	 html_output_file => 'CreateTable.html',
	 input_file       => 'misc/CreateTable.html',
	);

	$reveal -> run();

Sample output:

http://savage.net.au/Perl-modules/html/CreateTable.html

=head1 Description

C<HTML::Revelation> is a pure Perl module.

=head1 Constructor and initialization

C<new()> returns a C<HTML::Revelation> object.

This is the class's contructor.

You must pass a hash to C<new()>.

Options:

=over 4

=item caption => 0 | 1

Use this key to display or suppress a caption (a table of information) at the start of the HTML output file.

The default is 0.

This key is optional.

=item comment => $s

Use this key to add a comment to the caption (if displayed).

The default is '' (the empty string).

This key is optional.

=item css_output_file => $s

Use this key to specify the name of the CSS output file.

The default is '' (the empty string).

This key is mandatory.

=item css_url => $s

Use this key to specify the URL of the CSS output file.

This URL is written into the HTML output file.

The default is '' (the empty string).

This key is mandatory.

=item html_output_file => $s

Use this key to specify the name of the HTML output file.

The default is '' (the empty string).

This key is mandatory.

=item input_file => $s

Use this key to specify the name of the HTML input file.

The default is '' (the empty string).

This key is mandatory.

=back

=head1 Method: add_caption()

Factor out the code which formats the caption.

=head1 Method: build_css_file()

Factor out the code which build the body of the CSS output file.

=head1 Method: load_colors()

Factor out the code which stores the data defining the available colors.

=head1 Method: run()

As shown in the synopsis, you must call C<run()> on your C<HTML::Revelation> object in order to
generate the output files.

=head1 FAQ

=over 4

=item Where did the colors come from?

From the Image::Magick web site. I extracted them from a web page there using the
amazing HTML::TreeBuilder module. See scripts/extract.colors.pl.

=item Why do you discard the first 220 colors?

Because they are too dark for my liking.

=item Why does the caption use CSS class c0003?

I like that color - it's nice and restful. I seriously considered using c0201.

=item I want to know which CSS class produces which color.

Patch line 743 to put ' $class_name' just inside the '|' at the end of the line.

=back

=head1 Modules Used

=over 4

=item accessors::classic

=item File::Spec

=item HTML::Entities::Interpolate

=item HTML::Tagset

=item HTML::TreeBuilder

=item List::Cycle

=back

=head1 Author

C<HTML::Revelation> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

	Australian copyright (c) 2008,  Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	the Artistic or the GPL licences, copies of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
