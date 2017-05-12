package Markup::Tree;
$VERSION = '1.2.2';

####################################################
# This module is protected under the terms of the
# GNU GPL. Please see
# http://www.opensource.org/licenses/gpl-license.php
# for more information.
####################################################

use strict;
use XML::Parser;
use HTML::TreeBuilder;
use Markup::TreeNode;
use File::Temp qw/ :POSIX /;
use LWP::Simple;

require Exporter;
require Carp;

our @ISA = qw(Exporter);

sub new {
	my $invocant = shift();
	my $class = ref($invocant) || $invocant;
	$class = bless {
		_parser => '',
		_globals => {},
		_tree => Markup::TreeNode->new( element_type => '-->root', tagname => '-->root', level => 0 ),
		markup => 'html',
		parser_options => undef,
		no_squash_whitespace => 0,
		no_indent => 0
	}, $class;
	$class->init(@_);
	return $class;
}

sub init {
	my $self = shift();
	my %arg = @_;

	foreach (keys %arg) {
		if (exists $self->{$_}) {
			$self->{$_} = $arg{$_};
		}
		else {
			Carp::croak ("unrecognized option $_");
		}
	}

	if ($self->{'markup'} eq 'xml') {
		$self->{'_parser'} = XML::Parser->new( %{ $self->{'parser_options'} } );
	}
	else {
		if ((!exists $self->{'parser_options'}->{'api_version'}) ||
			($self->{'parser_options'}->{'api_version'} != 3))
		{
			$self->{'parser_options'}->{'api_version'} = 3;
		}

		for ($self->{'_parser'}) {
			$_ = HTML::TreeBuilder->new( %{ $self->{'parser_options'} } );
			$_->ignore_unknown(0);
			$_->no_space_compacting(1);
			$_->store_comments(1);
			$_->store_declarations(1);
			$_->store_pis(1);
		}
	}

	$self->_init_hookups () if ($self->{'markup'} eq 'xml');
}

sub _work_around_pis {
	my $fh = shift();
	my $data;
	my $fix = sub {
		my ($style, $text) = @_;
		$text =~ s/"/%QUOTE%/g;
		return "\"{pi:language=$style:$text}\"";
	};
	$data = join '', <$fh>;

	# within ""s?
	$data =~ s/"<%(.+?)%>"/$fix->('asp-style', $1)/seg;
	$data =~ s/"<\?(?:php(?:\d)?)?(.+?)\?>"/$fix->('asp-style', $1)/seg;

	$data =~ s/<%(.+?)%>/<pi language = "asp-style">$1<\/pi>/sg;
	$data =~ s/<\?(?:php(?:\d)?)?(.+?)\?>/<pi language = "php-style">$1<\/pi>/sg;

	seek $fh, 0, 0;

	return $data;
}

sub parse_file {
	my ($self, $file) = @_;

	$file = _mk_filehandle($file);

	if ($self->{'markup'} eq 'xml') {
		$self->parse($file);
	}
	else {
	    $self->parse (_work_around_pis($file));
	    $self->eof();
	}

	close ($file);
	return $self; # so you can say Markup::Tree->new()->parse_file('foo.html');
}

sub parse {
	$_ = shift();
	$_->{'_parser'}->parse (shift());
	return $_;
}

sub eof {
	my $self = shift();
	if ($self->{'markup'} ne 'xml') {
		$self->{'_parser'}->eof ();
		$self->{'_parser'}->elementify();
		$self->_init_hookups();
	}
	return $self;
}

sub _init_hookups {
	my $self = shift();

	$self->{'_globals'}->{'level'} = 0;
	$self->{'_globals'}->{'last_node'} = $self->{'_tree'};

	if ($self->{'markup'} eq 'xml') {
		$self->_init_xml_hookups ();
	}
	else {
		$self->_init_html_hookups ();
	}
}

