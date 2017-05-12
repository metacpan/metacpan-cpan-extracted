package Markup::Content;
$VERSION = '1.0.1';

####################################################
# This module is protected under the terms of the
# GNU GPL. Please see
# http://www.opensource.org/licenses/gpl-license.php
# for more information.
####################################################

use strict;
use Markup::Tree;
use Markup::TreeNode;
use Markup::MatchTree;

require Exporter;
require Carp;

our @ISA = qw(Exporter);

sub new {
	my $invocant = shift();
	my $class = ref($invocant) || $invocant;
	$class = bless {
		_tree            =>  {
					tree  => undef,
					minor => [],
					major => []
				     },

		template      	 => undef,
		template_options => { },
		target           => undef,
		target_options   => { },
		template_name    => 'default template'
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

	if (defined $self->{'target'}) {
		$self->set_target($self->{'target'})
	}

	if (defined $self->{'template'}) {
		$self->set_template($self->{'template'});
	}
}

sub set_target {
	my ($self, $target) = @_;

	if (UNIVERSAL::isa($target, 'Markup::Tree')) {
		$self->{'target'} = $self->{'_tree'};
		$self->{'target'}->{'tree'} = $target->copy_of();
	}

	$_ = $self->{'target'};
	$self->{'target'} = $self->{'_tree'};
	$self->{'target'}->{'tree'} = Markup::Tree->new(%{ $self->{'target_options'} });
	$self->{'target'}->{'tree'}->parse_file($_);

	return ($self->{'target'}->{'tree'});
}

sub set_template {
	my ($self, $template) = @_;

	$self->{'template'} = $template and return($self->{'template'})
		if (UNIVERSAL::isa($template, 'Markup::MatchTree'));

	$_ = $self->{'template'};
	$self->{'template'} = Markup::MatchTree->new(%{ $self->{'template_options'} });
	$self->{'template'}->parse_file($_);

	return ($self->{'template'});
}

sub extract {
	my $self = shift();

	Carp::croak ('No target or template') if (!($self->{'target'}->{'tree'} || $self->{'template'}));

	$self->mark_content ('forward');

	$self->mark_content ('backward');

	$self->{'_tree'}->{'tree'}->foreach_node (sub {
		my $node = shift();

		if ($node->{'element_type'} eq '-->section' && $node->{'tagname'} eq 'CONTENT') {
			$_[0] = $node->{'child_num'};
			$_ = $node->next_node();
			do {
				if ($_->{'element_type'} eq '-->section' && $_->{'tagname'} eq 'CONTENT') {
					$_[1] = $_->{'child_num'} - 1;
					while ($_[0] < $_[1]) {
						$node->attach_child($node->{'parent'}->{'children'}->[
							$_[1]--
						]->drop());
					}
					@{$node->{'children'}} = reverse @{$node->{'children'}};
					$self->{'_tree'}->{'tree'} = Markup::Tree->new(
							no_indent => $self->{'_tree'}->{'tree'}->{'no_indent'}
					);
					$self->{'_tree'}->{'tree'}->get_node('root')->attach_child($node);
					return 0;
				}
			} while ($_ = $_->next_node());
			return 0;
		}
		return 1;
	});

	return $self->{'_tree'}->{'tree'};
}

sub tree {
	shift()->{'_tree'}->{'tree'};
}

sub mark_content {
	my ($self, $dir) = @_;
	my ($move_node => $insert_marker);
	my ($template_node => $target_node);
	if ($dir eq 'forward') {
		$move_node = sub { shift()->next_node(); };
		($template_node, $target_node) = ($self->{'template'}->get_node('root'),
							$self->{'_tree'}->{'tree'}->get_node('root'));
		$insert_marker = sub { shift()->previous_node()->insert(Markup::TreeNode->new(
							element_type => '-->section',
							tagname => 'CONTENT'), 'before'); };
	}
	else {
		$move_node = sub { shift()->previous_node(); };
		($template_node, $target_node) = ($self->{'template'}->get_node('last'),
							$self->{'_tree'}->{'tree'}->get_node('last'));
		$insert_marker = sub { shift()->insert(Markup::TreeNode->new(
							element_type => '-->section',
							tagname => 'CONTENT'), 'before'); };
	}

	do {
		if ($template_node->{'element_type'} eq '-->section' && $template_node->{'tagname'} eq 'CONTENT') {
			$insert_marker->($target_node);
			return;
		}

		my @res = $template_node->compare_to($target_node);
		if (scalar(@res) == 2) {
			$self->{'_tree'}->{'minor'}->[0] += $res[0]->[0];
			$self->{'_tree'}->{'minor'}->[1] += $res[0]->[1];
			$self->{'_tree'}->{'minor'}->[2] += $res[0]->[2];
			$self->{'_tree'}->{'major'}->[0] += $res[1]->[0];
			$self->{'_tree'}->{'major'}->[1] += $res[1]->[1];
			$self->{'_tree'}->{'major'}->[2] += $res[1]->[2];
		}
		else {
			if ($res[0] eq 'optional') {
				$template_node = $move_node->($template_node);
			}
			else {
				$target_node = $move_node->($target_node);
			}
		}
	} while (($template_node = $move_node->($template_node)) && ($target_node = $move_node->($target_node)));
}

# TODO: write this method -> HTML => XML template
sub mk_template {
	my ($self, $out) = @_;
	my $data;
	$out = \$data if (!$out);

	Carp::croak ('No target') if (!($self->{'target'}->{'tree'}));

	$self->{'_tree'}->{'tree'}->foreach_node(sub {
		my $node = shift();


	});
}

1;

__END__

=head1 NAME

Markup::Content - Extract content markup information from a markup document

=head1 SYNOPSIS

	my $content = Markup::Content->new(
				target => 'noname.html',
				template => 'noname.xml',
				target_options => {
					no_squash_whitespace => [qw(script style pi code pre textarea)]
				},
				template_options => {
					callbacks => {
						title => sub {
							print shift()->get_text();
						}
					}
				});

	$content->extract();

	$content->tree->save_as(\*STDOUT);

=head1 DESCRIPTION

This modules uses a description of another markup page (template) to match
against a specified markup document (target). The point is to extract
formatted content from a markup page. While this module in itself lends
a good deal of flexibility and reuse, the script [to be] written around this
module is probably a better choice. See L<http://sourceforge.net/projects/content-x>.

=head1 ARGUMENTS

=over 4

=item template

This can be a file name, glob or internet address, or if you already have a
L<Markup::MatchTree> you want to use as the template, you
may set this argument to the tree. This argument will be passed directly
to the C<set_template> method. See the section C<TEMPLATES> for more information
on what is meant by "template".

=item template_options

This HASHREF will be sent directly to L<Markup::MatchTree> as the C<parser_options>
option.

=item target

This can be a file name, glob or internet address, or if you already have a
L<Markup::Tree> you want to use as the target, you
may set this argument to the tree. This argument will be passed directly
to the C<set_target> method.

=item target_options

This HASHREF will be sent directly to L<Markup::Tree> as the C<parser_options>
option.

=item template_name

The name of the template. This is unused right now, but will eventually be
a nice-to-have-if-set option.

=back

=head1 METHODS

=over 4

=item set_template(FILE|C<Markup::MatchTree>)

Makes a template tree from the FILE or C<Markup::MatchTree>.
See the section C<TEMPLATES> for more information
on what is meant by "template".

=item set_target(FILE|C<Markup::Tree>)

Makes a target tree from the FILE or C<Markup::Tree>.

=item extract

Based on the C<template> and C<target> it will build a
Markup::Tree, with just the content, accessible as $content->tree.

=back

=head1 TEMPLATES

A template, as wanted by this module, is nothing more than a simple XML
document. I will try to outline the document structure below.

The XML root node should be template.

	<template>

There are only two kinds of tags - C<match> or C<section>.

	<match />
	<section />

There are four known attributes: C<tagname>, C<options>, C<element_type>, and C<text>.

	<match element_type = "-->text" tagname = "-->text" options = "text_not_null" text = "{!!}" />

Section elements are only used to mark off sections (as you may have guessed). The name of the section
is specified in the tag by the C<tagname> known attribute.

	<section tagname = "nav1">
		<match tagname = "a" _href = "{!!}" />
	</section>

Generally section elements will only be used to mark off content. This, of course
does not require children, and the tagname B<must> be I<CONTENT>.

	<section tagname = "CONTENT" />

Match elements are used to match elements of the target.

Attributes are defined with a leading underscore.

	<match tagname ="a" _href = "{!^http://!}" _title = "outside link" />

These are unknown or unnamed attributes. Known attributes are a short list
of pre-defined keywords. It is perfectly fine to have an unknown attribute
the same as a known attribute, such as:

	<match tagname = "tagname" _tagname = "the_tag_name" />

This is unlikely to be encountered in the wild, as HTML tags don't
have any validity to the known attributes. We will describe our known
attributes more clearly below.

=head2 Known Attributes

=over 4

=item tagname

This represents the name of the element. Likely it will correspond to an HTML tag.

=item element_type

This will be directly mapped into L<Markup::MatchTree> as the elements element_type.
See the C<element_type> description under L<Markup::Tree> for a list of meaningful
values.

=item text

Useful only if element_type is "-->text". Note that text need not be specified only
with <match element_type = "-->text" /> elements. It could also be betwen <match>
tags, like so:

	<match tagname = "p">some text</p>

=item options

This is a comma-seperated (,) list of options. Options may be one or more of the
following:

=over 4

=item call_filter(CALLBACK)

CALLBACK is the name of a key of the HASHREF option whose value is a CODEREF
of L<Markup::MatchTree>s C<callback> arguments. An example will do nicely
here.

	my $content = Markup::Content->new( target => 'http://foobar/',
				template => '~/sites/foobar/foobar.xml',
				template_options => {
					callbacks => {
						my_callback_filter => sub {
							my $node = shift();
							print $node->drop()->{'tagname'}, "\n";
						},
						another_callback_filter => sub {
							my $node = shift();
							do {
								if ($node->{'element_type'} eq '-->text') {
									print $node->{'text'};
								}
							} while ($node = $node->next_node());
						}
					}
				});

=item text_not_null

If the C<text> or next text element of the specified element contains more than
whitespace, this option will not mark it as an error.

=item ignore_children

If this option is specified, all children of the element will be ignored, but
not the element itself.

=item optional

This option marks the element as optional. That is to say, if the
element does not appear in the target document, it will not be
marked as an error.

=item ignore_attrs

Attributes will not be considered if this option is specified.

=back

=back

In addition to the above knowledge, there is only one more
property to consider. All text or attributes need not be
an exact match. By surrounding text or attribute values with
{! and !} you are saying, "use the perl5 regular expression
specified between {! and !} to match the target element".
Luckily you don't have to actually say all that!

Please see C<noname.html>, C<noname.xml> and C<noname.pl> in this
distribution for a small example of this module, what it does, and
a bit on how to use it.

=head1 CAVEATS

This module is B<I<HIGHLY>> experimental. It may save your life,
job or carrer. It is also liable to get you fired, get you divorced,
or put sugar in your gastank. I would love to hear your
success/horror stories.

=head1 SEE ALSO

L<Markup::Tree>, L<Markup::MatchTree>, L<http://sourceforge.net/projects/content-x>

=head1 AUTHOR

BPrudent (Brandon Prudent)

Email: xlacklusterx@hotmail.com
