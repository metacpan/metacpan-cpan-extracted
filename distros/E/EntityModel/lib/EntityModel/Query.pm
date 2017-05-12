package EntityModel::Query;
{
  $EntityModel::Query::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Query::Base}],
	'forUpdate'	=> 'string',
	'limit'		=> 'int',
	'offset'	=> 'int',
	'field'		=> { type => 'array', subclass => 'EntityModel::Query::Field' },
	'from'		=> { type => 'array', subclass => 'EntityModel::Query::FromTable' },
	'join'		=> { type => 'array', subclass => 'EntityModel::Query::Join' },
	'where'		=> { type => 'EntityModel::Query::Condition' },
	'having'	=> { type => 'array', subclass => 'EntityModel::Query::Condition' },
	'group'		=> { type => 'array', subclass => 'EntityModel::Query::GroupField' },
	'order'		=> { type => 'array', subclass => 'EntityModel::Query::OrderField' },
	'returning'	=> { type => 'array', subclass => 'EntityModel::Query::ReturningField' },
	'db'		=> { type => 'EntityModel::DB', scope => 'private' },
	'transaction'	=> { type => 'EntityModel::Transaction', scope => 'private' },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Query - handle SQL queries

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use EntityModel::Query;

 # Provide a definition on instantiation:
 my $query = EntityModel::Query->new(
 	select	=> [qw(id name)]
	from	=> 'table',
	where	=> [ created => { '<' => '2010-01-01' } ],
	limit	=> 5
 );

 # or using chained methods:
 my $query = EntityModel::Query->new
 ->select( qw(id name) )
 ->from( 'table' )
 ->where(
 	created => { '<' => '2010-01-01' }
 )
 ->limit(5);

 # Extract query as SQL
 my ($sql, @bind) = $query->sqlAndParameters;
 my $sth = $dbh->prepare($sql);
 $sth->execute(@bind);

=head1 DESCRIPTION

Provides an abstraction layer for building SQL queries programmatically.

When generating the query, each of the components is called in turn to get an "inline SQL" arrayref. This is an arrayref consisting of
SQL string fragments interspersed with refs for items such as L<EntityModel::Entity> names, direct scalar values, or L<EntityModel::Field>
names.

As an example:

 [ 'select * from ', EntityModel::Entity->new('table'), ' where ', EntityModel::Field->new('something'), ' = ', \3 ]

This can then be used by L<sqlAndParameters> to generate:

 'select * from "table" where "something" = ?', 3

or as a plain SQL string (perhaps for diagnostic purposes) from L<sqlString> as:

 'select * from "table" where "something" = 3'

=cut

# Need both of these available and we may be running without EntityModel behind us
use EntityModel::Entity;
use EntityModel::Field;

# All the query subtypes
use EntityModel::Query::Select;
use EntityModel::Query::Update;
use EntityModel::Query::Insert;
use EntityModel::Query::Delete;

# Components
use EntityModel::Query::FromTable;
use EntityModel::Query::Field;
use EntityModel::Query::InsertField;
use EntityModel::Query::UpdateField;
use EntityModel::Query::OrderField;
use EntityModel::Query::Join;

# PostgreSQL extension
use EntityModel::Query::ReturningField;

# Multi-query pieces
use EntityModel::Query::Union;
use EntityModel::Query::UnionAll;
use EntityModel::Query::Intersect;
use EntityModel::Query::Except;

use Carp qw/confess/;

=head1 METHODS

=cut

=head2 new

Construct a new L<EntityModel::Query>. Most of the work is passed off to L<parse_spec>.

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	$self->parse_spec(@_) if @_;
	return $self;
}

=head2 type

Returns the type of the current query. The query object will be reblessed into an appropriate
subclass depending on whether this is an insert, select, delete etc. A query that has not been
reblessed is invalid.

=cut

sub type { confess "Virtual type - this is likely because you did not specify valid insert/select/delete criteria"; }

=head2 parse_spec

Parse the specification we were given.

=cut

sub parse_spec {
	my $self = shift;
	my @details = @_;
	SPEC:
	while(@details) {
		my $k = shift(@details);
		my $v = shift(@details);

		next SPEC if $k eq 'key';

		# Queries such as 'insert into' => 'insert_into'
		$k =~ s/\s+/_/g;

		# FIXME haxx
		if($k eq 'db') {
			$self->db($v);
		} elsif($k eq 'transaction') {
			$self->transaction($v);
		} elsif(my $handler = $self->can_parse($k)) {
			$handler->($self, $v);
		} else {
			die "Could not find method for $k";
		}
	}
	return $self;
}

=head2 parse_base

Base method for parsing.

=cut

sub parse_base {
	my $self = shift;
	my $spec = shift;
	my %arg = @_;

	my $meth = delete $arg{method};
	my $type = delete $arg{type};

	# Capital letter means a class of some sort. Arbitrary but at least it's simple.
	my $extType = ucfirst($type) eq $type;

	if(ref $spec ~~ 'ARRAY') {
		$self->$meth->push($extType ? $type->new($_) : $_) foreach @$spec;
	} elsif(ref $spec ~~ 'HASH') {
		# FIXME wrong if $extType is not set?
		$self->$meth->push($extType ? $type->new($spec) : $spec);
	} elsif(ref $spec) {
		$self->$meth->push($spec);
#		die "Don't know how to handle ref $spec for $meth";
	} else {
		$self->$meth->push($extType ? $type->new($spec) : $spec);
	}
	return $self;
}


=head2 reclassify

Virtual method to allow subclass to perform any required updates after reblessing to an alternative class.

=cut

sub reclassify { $_[0] }


