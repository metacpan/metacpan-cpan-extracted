package t::Utils;
use strict;
use warnings;
use utf8;

use Test::More 0.96;
use File::Spec;
use File::Basename;
use Class::Load;

BEGIN {
    Class::Load::try_load_class('DBD::SQLite')
        or plan skip_all => 'needs DBD::SQLite for testing'
}

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

sub setup_dbh {
    my ($self, $file) = @_;
    DBI->connect('dbi:SQLite:'. $self->get_data_file_path($file),'','',{RaiseError => 1, PrintError => 0, AutoCommit => 1})
        or die DBI->errstr;
}

sub get_data_file_path {
    my ($self, $file) = @_;
    return File::Spec->catfile(dirname(__FILE__), 'data', $file);
}

sub get_test_data {
    my ($self, $file) = @_;
    return do $self->get_data_file_path($file);
}

sub base_test {
    my ($self, $dt, $test_file) = @_;
    my $data = $self->get_test_data($test_file);
    $dt->param($data->{param});
    my $methods = $data->{methods};
    foreach my $m (sort keys %$methods) {
        my $v = $methods->{$m};
        is_deeply($dt->$m(@{$v->{args}}), $v->{res}, '$dt->'.$m) or diag explain $dt->$m;
    }
}

1;