# TODO: bring anything before html up
sub _init_html_hookups {
	my $self = shift();
	my $build_tree;

	$build_tree = sub {
		my $tag = shift();
		my $node;
		my %options = ( level => $self->{'_globals'}->{'level'} );
		my $parent = $self->{'_globals'}->{'last_node'};
		my %mapping = ( '~text' => '-->text',
				'~comment' => '-->comment',
				'~declaration' => '-->declaration',
				'~pi' => '-->pi' ); # unlikely

		@_ = $tag->all_external_attr();
		while (@_) { $options{'attr'}->{pop(@_)} = pop(@_); }
		delete $options{'attr'}->{'/'};
		$tag->objectify_text();

		if (exists $mapping{$tag->tag()}) {
			$options{'element_type'} = $mapping{$tag->tag()};
			$options{'tagname'} = $options{'element_type'};
		}
		else {
			$options{'element_type'} = 'tag';
			$options{'tagname'} = $tag->tag();
		}

		if ($options{'element_type'} eq '-->text') {
			$options{'text'} = $tag->{'text'};
			if ($self->{'no_squash_whitespace'}) {
				if (ref($self->{'no_squash_whitespace'}) eq 'ARRAY') {
					my $squash = 1;
					foreach (@{ $self->{'no_squash_whitespace'} }) {
						if ($_ eq $self->{'_globals'}->{'last_node'}->{'tagname'}) {
							$squash = 0;
							last;
						}
					}
					if ($squash) {
						$options{'text'} = _squash_whitespace ($options{'text'});
						return if (!$options{'text'});
					}
				}
			}
			else {
				$options{'text'} = _squash_whitespace ($options{'text'});
				return if (!$options{'text'});
			}
		}

		$node = Markup::TreeNode->new(%options);

		while (($node->{'level'} - 1) != $parent->{'level'}) {
			if ($parent->{'parent'} eq '(empty)') { last; }
			$parent = $parent->{'parent'};
		}

		$node->attach_parent($parent);

		$self->{'_globals'}->{'last_node'} = $node;

		foreach my $child ($tag->content_list) {
			$self->{'_globals'}->{'level'}++;
			if ($child->isa('HTML::Element')) {
				$build_tree->($child);
			}
			else {
				Carp::croak("Don't recognize $child!");
			}
			$self->{'_globals'}->{'level'}--;
		}
	};

	$build_tree->($self->{'_parser'});
}

sub _squash_whitespace {
	my $text = shift();
	$text =~ s/^(?:\s+)/ /sm;
	$text =~ s/(?:\s+)$/ /sm;
	$text =~ s/(\s){2,}/$1/gsm;
	return ($text =~ m/^(?:\s+)?$/) ? undef : $text;
}

sub _init_xml_hookups {
	my $self = shift();
	$self->{'_globals'}->{'new'} = [ 1, undef ];

	$self->{'_parser'}->setHandlers('Start', sub {
		my ($expat, $tag, @attrs) = @_;
		my %attrs;
		while (scalar(@attrs)) {
			$attrs{pop(@attrs)} = pop(@attrs);
		}
		delete $attrs{'/'};
		my $node = Markup::TreeNode->new (element_type => 'tag', tagname => $tag, attr => \%attrs,
							level => $self->{'_globals'}->{'level'});
		my $parent = $self->{'_globals'}->{'last_node'};

		while (($node->{'level'} - 1) != $parent->{'level'}) {
			if ($parent->{'parent'} eq '(empty)') { last; }
			$parent = $parent->{'parent'};
		}

		$node->attach_parent($parent);

		$self->{'_globals'}->{'last_node'} = $node;
		$self->{'_globals'}->{'level'}++;
		$self->{'_globals'}->{'new'} = [ 1, undef ];
	});

	$self->{'_parser'}->setHandlers('Char', sub {
		my ($expat, $text) = @_;

		if ($self->{'no_squash_whitespace'}) {
			if (ref($self->{'no_squash_whitespace'}) eq 'ARRAY') {
				my $squash = 1;
				foreach (@{ $self->{'no_squash_whitespace'} }) {
					if ($_ eq $self->{'_globals'}->{'last_node'}->{'tagname'}) {
						$squash = 0;
						last;
					}
				}
				$text = _squash_whitespace ($text) if ($squash);
				return if (!$text);
			}
		}
		else {
			$text = _squash_whitespace ($text);
			return if (!$text);
		}

		if ($self->{'_globals'}->{'new'}->[0]) {
			my $estruct = Markup::TreeNode->new(element_type => '-->text', tagname => '-->text',
						level => ($self->{'_globals'}->{'last_node'}->{'level'} + 1),
						text => $text);

			$self->{'_globals'}->{'last_node'}->attach_child($estruct);

			$self->{'_globals'}->{'new'} = [ 0, $estruct ];
		}
		else {
			$self->{'_globals'}->{'new'}->[1]->{'text'} .= $text;
		}
	} );

	$self->{'_parser'}->setHandlers('End', sub {
		$self->{'_globals'}->{'level'}--;
	});
}

