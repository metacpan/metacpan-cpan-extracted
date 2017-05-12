package Markup::MatchNode;
$VERSION = '1.0.0';

####################################################
# This module is protected under the terms of the
# GNU GPL. Please see
# http://www.opensource.org/licenses/gpl-license.php
# for more information.
####################################################

use strict;
use Carp;

require Markup::TreeNode;

our @ISA = qw(Markup::TreeNode);
our $empty = '(empty)';

sub new {
	my $invocant = shift();
	my $class = ref($invocant) || $invocant;
	$class = bless {
		element_type	=> 'tag',
		tagname		=> '',
		attr		=> { },
		level		=> 0,
		parent		=> $empty,
		child_num	=> 0,
		children	=> [ ],
		text		=> '',
		options		=> { }
	}, $class;
	$class->init (@_);
	return $class;
}

sub init {
	my $self = shift();
	my %args = @_;

	foreach (keys %args) {
		# enforce integrity
		if ($_ eq 'parent' && $args{$_} ne $empty) {
			$self->attach_parent($args{$_});
			next;
		}

		# enforce integrity
		if ($_ eq 'children') {
			$self->attach_children($args{$_});
			next;
		}

		if (exists $self->{$_}) {
			$self->{$_} = $args{$_};
		}
		else {
			croak ("unrecognized node option $_");
		}
	}
}

sub _ignore_me {
	my $self = shift();

	while (($self = $self->{'parent'}) ne $empty) {
		return 1 if ($self->{'options'}->{'ignore_children'});
	}

	return 0;
}

sub compare_to {
	my ($self, $treenode) = @_;

	return undef if ($self->_ignore_me());

	if (scalar(@{ $self->{'options'}->{'call_filter'} || [] })) {
		foreach (@{$self->{'options'}->{'call_filter'}}) {
			$_->($self);
		}

		return undef;
	}

	my (@minor, @major);
	@minor = (0, 0, 0, '');
	@major = (0, 0, 0, '');
	# array positions: [0] == possible errors : [1] == correct points : [2] percent correct : [3] errors
	my $similar = sub {
		my ($nodeA, $nodeB) = @_;

		if ($nodeA eq $empty && $nodeB eq $empty) {
			return (1);
		}

		if ($nodeA eq $empty || $nodeB eq $empty) {
			return (0);
		}

		return ((($nodeA->{'element_type'} eq $nodeB->{'element_type'}) &&
			($nodeA->{'tagname'} eq $nodeB->{'tagname'})));
	};
	my $calc = sub {
		my ($minor, $major, $list) = @_;

		$minor->[3] =~ s/^://;
		$major->[3] =~ s/^://;

		$minor->[2] = _percent($minor->[1], $minor->[0]);
		$major->[2] = _percent($major->[1], $major->[0]);
		return $list ? ($minor, $major) : int((($minor->[2] + $major->[2]) / 2));
	};

	if ($self->{'text'}) {
		$minor[0]++;
		if ($self->{'options'}->{'text_not_null'}) {
			if ($treenode->{'text'} =~ m/(?:\S+)/) {
				$minor[1]++;
			}
			else {
				$minor[3] .= ':text is null where option text_not_null was specified';
			}
		}
		elsif ($self->{'text'} =~ m/^{!(.+)!}/) {
			if ($treenode->{'text'} =~ m/$1/) {
				$minor[1]++;
			}
			else {
				$minor[3] .= ":your regular expression /$1/ did not match the text";
			}
		}
		elsif ($self->{'text'} eq $treenode->{'text'}) {
			$minor[1]++;
		}
		else {
			$minor[3] .= ':unmatched text';
		}
	}

	$_ = \@minor;

	# these are tags which, if out of place, I find to be major errors
	foreach my $j (qw(table td tr tbody map object img body head title html)) {
		if ($self->{'tagname'} eq $j) {
			$_ = \@major; last;
		}
	}

	$_->[0]++;
	if ($similar->($self, $treenode)) {
		$_->[1]++;
	}
	else {
		# optional nodes get special treatment :)
		if ($self->{'options'}->{'optional'}) {
			return 'optional';
		}

		$_->[3] .= ':nodes are not simliar';

		# no point in going on - this node is out of place!
		return $calc->(\@minor, \@major, wantarray);
	}

	unless ($self->{'options'}->{'ignore_attrs'}) {
		foreach (keys %{ $self->{'attr'} }) {
			$minor[0]++;
			if ($self->{'attr'}->{$_} =~ m/^{!(.+)!}/) {
				if ($treenode->{'attr'}->{$_} =~ m/$1/) {
					$minor[1]++;
				}
				else {
					$minor[3] .= ":attribute '$_' could not be matched with /$1/";
				}
			}
			elsif ($self->{'attr'}->{$_} eq $treenode->{'attr'}->{$_}) {
				$minor[1]++;
			}
			else {
				$minor[3] .= ":attribute '$_' could not be matched";
			}
		}
	}

	return $calc->(\@minor, \@major, wantarray);
}

