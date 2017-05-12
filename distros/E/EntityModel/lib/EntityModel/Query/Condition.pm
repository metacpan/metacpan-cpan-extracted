package EntityModel::Query::Condition;
{
  $EntityModel::Query::Condition::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query::Base}],
	'expr' => { type => 'string' },
	'branch' => 'object'
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Query::Condition - a condition clause for where, on etc.

=head1 VERSION

version 0.102

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	$self->branch($self->parseCondition(ref $_[0] ? (@_) : ({ @_ })));
	return $self;
}

=head2 inlineSQL

Returns the "inline SQL" representation for this condition. See L<EntityModel::Query> description for more details on what this means.

=cut

sub inlineSQL {
	my $self = shift;
	return [ $self->parseBranch($self->branch) ];
}

=head2 parseCondition

An array reference expands out as follows:

 [ x => 3 ]

=cut

sub parseCondition {
	my $self = shift;
	my $data = shift;

# Accept hashrefs, but turn them into arrayref by default.
	$data = [ %$data ] if ref $data ~~ 'HASH';

	my @list = @$data;

	my @node;
	my @tree;
	ITEM:
	while(@list) {
		my $k = shift(@list);
		my $item;
		if(ref $k) {
			$item = $self->parseCondition($k);
		} else {
			my ($start, $directive) = $k =~ /^(.)(.*)$/;
# If we have a directive such as and, or, etc. then we're switching mode
			if($start eq '-') {
				if($directive eq 'subquery') {
					$item = $self->parseQuery(shift(@list));
				} else {
					push @node, $directive;
					next ITEM;
				}
			} else {
				$k = $self->quoteIdentifier($k) unless ref $k;
				my $v = shift(@list);
				if(!ref($v)) {
					$item = [ $k, $v ];
				} elsif(ref($v) ~~ [qw{HASH SCALAR}]) {
					$item = [ $k, $v ];
				} else {
					$v = $self->parseCondition($v);
					$item = [ $k, $v ];
				}
			}
		}
		if(@node) {
			my $prev = pop(@tree);
			die 'no previous item?' unless $prev;

			my $entry = {
				op => join(' ', @node),
				left => $prev,
				right => $item
			};
			$item = $entry;
			@node = ();
		}
		push @tree, $item;
	}
	return $tree[0] if @tree == 1 && ref $tree[0];
	return \@tree;
}

=head2 parseBranch

For a hashref, the following three items should be in the hash:

=over 4

=item * left - left node of the branch, this will be recursed into as appropriate

=item * right - right node of the branch, will be recursed as required

=item * op - the operation to perform, such as =, and, or, etc.

=back

An arrayref will use the '=' operation for all entries unless the second element is
a hashref, in which case the key will be used as the operation and the value as the
RHS.

=cut

sub parseBranch {
	my $self = shift;
	my $item = shift;
	my @query;
	if(ref $item ~~ 'HASH') {
		push @query, '(';
		push @query, $self->parseBranch($item->{left});
		push @query, ' ' . $item->{op} . ' ';
		push @query, $self->parseBranch($item->{right});
		push @query, ')';
	} elsif(ref $item ~~ 'ARRAY') {
		my ($k, $v) = @$item;
		push @query, $k;
		my $op = '=';
		if(ref $v eq 'HASH') {
			($op, $v) = %$v;
		}
		push @query, " $op ";
		push @query, \$v;
	} elsif(ref $item) {
		push @query, $item;
	} else {
		push @query, $item;
	}
	return @query;
}

=head2 parseQuery

=cut

sub parseQuery {
	my $self = shift;
	' Query ';
}

=head2 quoteIdentifier

Convert an identifier to the quoted version.

=cut

sub quoteIdentifier {
	my $self = shift;
	my $k = shift;
	return $k;
	return '"'. $k . '"';
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
