package JQuery::DataTables::Heavy;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.04";

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Carp;
use Class::Load ();
use namespace::clean;


has subclass => ( is => 'lazy', isa => ConsumerOf [ __PACKAGE__ . '::Base' ] );
has args => ( is => 'ro', isa => HashRef, required => 1 );

around BUILDARGS => sub {
    my $orig      = shift;
    my $class     = shift;
    my $orig_args = $class->$orig(@_);
    my $args      = { args => $orig_args };
    $args->{subclass} = $args->{subclass} if $args->{subclass};
    return $args;
};

sub _build_subclass {
    my ($self) = @_;
    my $subclass = dispatch_subclass( $self->args->{dbh} );
    Class::Load::load_class($subclass);
    return $subclass->new( $self->args );
}

sub dispatch_subclass {
    my ($obj) = @_;
    my $subclass = __PACKAGE__;
    if ( $obj->isa('DBI::db') ) {
        $subclass .= '::DBI';
    }
    elsif ( $obj->isa('DBIx::Class::Schema') ) {
        $subclass .= '::DBIC';
    }
    else {
        croak( sprintf( "Can't dispatch subclass from args: 'dbh': %s", ref $obj ) );
    }
    return $subclass;
}

sub table_data {
    my $self = shift;
    $self->subclass->table_data(@_);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

JQuery::DataTables::Heavy - It's new $module

=head1 SYNOPSIS

    use JQuery::DataTables::Heavy;

=head1 DESCRIPTION

JQuery::DataTables::Heavy is ...

=head1 LICENSE

Copyright (C) Yusuke Watase.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Watase E<lt>ywatase@gmail.comE<gt>

=cut

