package MySchema::Master;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/
    InflateColumn::DateTime Core
/);

__PACKAGE__->table("master");

__PACKAGE__->add_columns(
    id             => {
        data_type => "INTEGER",
        is_nullable => 0,
    },
    text_col       => { data_type => "TEXT", is_nullable => 1 },
    password_col   => { data_type => "TEXT", is_nullable => 1 },
    checkbox_col   => {
        data_type => "BOOLEAN",
        default_value => 1,
        is_nullable   => 0,
    },
    select_col     => { data_type => "TEXT", is_nullable => 1 },
    combobox_col   => { data_type => "TEXT", is_nullable => 1 },
    radio_col      => { data_type => "TEXT", is_nullable => 1 },
    radiogroup_col => { data_type => "TEXT", is_nullable => 1 },
    array_col      => { data_type => "TEXT", is_nullable => 1, is_array => 1 },
    date_col       => { data_type => "DATETIME", is_nullable => 1 },
    type_id        => { data_type => "INTEGER", is_nullable => 1 },
    type2_id       => { data_type => "INTEGER", is_nullable => 1 },
    enum_col       => { data_type => "ENUM", is_nullable => 1, extra => { list => [qw( a b c )] } },
    not_in_form    => { data_type => "TEXT", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->might_have( note => 'MySchema::Note', 'master' );

__PACKAGE__->has_one( user => 'MySchema::User', 'master' );

__PACKAGE__->has_many( schedules => 'MySchema::Schedule', 'master' );

__PACKAGE__->belongs_to(
    type => 'MySchema::Type',
    { 'foreign.id' => 'self.type_id' } );

__PACKAGE__->belongs_to(
    type2 => 'MySchema::Type2',
    { 'foreign.id' => 'self.type2_id' } );

__PACKAGE__->inflate_column('array_col', {	# {key=>val}
        inflate => __PACKAGE__->inflate_column_list_comma,
        deflate => __PACKAGE__->deflate_column_list_comma,
    });

sub method_test {
    my $self = shift;
    if (@_) {
        $self->text_col(@_);
    }

    return $self->text_col;
}

sub method_select_test {
    my $self = shift;
    if (@_) {
        $self->select_col(@_);
    }

    return $self->select_col;
}

sub method_checkbox_test {
    my $self = shift;
    if (@_) {
        $self->checkbox_col(@_);
    }
    return $self->checkbox_col;
}

sub inflate_column_list_comma {
  sub {
	[split(/,/,  shift )];
  }
}
sub deflate_column_list_comma {
  sub {
	join(',', @{(shift)} );
  }
}

1;

