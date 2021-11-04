package FindApp::Object::State::Group::Class;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Vars  qw(:all);
use FindApp::Utils qw(:all);

sibuse "State::Dirs";

#################################################################

sub dir_field   (  _  ) ;
sub dir_fields  (     ) ;
sub dir_types   (     ) ;
sub field_map   ( & @ ) ;
sub type_map    ( & @ ) ;

#################################################################

sub dir_types() {
    return qw(allowed wanted found);
}

sub dir_field(_) {
    my($type) = @_;
    no strict "refs";
    return sibpackage("State::\U$type")->();
}

sub type_map(&@) {
    my $code = shift;
    return map { &$code } +dir_types, @_;
}

sub dir_fields() {
    my $fields = [ type_map{dir_field} ];
    return @$fields;
}

sub field_map(&@) {
    my $code = shift;
    return map { &$code } +dir_fields, @_;
}

use namespace::clean;

sub class { &ENTER_TRACE_2;
    my($self) = @_;
    return blessed($self) || $self;
}

sub object { &ENTER_TRACE_2;
    my($self) = @_;
    croak "not an object" unless blessed $self;
    return $self;
}

sub new { &ENTER_TRACE_2;
    good_args(@_ >= 2);
    my($invocant, $name) = (shift, shift);
    my $class = blessed($invocant) || $invocant;
    my %dirlists = field_map { $_ => sibpackage("State::Dirs")->new };
    return bless(\%dirlists, $class)->params(
        name       => [$name],
        unexported => [1],
        @_,
    );
}

sub copy { &ENTER_TRACE_2;
    good_args(@_ == 2);
    my($new, $old) = @_;
    my $name = $old->name;
    $new->name eq $old->name || panic "name mismatch";
    $new->exported($old->exported);
    for my $field (dir_types()) {
        $new->$field->copy($old->$field->object);
    }
}

sub params { &ENTER_TRACE_2;
    my($self, %inits) = @_;
    while (my($method, $aref) = each %inits) {
        $self->$method(@$aref);
    }
    return $self;
}

1;

=encoding utf8

=head1 NAME

FindApp::Object::State::Group::Object::Class - FIXME

=head1 SYNOPSIS

 use FindApp::Object::State::Group::Object::Class;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item class

=item copy

=item new

=item object

=item params

=back

=head2 Exports

=over

=item FIXME

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