sub get_node {
	my ($self, $description) = @_;
	$description = lc $description;
	my $fault = 1;

	foreach (qw(first last start end root copy-of copy copy_of)) {
		if ($description eq $_) {
			$fault = 0;
			last;
		}
	}

	if ($fault) {
		Carp::croak ("Unknown node description $description.");
	}

	if (($description eq 'copy-of') || ($description eq 'copy') || ($description eq 'copy_of')) {
		return ($self->{'_tree'}->copy_of());
	}

	if (($description eq 'first') || ($description eq 'start')) {
		return ($self->{'_tree'}->next_node());
	}

	if (($description eq 'last') || ($description eq 'end')) {
		my $ret;
		$self->foreach_node(sub { $ret = shift(); });
		return ($ret);
	}

	return $self->{'_tree'};
}

sub foreach_node {
	my ($self, $start_callback, $end_callback, $start_from) = @_;
	my $walk_tree;

	if (!$start_from) {
		if ($end_callback && UNIVERSAL::isa($end_callback, 'Markup::TreeNode')) {
			$start_from = $end_callback;
			$end_callback = undef;
		}
		else {
			$start_from = $self->{'_tree'};
		}
	}

	if (!($start_callback || (ref($start_callback) ne 'CODE'))) {
		Carp::croak ("parameter 0 is not a CODE reference");
	}

	$walk_tree = sub {
		my $tree = shift();

		if (ref($tree) eq 'ARRAY') {
			for (my $i = 0; $i < scalar(@{ $tree }); $i++) {
				$walk_tree->($tree->[$i]);
			}
		}
		elsif ($tree->isa('Markup::TreeNode')) {
			if ($tree->{'element_type'} eq '-->ignore') {
				$walk_tree->($tree->{'children'});
				return;
			}
			return if (!$start_callback->($tree));
			$walk_tree->($tree->{'children'});
			if ($end_callback && ref($end_callback) eq 'CODE') {
				return if (!$end_callback->($tree));
			}
		}
	};

	$walk_tree->($start_from);
}

sub save_as {
	my ($self, $file, $file_type) = @_;

	if (!$file_type) {
		if ($file =~ m/\.xml$/i) {
			$file_type = 'xml';
		}
		else {
			$file_type = 'html';
		}
	}

	$file_type = lc $file_type;

	$file = _mk_filehandle_write($file);

	print $file '<?xml version = "1.0" encoding = "iso-8859-1"?>'."\n";
	if ($file_type =~ '(?:x)?html') {
		print $file '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" ';
		print $file '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'."\n";
	}

	$self->foreach_node(
		sub {
			my $node = shift();

			return 1 if ($node->{'element_type'} eq '-->root');
			return 1 if ($node->{'element_type'} eq '-->declaration');

			print $file '<!-- '.$node->{'text'}." -->\n" and return 1
				if ($node->{'element_type'} eq '-->comment');

			print $file $self->_rindent($node);
			unless ($node->{'element_type'} eq '-->text') {
				print $file "<".$node->{'tagname'};
				foreach (keys %{ $node->{'attr'} }) {
					print $file " $_ = \"".$node->{'attr'}->{$_}."\"";
				}
				if (!scalar(@{$node->{'children'} || []})) {
					print $file ' /';
				}
			}
			print $file (($node->{'element_type'} eq '-->text') ? $node->{'text'} : ">")."\n";
			return 1;
		},
		sub {
			my $node = shift();

			return 1 if ($node->{'element_type'} eq '-->root');
			return 1 if ($node->{'element_type'} eq '-->declaration');
			return 1 if (!scalar(@{$node->{'children'} || []}));
			return 1 if ($node->{'element_type'} eq '-->text');

			print $file $self->_rindent($node);
			print $file '</'.$node->{'tagname'}.">\n";

			return 1;
		}
	);

	close ($file) or Carp::croak ("Could not close file - $!");
}

sub _rindent {
	my ($self, $node) = @_;
	my $ident = $node->{'level'};
	my $buf = "";

	if ($self->{'no_indent'}) {
		return if (ref($self->{'no_indent'}) ne 'ARRAY');
		my $indent = 1;
		foreach (@{ $self->{'no_indent'} }) {
			if ($_ eq $node->{'tagname'}) { $indent = 0; last; }
		}

		return if (!$indent);
	}

	while ($ident--) {
		$buf .= "\t";
	}

	return $buf;
}

sub _mk_filehandle {
	my $something = shift();

	return $something if (ref($something) eq 'GLOB');

	if ($something =~ m-^(?:ht|f)tp://-) {
		my ($data, $fn) = ('', tmpnam());
		$data = get($something) or Carp::croak("Could not access url $something. $!");
		print $fn $data;
		seek ($fn, 0, 0);
		return ($fn);
	}

	open (TMP, $something) or Carp::croak("Could not open $something for reading. $!");
	return (\*TMP);
}

