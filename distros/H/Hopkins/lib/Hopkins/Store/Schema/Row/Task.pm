package Hopkins::Store::Schema::Row::Task;

use strict;

=head1 NAME

Hopkins::Schema::Row::Task - ORM relational class defining a point-in-time execution

=head1 DESCRIPTION

=cut

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('tasks');
__PACKAGE__->add_columns(
	id => {
		data_type			=> 'char',
		size				=> 36,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	name => {
		data_type			=> 'varchar',
		size				=> 255,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	queue => {
		data_type			=> 'varchar',
		size				=> 255,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	started => {
		data_type			=> 'tinyint',
		size				=> 1,
		is_nullable			=> 0,
		default_value		=> 0,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	completed => {
		data_type			=> 'tinyint',
		size				=> 1,
		is_nullable			=> 0,
		default_value		=> 0,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	succeeded => {
		data_type			=> 'tinyint',
		size				=> 1,
		is_nullable			=> 0,
		default_value		=> 0,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	failed => {
		data_type			=> 'tinyint',
		size				=> 1,
		is_nullable			=> 0,
		default_value		=> 0,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	aborted => {
		data_type			=> 'tinyint',
		size				=> 1,
		is_nullable			=> 0,
		default_value		=> 0,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	date_enqueued => {
		data_type			=> 'datetime',
		size				=> 0,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	date_to_execute => {
		data_type			=> 'datetime',
		size				=> 0,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	date_started => {
		data_type			=> 'datetime',
		size				=> 0,
		is_nullable			=> 1,
		default_value		=> 'NULL',
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	},
	date_completed => {
		data_type			=> 'datetime',
		size				=> 0,
		is_nullable			=> 1,
		default_value		=> 'NULL',
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	}
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_relationship('output', 'Hopkins::Store::Schema::Row::TaskOutput',
	{ 'foreign.task'	=> 'self.id'	},
	{ 'accessor'		=> 'single'		}
);

__PACKAGE__->inflate_column('date_enqueued', {
    inflate => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
    deflate => sub { shift->iso8601 }
});
__PACKAGE__->inflate_column('date_to_execute', {
    inflate => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
    deflate => sub { shift->iso8601 }
});
__PACKAGE__->inflate_column('date_started', {
    inflate => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
    deflate => sub { shift->iso8601 }
});
__PACKAGE__->inflate_column('date_completed', {
    inflate => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
    deflate => sub { shift->iso8601 }
});

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=cut

1;
