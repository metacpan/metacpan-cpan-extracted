package EntityModel::Query::Base;
{
  $EntityModel::Query::Base::VERSION = '0.102';
}
use EntityModel::Class;
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Query::Base - base class for L<EntityModel::Query>-derived components

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

my %ParseHandler;

=head2 register

Register a parse handler for the given key(s).

Called from subclass ->import methods to hook into the configuration parser:

 EntityModel::Query->new(
 	x => [ ],
	y => [ ]
 )

will call the registered parse_x and parse_y methods to handle the two directives, unless those methods are already available on the class.

=cut

sub register {
	my $class = shift;
	my %args = @_;
	foreach my $k (keys %args) {
		die "Parse handler for $k already handled by " . $ParseHandler{$k}->{class} if exists $ParseHandler{$k};
		$ParseHandler{$k} = {
			class	=> $class,
			parser	=> $args{$k}
		};
	}
}

=head2 can_parse

If this class supports the parse_X method, or the given configuration key was registered by
one of the subclasses, returns the appropriate parse handler.

Returns undef if no handler was available.

=cut

sub can_parse {
	my $self = shift;
	my $k = shift;
	# TODO should probably drop the 'exists', don't think it's needed
	return $self->can("parse_$k") || (exists($ParseHandler{$k}) ? $ParseHandler{$k}->{parser} : undef);
}

=head2 inlineSQL


=cut

sub inlineSQL {
	my $self = shift;
	my $class = ref($self) || $self;
	die "Virtual ->inlineSQL method from EntityModel::Query::Base called on $class.";
}

=head2 normaliseInlineSQL

Merge adjacent plaintext sections in an inline SQL expression.

This would for example convert the following:

 'select', ' ', Entity::Field, ' ', 'from', ' ', Entity::Table

into:

 'select ', Entity::Field, ' from ', Entity::Table

=cut

sub normaliseInlineSQL {
	my $self = shift;
	my @sql = @_;
	my @text;

	my @out;
	while(@sql) {
		my $next = shift(@sql);
		if(defined($next) && !ref($next)) {
			push @text, $next;
		} else {
			push @out, join('', @text) if @text;
			push @out, $next;
			@text = ();
		}
	}
	push @out, join('', @text) if @text;
	return \@out;
}

=head2 decantValue

Extract a value.

=cut

sub decantValue {
	my $self = shift;
	my $in = shift;
	my $out;
	my $type = ref $in;
	given($type) {
		when('SCALAR') {
			$out = $$in;
			if(defined($out) && $out ~~ /^-?\d+(?:\.\d+)?$/) {
				$out = $out+0;
			}
		}
		default { $out = 'unknown'; }
	}
	return $out;
}

=head2 decantQuotedValue

Extract a quoted value suitable for use in direct SQL strings.

The plain-string form of SQL query is only intended for debugging and tracing; regular queries should always use the prepared statement form
provided by L<sqlAndParameters>.

=cut

sub decantQuotedValue {
	my $self = shift;
	my $in = shift;
	my $out;
	my $type = ref $in;
	given($type) {
		when('SCALAR') {
			$out = $$in;
			if(!defined($out)) {
				$out = 'NULL';
			} elsif($out =~ /^-?\d+(?:\.\d+)?$/) {
				$out = $out+0;
			} else {
				$out =~ s/'/''/g;
				$out = "'$out'";
			}
		}
		default { $out = 'unknown'; }
	}
	return $out;
}

=head2 sqlString

=cut

sub sqlString {
	my $self = shift;
	my @query = @{ $self->inlineSQL };

	my $sql = '';
	foreach my $part (@query) {
		my $type = ref $part;
		if($type) {
			$sql .= $self->decantQuotedValue($part);
		} else {
			$sql .= $part;
		}
	}
	return $sql;
}

=head2 sqlAndParameters

=cut

sub sqlAndParameters {
	my $self = shift;
	my @query = @{ $self->inlineSQL };

	my $sql = '';
	my @bind;
	my $id = 1;
	foreach my $part (@query) {
		my $type = ref $part;
		if($type) {
			push @bind, $self->decantValue($part);
			$sql .= '$'. $id++;
		} else {
			$sql .= $part;
		}
	}
	return wantarray ? ($sql, @bind) : $sql;
}

=head2 asString

=cut

sub asString { shift->sqlString }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
