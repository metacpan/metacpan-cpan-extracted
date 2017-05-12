#!/usr/bin/perl

package KiokuDB::Backend::BDB::Manager;
use Moose;

use Path::Class;

use Moose::Util::TypeConstraints;

use namespace::clean -except => 'meta';

extends "BerkeleyDB::Manager";

has '+home' => ( required => 1 );

sub BUILD {
    my $self = shift;

    my $home = dir($self->home);

    # backwards compat
    # this used to be the default, but makes using db_hotbackup hard
    if ( -d $home->subdir("data") ) {
        $self->meta->find_attribute_by_name("data_dir")->set_value($self, "data");
    }

    if ( -d $home->subdir("logs") ) {
        $self->meta->find_attribute_by_name("log_dir")->set_value($self, "logs");
    }
}

coerce( __PACKAGE__,
    from HashRef => via { __PACKAGE__->new(%$_) },
    from Str     => via { __PACKAGE__->new( home => $_ ) },
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuDB::Backend::BDB::Manager - 

=head1 SYNOPSIS

	use KiokuDB::Backend::BDB::Manager;

=head1 DESCRIPTION

=cut


