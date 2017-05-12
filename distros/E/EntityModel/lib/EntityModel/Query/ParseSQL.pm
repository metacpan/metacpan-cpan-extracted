package EntityModel::Query::ParseSQL;
{
  $EntityModel::Query::ParseSQL::VERSION = '0.102';
}
use strict;
use warnings FATAL => 'all';
use parent qw(Parser::MGC);

use constant DEBUG => 0;

use constant KEYWORDS => qw(
	select
	insert
	update
	truncate
	delete
	from
	where
	group
	by
	limit
	not
	in
	like
	order
	having
	create
	table
	drop
);

=head1 NAME

EntityModel::Query::ParseSQL

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use strict; use warnings;
 use EntityModel::Query::ParseSQL;
 my $parser = EntityModel::Query::ParseSQL->new;
 print Dumper($parser->from_string('select id from tbl x inner join tbl y on x.idx = y.idx where x.idx < 14'));

=head1 METHODS

=cut

sub where_am_i { return unless DEBUG; my $self = shift;
	my $note = shift || (caller(1))[3];
	my ( $lineno, $col, $text ) = $self->where;
	my $len = length($text);
	my $target_pos = $col;
	$target_pos++ while $target_pos < length($text) && substr($text, $target_pos, 1) =~ /^\s/;
	$target_pos++;
	substr $text, ($target_pos >= length($text) ? length($text) : $target_pos), 0, "\033[01;00m";
	substr $text, $col, 0, "\033[01;32m";
	printf("%-80.80s %d,%d %d %s\n", $text, $col, $lineno, $len, $note);
}

sub parse {
	my $self = shift;

	$self->list_of(';', sub { $self->parse_statement });
}

sub parse_select {
	my $self = shift;
	$self->where_am_i;
	$self->token_kw('select');
}

sub token_lvalue {
	my $self = shift;
	$self->where_am_i;
	$self->any_of(
		sub {
			join '', @{ $self->maybe(sub { [$self->token_ident, $self->expect('.')] }) || [] }, $self->token_ident;
		},
		sub { $self->token_int },
		sub { $self->token_float },
		sub { $self->token_string },
	);
}

sub token_rvalue {
	my $self = shift;
	$self->where_am_i;
	$self->any_of(
		sub {
			join '', @{ $self->maybe(sub { [$self->token_ident, $self->expect('.')] }) || [] }, $self->token_ident;
		},
		sub { $self->token_int },
		sub { $self->token_float },
		sub { $self->token_string },
	);
}


sub token_operator {
	my $self = shift;
	$self->where_am_i;
	$self->any_of(
		sub { $self->expect('=') },
		sub { $self->expect('!=') },
		sub { $self->expect('<=') },
		sub { $self->expect('>=') },
		sub { $self->expect('<') },
		sub { $self->expect('>') },
		sub { $self->expect('<>') },
		sub { $self->expect('is') },
		sub { $self->expect('in') },
		sub { $self->expect('like') },
	);
}

my $ANY_KEYWORD_RE = qr(@{[ join '|', KEYWORDS ]});

sub check_keyword {
	my $self = shift;
	$self->where_am_i;
	$self->skip_ws;
	if($self->{str} =~ m/\G($ANY_KEYWORD_RE)/gc) {
		$self->fail( "Had keyword $1" );
		return 1;
	}
	return 0;
}

sub token_alias {
	my $self = shift;
	$self->where_am_i;
	return if $self->check_keyword;
	$self->token_ident;
}

sub parse_join {
	my $self = shift;
	$self->where_am_i;
	$self->sequence_of(sub {
		$self->skip_ws;
		$self->where_am_i('join seq');
		[
		@{ $self->maybe(sub {
			$self->where_am_i('find join kw');
			$self->any_of(
				sub { [ $self->expect('full'), $self->expect('outer') ] },
				sub { [ $self->token_kw(qw(inner left right full cross hash)) ] },
				sub { [ $self->expect('left'), $self->expect('outer') ] },
				sub { [ $self->expect('right'), $self->expect('outer') ] },
			)
		}) || [] },
		$self->expect('join'),
		@{ $self->parse_table_or_query || [] },
		@{ $self->maybe(sub {
			[ $self->expect('on'),
			$self->any_of(
				sub {
					$self->where_am_i;
					[
						$self->token_lvalue,
						$self->token_operator,
						$self->token_rvalue
					]
				},
				sub {
					$self->where_am_i;
					[
						$self->token_rvalue
					]
				}
			) ]
		}) || [] } ]
	});
}

sub parse_statement {
	my $self = shift;
	$self->where_am_i;

	return [
	# Query type
		$self->any_of(
			sub { $self->parse_select }
		),
		$self->parse_fields,
		@{ $self->maybe(sub {
			$self->parse_from;
		}) || []},
		@{ $self->maybe(sub {
			$self->parse_join;
		}) || []},
		@{ $self->maybe(sub {
			$self->parse_where;
		}) || []},
	];
}

sub token_keyword {
	my $self = shift;
	$self->any_of(map { my $k = $_; sub { $self->expect($k) } } KEYWORDS);
}

sub parse_from {
	my $self = shift;
	$self->where_am_i;
	return [
		$self->expect('from'),
		@{ $self->parse_table_or_query || [] },
	];
}

sub parse_table_or_query {
	my $self = shift;
	[
		$self->any_of(
			@{ $self->maybe(sub { [$self->token_ident, $self->expect('.')] }) || [] },
			sub { $self->token_ident },
		),
		@{ $self->maybe(sub { [$self->expect('as')] }) || [] },
		@{ $self->maybe(sub { [$self->token_alias ] }) || [] },
	];
}

sub parse_where {
	my $self = shift;
	$self->where_am_i;
	[$self->expect('where'), $self->sequence_of(
		sub {
			$self->any_of(
				sub {
					[
						$self->token_lvalue,
						$self->token_operator,
						$self->token_rvalue
					]
				},
				sub {
					[
						$self->token_rvalue
					]
				}
			);
		}
	)];
}

sub parse_fields {
	my $self = shift;
	$self->where_am_i;

	# Fields
	$self->list_of(',', sub { $self->any_of(
		sub { $self->where_am_i('int field'); $self->token_int },
		sub { $self->where_am_i('ident field'); $self->token_ident },
		sub { $self->where_am_i('string field'); $self->token_string },
		sub { $self->where_am_i('nested fields'); $self->scope_of( "(", \&parse, ")" ) }
	)});
}

1;

__END__

=head1 SEE ALSO

L<SQL::Translator>, L<SQL::Abstract>

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