# won't really work on GLOBs X(
sub _mk_filehandle_write {
	my $something = shift();

	if (ref($something) eq 'GLOB') {
		open (W, ">&=", fileno($something));
		return (\*W);
	}

	if ($something =~ m-^(?:ht|f)tp://-) {
		Carp::croak("writable urls are not supported");
	}

	open (TMP, '>', $something) or Carp::croak("Could not open $something for reading. $!");
	return (\*TMP);
}

sub tree { shift()->{'_tree'}; }

sub copy_of {
	my $self = shift();
	my ($newbie => %options); # if you don't know you betta' axe somebody!

	foreach (keys %{ $self }) {
		$options{$_} = $self->{$_};
	}

	foreach (qw(_parser _globals _tree)) {
		delete $options{$_};
	}

	$newbie = $self->new(%options);

	$newbie->{'_tree'} = $self->get_node('first')->copy_of();

	return ($newbie);
}

1;

__END__

=head1 NAME

Markup::Tree - Unified way to easily access XML or HTML markup locally or remotly.

=head1 SYNOPSIS

	use Markup::Tree;

	my @preserve = qw(pre style script code);

	my $tree = Markup::Tree->new ( markup => 'html', no_squash_whitespace => \@preserve,
					no_indent => \@preserve );

	$tree->parse_file('http://lackluster.tzo.com:1024');

	$tree->save_as('ltzo.com.xml', 'xml');

	# or

	my $tree = Markup::Tree->new ( markup => 'xml', no_squash_whitespace => \@preserve,
					no_indent => \@preserve );

	$tree->parse_file('http://lackluster.tzo.com:1024/index.php.xml');

	$tree->foreach_node(\&start, \&end);

=head1 DESCRIPTION

I wanted a module to allow one to access either XML or HTML input, locally or remotely, easily
transform it, and save it as HTML or XML (or some user-defined format). So I quit whining and
wrote one. It's not 100% finished, but it's a good start and the groundwork for the
L<Markup::Content> module.

=head1 CONVENTIONS

I will be reopening certain terms to save myself keystrokes and you confusion (or does that
just create confusion?).

=over 4

=item FILE

When I mention FILE, what I really mean is either a local or remotely mounted file
C<(i.e - /home/bprudent/this_xml_file.xml)>, an already opened filehandle, or
a remote file location of which L<LWP::Simple>'s get is capable of, well, getting.

Note that if you pass an open filehandle to a method that wants to read from it,
you should open it for reading, and if the method wants to write to it, you should
open it for writing. Also, we cannot write to a remote location (at least, the
functionality does not exist in this module to do so) so please don't pass a
remote location to a method that wants to write something (such as the save_as method).

=item pi

I see alot of people using pi or (p)rocessing (i)nstruction to mean a local procressing directive.
I am using here and in C<TreeNode> to mean also server-side instructions, which are often
found in the wild. Please remember that you will not see these from a remote URL.

=back

=head1 ARGUMENTS

These are the arguments you can specify upon instantiation. In most cases you can also set
them yourself after you have an object of this class via $tree->{'the_option'} = $whatever.

=over 4

=item markup

Valid options are 'xml' or 'html'. This just specifies which parser to use. I would like to,
in the future, add more parsers to this list. The default is 'html', which is much more
forgiving.

=item parser_options

This parameters requests an anonymous hash with parser-specific options. If you specified
'xml' for markup then the C<parser_options> argument will be passed to L<XML::Parser>.
Otherwise it will go to L<HTML::TreeBuilder>.

=item no_squash_whitespace

There are three modes to this argument:

=over 4

=item mode 0

Squash all whitespace. This is the default mode.

=item mode 1

Set C<no_squash_whitespace> to a true value to keep the tree as close to the original document
as possible.

=item mode 2

Set C<no_squash_whitespace> to an anonymous array containing tagnames of which you want to
preserve. This is handy when re-creating or transforming HTML documents containing pre-formatted
text, such as C<script>, C<style>, C<pre>, or, sometimes, C<code>. It is also wise to include the
fabricated tag, pi. This is the tag that is made up when either <% or <? is encountered, except
when within quotes. See Also L<Markup::TreeNode> for a bit more on this.

=back

Example:

	my $tree = Markup::Tree->new ( no_squash_whitespace => [qw(script style pre code)] );

=item no_indent

It's all in the name. This value affects only (as of now) the save_as method.
Again, there are three operating modes:

=over 4

=item mode 0

Leave indentation on. This is the default mode.

=item mode 1

Setting C<no_indent> to a true value will never indent.

