package FindApp::Object::State::Group::State;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Vars  qw(:all);
use FindApp::Utils qw(:all);

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
    return &{uc $type};
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

################################################################

use pluskeys qw{
    NAME
    EXPORTED
} => type_map{uc};

sub unexported {
    bad_args(!@_ || @_ > 2);
    my($self, $value) = @_;
    if ($value) {
        $$self{+EXPORTED} = 0;
    }
    return !$$self{+EXPORTED};
}

sub have_exported {
    good_args(@_ == 1);
    my $self = shift;
    return $$self{+EXPORTED};
}

sub bump_exports {
    good_args(@_ == 1);
    my $self = shift;
    return ++$$self{+EXPORTED};
}

sub exported {
    bad_args(@_ > 2);
    my $self = shift;
    use warnings FATAL => qw(numeric uninitialized);
    $$self{+EXPORTED} += shift if @_;
    $$self{+EXPORTED};
}

sub name {
    bad_args(@_ > 2);
    my $self = shift;
    return $$self{+NAME} unless @_;
    my $old_name = $$self{+NAME};
    my $new_name = shift;
    for ($new_name) {
        defined    || die "name cannot be undef";
        length     || die "name cannot be zero length";
        !ref       || die "name cannot be a reference";
        !/\0/      || die "name cannot contain NUL characters";
    }
    $$self{+NAME} = $new_name;
    return $old_name;
}

sub access_AWF_subdir {
    my($self, $dirs, @values) = @_;
    $dirs->set(@values) if @values;
    if    (wantarray)           { return $dirs->get }
    elsif (defined wantarray)   { return $dirs      }
    else                        { return            }
}

BEGIN {
    my %ACCESSOR = type_map { $_ => dir_field };
    # BUILD: allowed, wanted, found
    while (my($TYPE, $FIELD) = each %ACCESSOR) {
        function $TYPE => sub { &ENTER_TRACE_2;
            my $self = shift;
            $self->access_AWF_subdir($$self{$FIELD}, @_);
        };
    }
}

1;

=encoding utf8

=head1 NAME

FindApp::Object::State::Group::Object::State - FIXME

=head1 SYNOPSIS

 use FindApp::Object::State::Group::Object::State;

=head1 DESCRIPTION

=head2 Pluskey Attributes

These are always private; use the methods insteads.

=over

=item ALLOWED 

=item EXPORTED

=item FOUND

=item NAME

=item WANTED 

=back

=head2 Public Methods

=over

=item ALLOWED

=item FOUND

=item WANTED

=item access_AWF_subdir

=item allowed

=item bump_exports

=item exported

=item found

=item have_exported

=item name

=item unexported

=item wanted

=item FIXME

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