=head2 upgradeTo

Upgrade an existing L<EntityModel::Query> object to a subclass.

=cut

sub upgradeTo {
	my $self = shift;
	my $class = shift;
	bless $self, $class;
	$self->reclassify;
}

=head2 parse_limit

Handle a 'limit' directive.

=cut

sub parse_limit {
	my $self = shift;
	my $v = shift;
	$self->limit($v);
	return $self;
}

=head2 parse_group

=cut

sub parse_group {
	my $self = shift;
	$self->parse_base(
		@_,
		method	=> 'group',
		type	=> 'EntityModel::Query::GroupField'
	);
}

=head2 parse_where

=cut

sub parse_where {
	my $self = shift;
	$self->where(EntityModel::Query::Condition->new(@_));
	return $self;
}

=head2 typeSQL

Proxy method for L<type>, returns the SQL string representation for the current query type (such as 'select' or 'insert into').

=cut

sub typeSQL { shift->type }

=head2 fieldsSQL

Generate the SQL for fields.

=cut

sub fieldsSQL {
	my $self = shift;
	my $fields = join(', ', map {
		$_->asString . ($_->alias ? (' as ' . $_->alias) : '');
	} $self->field->list);
	return unless $fields;
	return $fields;
}

=head2 fromSQL

SQL for the 'from' clause.

=cut

sub fromSQL {
	my $self = shift;
	my $from = join(', ', map { $_->asString } $self->from->list);
	return unless $from;
	logDebug("From " . $from);
	return 'from ' . $from;
}

=head2 limitSQL

=cut

sub limitSQL {
	my $self = shift;
	my $sql = (exists $self->{limit}) ? ('limit ' . $self->limit) : '';
	return unless $sql;
	return $sql;
}

=head2 offsetSQL

=cut

sub offsetSQL {
	my $self = shift;
	my $sql = (exists $self->{offset}) ? ('offset ' . $self->offset) : '';
	return unless $sql;
	return $sql;
}

=head2 orderSQL

=cut

sub orderSQL {
	my $self = shift;
	my $sql = join(', ', map { $_->asString } $self->order->list);
	return unless $sql;
	return 'order by ' . $sql;
}

=head2 groupSQL

=cut

sub groupSQL {
	my $self = shift;
	my $sql = join(', ', map { $_->asString } $self->group->list);
	return unless $sql;
	return 'group by ' . $sql;
}

=head2 havingSQL

=cut

sub havingSQL {
	my $self = shift;
	my $sql = join(', ', map { $_->expr } $self->having->list);
	return unless $sql;
	return $sql;
}

=head2 whereSQL

=cut

sub whereSQL {
	my $self = shift;
	return unless $self->where;
	return [ "where ", @{ $self->where->inlineSQL } ];
}

=head2 joinSQL

=cut

sub joinSQL {
	my $self = shift;
	my $join = join(' ', map { $_->asString } $self->join->list);
	return unless $join;
	return $join;
}

=head2 keyword_order { qw{type fields from join where having group order offset limit};

=cut

sub keyword_order { qw{type fields from join where having group order offset limit}; }

=head2 inlineSQL

=cut

sub inlineSQL {
	my $self = shift;
	my @sql;
	my @items = $self->keyword_order;
	ITEM:
	while(@items) {
		my $m = shift(@items) . 'SQL';
		my $entry = $self->$m;
		next ITEM unless defined $entry;
		push @sql, ' ' if @sql;
		if(ref $entry eq 'ARRAY') {
			push @sql, @$entry;
		} else {
			push @sql, $entry;
		}
	}
	push @sql, ' for update' if $self->forUpdate;
	return $self->normaliseInlineSQL(@sql);
}

=head2 results

=cut

sub results {
	my $self = shift;
	logDebug("Running [%s]", $self->sqlString);

	$self->db(EntityModel::DB->active_db) unless $self->db;
	die "No DB" unless $self->db;

	my ($sql, @bind) = $self->sqlAndParameters;
	my $sth;
	eval {
		$sth = $self->dbh->prepare($sql);
		$sth->execute(@bind);
	};
	if($@) {
		my $msg = $@;
		logError("Query [%s] failed: [%s]", $sql, $msg);
		return EntityModel::Error->new('SQL failed');
	}

	return EntityModel::Error->new('Invalid handle') unless $sth->{Active};

	my @rslt;
	while(my $row = $sth->fetchrow_hashref) {
		logDebug("Got " . join(',', map { $_ . ' => ' . ($row->{$_} // 'undef') } keys %$row));
		push @rslt, $row;
	}
	return @rslt;
}

=head2 iterate

Calls the given method for each result returned from the current query.

=cut

sub iterate {
	my $self = shift;
	my $code = shift;
	logDebug("Running [%s]", $self->sqlString);

	my ($sql, @bind) = $self->sqlAndParameters;

	my $sth;
	eval {
		$sth = $self->dbh->prepare($sql);
		$sth->execute(@bind);
	};
	if($@) {
		my $msg = $@;
		logError("Query [%s] failed: [%s]", $sql, $msg);
		return EntityModel::Error->new('SQL failed');
	}
	return unless $sth->{Active};

	while(my $row = $sth->fetchrow_hashref) {
		logDebug("Got " . join(',', map { $_ . ' => ' . ($row->{$_} // 'undef') } keys %$row));
		$code->($row);
	}
	return $self;
}

=head2 dbh

=cut

sub dbh {
	my $self = shift;
	$self->db(EntityModel::DB->active_db) unless $self->db;
	return $self->db->dbh;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<SQL::Translator>

=item * L<SQL::Abstract>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Licensed under the same terms as Perl itself.
