package Hopkins::Store::Schema::Row::TaskOutput;

use strict;

=head1 NAME

Hopkins::Schema::Row::TaskOutput - storage for task output

=head1 DESCRIPTION

=cut

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('task_outputs');
__PACKAGE__->add_columns(
	id => {
		data_type			=> 'bigint',
		size				=> 20,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 1,
		is_foreign_key		=> 0
	},
	task => {
		data_type			=> 'char',
		size				=> 36,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 1
	},
	text => {
		data_type			=> 'text',
		size				=> 65535,
		is_nullable			=> 0,
		default_value		=> undef,
		is_auto_increment	=> 0,
		is_foreign_key		=> 0
	}
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_relationship('task', 'Hopkins::Store::Schema::Row::Task',
	{ 'foreign.id'	=> 'self.task'	},
	{ 'accessor'	=> 'single'		}
);

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=cut

1;