=item mode 2

Set C<no_indent> to an anonymous array containing tagnames of which you want to not indent.
This is normally the same value as no_squash_whitespace.

=back

=back

=head1 METHODS

=over 4

=item get_node (description)

Arguments:

=over 4

=item description

Description must be one of the following: C<first>, C<last>, C<start>, C<end>, C<copy-of>, C<copy>, C<copy_of>, or C<root>.

=over 4

=item first

Causes the method to return the first node in the tree, not including the C<root> node.
This is the first actual element found in the markup source.

=item last

Causes the method to return the last node in the tree.

=item start

An alias for C<first>.

=item end

An alias for C<last>.

=item copy-of

Returns a copy of the entire tree. This allows you to have two copies in
memory. One that you can chop to bits and another that you can preserve.

=item copy

An alias for C<copy-of>.

=item copy_of

An alias for C<copy-of>.

=item root

Causes the method to return the root node. This is equivalant to $tree->tree.

=back

=back

Example:

	my $first_node = $tree->get_node('first');
	print "The first node in the tree is a ".$first_node->{'tagname'}." node.\n";

=item parse_file (FILE)

Arguments:

=over 4

=item FILE to be parsed

=back

Example:

	$tree->parse_file ('http://lackluster.tzo.com:1024');
	# or
	$tree->parse_file (\*INPUT);
	# or
	$tree->parse_file ('/home/lackluster/public_html/index.html');

Returns: a refrence to the parser so that you can say things like

	$tree = Markup::Tree->new()->parse_file('noname.html');

Note that this will close the file(handle).

=item parse (DATA)

Just the same as HTML or XML ::Parse's parse method. Pass in markup data.
For HTML you will need to call eof().

Returns: a refrence to the parser

=item eof ( )

Signals the end of HTML markup. Calling eof on XML data will not
generate an error, it just won't do anything.

Returns: a refrence to the parser

=item save_as (FILE [, type])

Saves the tree to FILE as type, if specified.

Arguments:

=over 4

=item FILE

This is the filename or handle to write the information in. If this
argument is textual, the method will try to guess, based on the
file extension, the second argument if not present.

=item type

Valid values are 'html' or 'xml'. Will also accept 'xhtml'.
Default is 'html'.

=back

Example:
	$tree->save_as ('/home/lackluster/public_html/transformed.html.xml', 'xml');

=item foreach_node (start_CODE [, end_CODE] [, start_from])

Loops through each node in the syntax tree, calling C<start_CODE>
and, if present, end_CODE. This method makes looping through the tree really
quite simple and lends itself well to saving files to your own format.

Arguments:

=over 4

=item start_CODE

This CODE ref will be called when a node is encounted and before its children
have been processed. A L<Markup::TreeNode> element will be passed to your sub.

=item end_CODE

If this parameter is present, then the CODE ref will be called after a node is
encountered and after its children have been processed. If end_CODE is not
a CODE ref, but instead a L<Markup::TreeNode>, the method will interpret
C<end_CODE> as C<start_from>.

=item start_from

Instead of looping over the whole tree, this value can be a L<Markup::TreeNode>
start point. (See L</BUGS> section)

Example:
	$tree->foreach_node(
		sub {
			my $node = shift();
			indent($node->{'level'});
			print $node->{'tagname'}."\n";
		},
		sub {
			my $node = shift();
			indent($node->{'level'});
			print $node->{'tagname'}."\n";
		}
	);

=back

B<RETURN VALUES MATTER!>

Returning a false value will end the iterations and cause the method to return.
Return true to keep processing.

=item copy_of

Returns a copy, not a reference, of the tree.

=back

=head1 CAVEATS

This module isn't really the best for people who don't often use markup. It
requires quite a few modules (I actually feed bad about the module requirements),
and C<HTML::TreeBuilder> or C<XML::Parser> is probably a better choice for most things you want to
do. On the upside, if you already have these modules, it is a comparativly easy
way to use markup.

=head1 BUGS || UNFINISHED

"Wide character in print" warnings are abound. I haven't taken the time to look into this.
Something about UNICODE?

The C<foreach_node> method doesn't behave properly when passed the start_from parameter.
That's what I thought, at least. The behaviour may work for you in your situation. Just
know that it may change in the future unless anyone requests otherwise.

Please inform me of other bugs.

=head1 SEE ALSO

L<Markup::TreeNode>, L<XML::Parser>, L<HTML::TreeBuilder>, L<LWP::Simple>

=head1 AUTHOR

BPrudent (Brandon Prudent)

Email: xlacklusterx@hotmail.com