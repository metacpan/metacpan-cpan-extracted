=head1 NAME

GOBO::Identified

=head1 SYNOPSIS

=head1 DESCRIPTION

A role for any kind of entity that is identifiable. Provides standard
metadata and paper-trail methods. Based on GOBO-Format

=head2 TBD

Is this over-abstraction? This could be simply mixed in with Node

=cut

package GOBO::Identified;
use Moose::Role;

has id => (is => 'rw', isa => 'Str');
has namespace => (is => 'rw', isa => 'Str');
has obsolete => (is => 'rw', isa=> 'Bool');
has anonymous => (is => 'rw', isa=> 'Bool');
has deprecated => (is => 'rw', isa=> 'Bool');
has replaced_by => (is => 'rw', isa=>'ArrayRef[GOBO::Node]');
has consider => (is => 'rw', isa=>'ArrayRef[GOBO::Node]');

=head2 status

returns oneof: obsolete deprecated ok

=cut

sub status {
    my $self = shift;
    return 'obsolete' if $self->obsolete;
    return 'deprecated' if $self->deprecated;
    return 'ok';
}

sub is_identified {
    return defined shift->id;
}

sub id_db {
    (shift->get_db_local_id())[0];
}

sub local_id {
    (shift->get_db_local_id())[1];
}

sub get_db_local_id {
    my $id = shift->id;
    if ($id =~ /([\w\-]+):(.*)/) {
        return ($1,$2);
    }
    return ('_',$id);
}

sub equals {
    my $self = shift;
    return $self->id eq shift->id;
}

sub add_considers {
    my $self = shift;
    $self->consider([]) unless $self->consider;
    foreach (@_) {
        push(@{$self->consider},ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_);
    }
    return;
}

sub add_replaced_bys {
    my $self = shift;
    $self->replaced_by([]) unless $self->replaced_by;
    foreach (@_) {
        push(@{$self->replaced_by},ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_);
    }
    return;
}

1;

