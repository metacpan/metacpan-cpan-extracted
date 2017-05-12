package MySchema::User;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table("user");

__PACKAGE__->add_columns(
    id     => { data_type => "INTEGER", is_nullable => 0 },
    master => { data_type => "INTEGER", is_nullable => 1 },
    name   => { data_type => "TEXT", is_nullable => 0 },
    title  => { data_type => "TEXT", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( master => 'MySchema::Master', 'id' );

__PACKAGE__->has_many( addresses => 'MySchema::Address', 'user' );

__PACKAGE__->has_many( user_bands => 'MySchema::UserBand', 'user' );

__PACKAGE__->has_many( hasmanys => 'MySchema::HasMany', 'user' );

__PACKAGE__->many_to_many( bands => 'user_bands', 'band' );

__PACKAGE__->resultset_class('MySchemaRS::User');

sub fullname {
    my $self = shift;

    if (@_) {
        my $fullname = shift;

        my $match = qr/
            (?: ( \w+ ) \s+ )?
            ( .* )
            /x;

        my ($title, $name) = $fullname =~ $match;

        $self->set_column( 'title', $title );
        $self->set_column( 'name', $name );

        return $fullname;
    }

    my $title = $self->get_column('title');
    my $name  = $self->get_column('name');

    return join ' ', grep {defined} $title, $name;
}

sub foo {
    my ($self) = @_;

    my $row = $self->find_or_new_related( 'hasmanys', { key => 'foo' } );

    if ( @_ > 1 ) {
        $row->update(@_);
    }

    return $row;
}

1;

