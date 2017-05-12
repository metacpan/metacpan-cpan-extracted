package Foorum::Schema::ScheduledEmail;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('scheduled_email');
__PACKAGE__->add_columns(
    'email_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'email_type',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 24,
    },
    'processed',
    {   data_type     => 'ENUM',
        default_value => 'N',
        is_nullable   => 0,
        size          => 1
    },
    'from_email',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },
    'to_email',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },
    'subject',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    'plain_body',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    'html_body',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    'time',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 0,
        size          => 11,
    },
);
__PACKAGE__->set_primary_key('email_id');

__PACKAGE__->resultset_class('Foorum::ResultSet::ScheduledEmail');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::ScheduledEmail - Table 'scheduled_email'

=head1 COLUMNS

=over 4

=item email_id

INT(11)

NOT NULL, PRIMARY KEY

=item email_type

VARCHAR(24)



=item processed

ENUM(1)

NOT NULL, DEFAULT VALUE 'N'

=item from_email

VARCHAR(128)



=item to_email

VARCHAR(128)



=item subject

TEXT(65535)



=item plain_body

TEXT(65535)



=item html_body

TEXT(65535)



=item time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

