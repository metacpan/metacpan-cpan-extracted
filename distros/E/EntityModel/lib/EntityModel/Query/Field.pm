package EntityModel::Query::Field;
{
  $EntityModel::Query::Field::VERSION = '0.102';
}
use EntityModel::Class {
	'_isa' => [qw(EntityModel::Query::Base)],
	'field' => 'EntityModel::Field',
	'name' => 'string',
	'sql' => 'string',
	'alias' => 'string',
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Query::Field - field wrapper

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	if(ref $_[0] eq 'HASH') {
		my $spec = shift;
		my ($k, $v) = %$spec;
		$self->alias($k);
		if(ref $v) {
			$self->sql($$v);
		} else {
			$self->name($v);
		}

#		foreach (qw{name field value alias}) {
#			$self->$_($spec->{$_}) if exists $spec->{$_};
#		}
	} elsif(ref($_[0]) && $_[0]->isa('EntityModel::Field')) {
		my $spec = shift;
		$self->field($spec);
# Handle plain value
	} elsif(@_ == 1 && !ref $_[0]) {
		my $v = shift;
		$self->name($v);
	}

	return $self;
}

=head2 quotedValue

=cut

sub quotedValue {
	my $self = shift;
	my $v = $self->value;
	return 'null' unless defined $v && $v ne 'undef';
	return $v if $self->field && $self->field->type ~~ [qw/int bigint serial bigserial numeric/];
	$v =~ s/'/''/g;
	$v =~ s!\\!\\\\!g;
	return "E'$v'";
}

=head2 asString

=cut

sub asString {
	my $self = shift;
	my $alias;
	return $self->sql if exists $self->{sql};
	return $self->name if exists $self->{name};
	return $self->field->name;
	$alias = $self->table->name if $self->table;
	return ($alias ? ($alias . '.') : '') . $self->name;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
