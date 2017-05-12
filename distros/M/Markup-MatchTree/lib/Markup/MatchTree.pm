package Markup::MatchTree;
$VERSION = '1.0.0';

####################################################
# This module is protected under the terms of the
# GNU GPL. Please see
# http://www.opensource.org/licenses/gpl-license.php
# for more information.
####################################################

use strict;
use Markup::MatchNode;

require Carp;
require Exporter;
require Markup::Tree;

our @ISA = qw(Markup::Tree);

sub new {
	my $invocant = shift();
	my $class = ref($invocant) || $invocant;
	$class = bless {
		_parser => undef,
		_globals => {
			relpath => ''
		},
		_tree => Markup::MatchNode->new( element_type => '-->root', tagname => '-->root', level => 0 ),

		callbacks => {},
		no_squash_whitespace => 0,
		parser_options => {}
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

	$self->{'_parser'} = XML::Parser->new( %{ $self->{'parser_options'} } );
	$self->_init_hookups ();
}

sub parse_file {
	my ($self, $glob) = (shift(), Markup::Tree::_mk_filehandle(shift()));
	$self->parse($glob);
}

sub _init_xml_hookups {
	Carp::croak ('_init_xml_hookups is not a MatchTree method');
}

sub _init_html_hookups {
	Carp::croak ('HTML can not be transformed to a MatchTree');
}

sub _init_hookups {
	my $self = shift();

	$self->{'_globals'}->{'level'} = 0;
	$self->{'_globals'}->{'last_node'} = $self->{'_tree'};
	$self->{'_globals'}->{'new'} = [ 1, undef ];

	$self->{'_parser'}->setHandlers('Start', sub {
		my ($expat, $tag, @attrs) = @_;
		my (%attrs, %options);
		return if ($tag eq 'template'); # throw out root node

		while (scalar(@attrs)) { $attrs{pop(@attrs)} = pop(@attrs); }

		delete $attrs{'/'};

		foreach (keys %attrs) {
			if (s/^_//) {
				$attrs{$_} = delete $attrs{'_'.$_};
				next;
			}

			foreach my $et (qw(element_type tagname text)) {
				if ($_ eq $et) {
					$options{$_} = delete $attrs{$_};
				}
			}

			if ($_ eq 'options') {
				@_ = split (',', $attrs{$_});
				foreach (@_) {
					if ($_ =~ m/call_filter(?:\s+)?\((.+?)\)/i) {
						if (exists $self->{'callbacks'}->{$1} &&
							ref($self->{'callbacks'}->{$1}) eq 'CODE')
						{
							push @{ $options{'options'}->{'call_filter'} },
								$self->{'callbacks'}->{$1};
						}
						else {
							Carp::croak ("callback '$1' does not exist or is"
									." not a CODE ref");
						}
					}
					elsif ($_ =~ m/ignore_attrs/i) {
						$options{'options'}->{'ignore_attrs'} = 1;
					}
					elsif ($_ =~ m/text_not_null/i) {
						$options{'options'}->{'text_not_null'} = 1;
					}
					elsif ($_ =~ m/ignore_children/i) {
						$options{'options'}->{'ignore_children'} = 1;
					}
					elsif ($_ =~ m/optional/i) {
						$options{'options'}->{'optional'} = 1;
					}
					else {
						Carp::croak ("Unrecognized option $_");
					}
				}

				delete $attrs{'options'};
			}
		}

		if ($tag eq 'section') {
			$options{'element_type'} = '-->section';
		}

		$options{'level'} = $self->{'_globals'}->{'level'};
		$options{'attr'} = \%attrs;
		$options{'tagname'} = $options{'element_type'} if (!$options{'tagname'});
		my $node = Markup::MatchNode->new ( %options );
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
				$text = Markup::Tree::_squash_whitespace ($text) if ($squash);
				return if (!$text);
			}
		}
		else {
			$text = Markup::Tree::_squash_whitespace ($text);
			return if (!$text);
		}

		if ($self->{'_globals'}->{'new'}->[0]) {
			my $estruct = Markup::MatchNode->new(element_type => '-->text', tagname => '-->text',
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

1;

__END__

=head1 NAME

Markup::MatchTree - For building trees to be compared to C<Markup::Tree>s.

=head1 SYNOPSIS

	use Markup::MatchTree;

	my $match_tree = Markup::MatchTree->new( no_squash_whitespace => \@same_as_I_used_for_Markup__Tree);
	$match_tree->parse_file ('http://localhost/site_template.xml');

=head1 DESCRIPTION

Most likely you won't need to use this module explicitly unless you are doing some
custom matching/parsing/extracting. Mainly this will be used by the upcoming
L<Markup::Content> module.

See L<Markup::Tree> for a description of the methods. The only difference is
C<MatchTree> dosen't accpet C<no_indent> as an argument. C<no_squash_whitespace> should
be the same value that was used for C<Markup::Tree>.

=head1 SEE ALSO

L<Markup::Tree>, L<Markup::TreeNode>, L<Markup::MatchNode>, L<Markup::Content>

=head1 AUTHOR

BPrudent (Brandon Prudent)

Email: xlacklusterx@hotmail.com