sub _percent {
	my ($div, $by) = @_;
	return 100 if (!$div && !$by);
	return (int(($div /((!$by) ? 1 : $by)) * 100));
}

sub _avg {
	my ($res, $cnt);
	foreach (@_) {
		$res += $_;
		$cnt++;
	}
	return (int($res / $cnt));
}

1;

__END__

=head1 NAME

Markup::MatchNode - Comparison object of Markup::TreeNode.

=head1 SYNOPSIS

	use Markup::MatchNode;

	my $node = Markup::MatchNode->new( tagname => 'p', attr => { align => 'center' } );
	$_ = $node->compare_to(Markup::TreeNode->new( tagname => 'p', attr => { align => 'left' } ));

	print "Percent correct: $_\n";

=head1 DESCRIPTION

Pretty much exactly the same as L<Markup::TreeNode>. The major difference is the C<compare_to> method.
Likely you won't need this module explicitly. It is mostly used with L<Markup::Content>.

=head1 METHODS

All the same as L<Markup::TreeNode> with the notable exception of C<compare_to>, listed below.

Please note the following terminology:

A B<Major Error> occurs when one of the following tag nodes is out of place: table, td, tr, tbody, map, object, img, body, head, title, and html.

A B<Minor Error> is any error that is not a B<Major Error>. This could be unmatched text an unmatched attribute, an unmatched tag node or any other error.

=over 4

=item compare_to (L<Markup::TreeNode>)

This compares the current MatchNode to the specified TreeNode. Generally you won't need to explicitly
call this method or use this module unless you are performing some custom matching routines.

Returns: In scalar context it returns the percentage correct. The example under SYNOPSIS should yeild 75.
In list context two references to arrays are returned. The first index is the complete stats on the minor
errors. Index zero of this array reference is the total number of possible correct points. The second index
is the total correct points. The following index is the percent correct. The last index of the array reference
is a colon(:)-seperated list of reasons why the nodes did not match. The second array reference represents
the major errors and the array indices exactly mirror the minor errors.

Example:

	my $node = Markup::MatchNode->new( tagname => 'p', attr => { align => 'center' } );

	# scalar context
	$_ = $node->compare_to(Markup::TreeNode->new( tagname => 'p', attr => { align => 'left' } ));
	print "Percent correct: $_%\n";

	# list context
	@_ = $node->compare_to(Markup::TreeNode->new( tagname => 'p', attr => { align => 'left' } ));
	$_[0]->[3] =~ s/:/\n\t\t\t\t\t/g;
	$_[1]->[3] =~ s/:/\n\t\t\t\t\t/g;
	$_ = int((($_[0]->[2] + $_[1]->[2]) / 2));
	print <<EOF;

	Error	Correct		Total	Percent	Reasons
	------------------------------------------------------------------------
	Minor	$_[0]->[1]	of	$_[0]->[0]	($_[0]->[2]%)	$_[0]->[3]
	Major	$_[1]->[1]	of	$_[1]->[0]	($_[1]->[2]%)	$_[1]->[3]
	Total				($_%)
	EOF

=back

=head1 SEE ALSO

L<Markup::TreeNode>, L<Markup::MatchTree>, L<Markup::Tree>, L<Markup::Content>

=head1 AUTHOR

BPrudent (Brandon Prudent)

Email: xlacklusterx@hotmail.com