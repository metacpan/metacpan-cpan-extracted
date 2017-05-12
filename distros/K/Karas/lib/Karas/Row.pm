package Karas::Row;
use strict;
use warnings;
use utf8;
use Carp ();

sub new {
    my ($class, $values) = @_;
    bless {
        __private_dirty_column => +{},
        %$values,
    }, $class;
}

# Abstract methods.
sub table_name   { Carp::croak("Abstract method"); }
sub primary_key  { Carp::croak("Abstract method"); }
sub column_names { Carp::croak("Abstract method"); }
sub has_column   {
    my ($self, $column) = @_;
    return (grep { $_ eq $column } $self->column_names) > 0;
}

sub get_dirty_columns { $_[0]->{__private_dirty_column} }

sub mk_column_accessors {
    my ($class, @cols) = @_;
    Carp::croak("mk_column_accessors is class method.") if ref $class;

    for my $col (@cols) {
        Carp::croak("Column is undefined") unless defined $col;
        Carp::croak("Invalid column name: $col") if $col =~ /^__private/;
        no strict 'refs';
        *{"${class}::${col}"} = sub {
            if (@_==1) {
                # my ($self) = @_;
                Carp::croak("You don't selected $col in SQL.") unless exists $_[0]->{$col};
                return $_[0]->{$col};
            } elsif (@_==2) {
                # my ($self, $val) = @_;
                Carp::croak("You can't set non scalar value as column data: $col") if ref $_[1];
                $_[0]->{$col} = ($_[0]->{__private_dirty_column}->{$col} = $_[1]);
            } else {
                Carp::croak("Too many arguments for ${class}::${col}");
            }
        };
    }
}

sub make_where_condition {
    my $self = shift;
    unless ($self->primary_key()) {
        Carp::croak("You can't get WHERE clause for @{[ $self->table_name ]}. There is no primary key settings.");
    }
    my %cond;
    for my $key ($self->primary_key) {
        $cond{$key} = $self->get_column($key);
    }
    return \%cond;
}

sub get_column {
    my ($self, $col) = @_;
    Carp::croak("Usage: Karas::Row#get_column(\$col)") unless @_==2;
    Carp::croak("Column is undefined") unless defined $col;
    Carp::croak("You don't selected $col") unless exists $self->{$col};
    Carp::croak("Invalid column name: $col") if $col =~ /^__private/;
    return $self->{$col};
}

sub set_column {
    my ($self, $col, $val) = @_;
    Carp::croak("Usage: Karas::Row#set_column(\$col, \$val)") unless @_==3;
    Carp::croak("You can't set non scalar value as column data: $col") if ref $val;
    $self->{__private_dirty_column}->{$col} = $val;
}

sub DESTROY { }

1;
__END__

=head1 NAME

Karas::Row - row class for Karas

=head1 SYNOPSIS

    # Here is a synopsis. But you don't need to write this class by your hand.
    # Karas::Dumper can generate this class by your RDBMS schema, automatically.
    package My::Row::Member;
    use parent qw/Karas::Row/;

    sub table_name { 'member' }
    sub primary_key { qw/id/ }
    sub column_names { qw/id name email/ }

    __PACKAGE__->mk_column_accessors(column_names());

    1;

=head1 DESCRIPTION

This is Row class for Karas.

=head1 METHODS

=over 4

=item my @pk = $row->primary_key()

This method returns list of strings. It's primary keys.

Default method returns 'id'. You can override this method to use another primary key.

=item my $table_name = $row->table_name()

Returns table name. It's set at constructor.

=item my $val = $row->get_column($column_name)

Get a column value from row object. This method throws exception if column is not selected by SQL.

=item $row->set_column($column_name, $value:Str)

Set a column value for row object.

You can't set ScalarRef. If you want to use C<< $row->set_column('cnt' => \'cnt+1') >> form, you should use C<< $db->update($row, { cnt => \'cnt+1'}) >> instead.

=item __PACKAGE__->mk_column_accessors(@column_names)

Create column accessor methods by @column_names.

=back
