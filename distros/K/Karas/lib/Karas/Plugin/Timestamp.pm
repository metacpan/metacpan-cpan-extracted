package Karas::Plugin::Timestamp;
use strict;
use warnings;
use utf8;

sub new {
    my $self = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $self;
}

sub init {
    my ($plugin, $db) = @_;
    Carp::croak("Do not use this plugin to instance") if ref $db;
    Carp::croak("Do not load this plugin to Karas itself. Please make your own child class from Karas.") if $db eq 'Karas';

    $db->add_trigger('BEFORE_INSERT' => sub {
        my ($db, $table_name, $values) = @_;
        if ($plugin->_has_created_on($db, $table_name)) {
            unless (exists $values->{created_on}) {
                $values->{'created_on'} = time();
            }
        }
        if ($plugin->_has_updated_on($db, $table_name)) {
            unless (exists $values->{updated_on}) {
                $values->{'updated_on'} = time();
            }
        }
    });
    $db->add_trigger('BEFORE_REPLACE' => sub {
        my ($db, $table_name, $values) = @_;
        if ($plugin->_has_created_on($db, $table_name)) {
            unless (exists $values->{created_on}) {
                $values->{'created_on'} = time();
            }
        }
        if ($plugin->_has_updated_on($db, $table_name)) {
            unless (exists $values->{updated_on}) {
                $values->{'updated_on'} = time();
            }
        }
    });
    $db->add_trigger('BEFORE_BULK_INSERT' => sub {
        my ($db, $table_name, $rows) = @_;
        my $time = time(); # put same time to all rows.
        if ($plugin->_has_created_on($db, $table_name)) {
            for my $row (@$rows) {
                unless (exists $row->{created_on}) {
                    $row->{created_on} = $time;
                }
            }
        }
        if ($plugin->_has_updated_on($db, $table_name)) {
            for my $row (@$rows) {
                unless (exists $row->{updated_on}) {
                    $row->{updated_on} = $time;
                }
            }
        }
    });
    $db->add_trigger('BEFORE_INSERT_ON_DUPLICATE' => sub {
        my ($db, $table_name, $insert_values, $update_values) = @_;
        if ($plugin->_has_created_on($db, $table_name)) {
            unless (exists $insert_values->{created_on}) {
                $insert_values->{'created_on'} = time();
            }
            unless (exists $insert_values->{updated_on}) {
                $insert_values->{'updated_on'} = time();
            }
        }
        if ($plugin->_has_updated_on($db, $table_name)) {
            unless (exists $update_values->{updated_on}) {
                $update_values->{'updated_on'} = time();
            }
        }
    });
    $db->add_trigger('BEFORE_UPDATE_ROW' => sub {
        my ($db, $row, $set) = @_;
        if ($plugin->_has_updated_on($db, $row->table_name)) {
            unless (exists $set->{updated_on}) {
                $set->{'updated_on'} = time();
            }
        }
    });
    $db->add_trigger('BEFORE_UPDATE_DIRECT' => sub {
        my ($db, $table_name, $set, $where) = @_;
        if ($plugin->_has_updated_on($db, $table_name)) {
            unless (exists $set->{updated_on}) {
                $set->{'updated_on'} = time();
            }
        }
    });
}

sub _has_created_on {
    my ($self, $db, $table_name) = @_;
    return $db->get_row_class($table_name)->has_column('created_on');
}

sub _has_updated_on {
    my ($self, $db, $table_name) = @_;
    return $db->get_row_class($table_name)->has_column('updated_on');
}

1;
__END__

=head1 NAME

Karas::Plugin::Timestamp - Timestamp plugin

=head1 DESCRIPTION

This is a timestamp plugin for Karas.

If your tables has created_on or updated_on columns.

=head1 AFTER MYSQL 5.6

MySQL 5.6 supports more flexible timestamp management.

You can use following style.

    CREATE TABLE t1 (
        created_on DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_on DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    );

See this URL for more details:
https://dev.mysql.com/doc/refman/5.6/en/timestamp-initialization.html
http://optimize-this.blogspot.co.uk/2012/04/datetime-default-now-finally-available.html

