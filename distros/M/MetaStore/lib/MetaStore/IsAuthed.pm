package MetaStore::IsAuthed;

=head1 NAME

MetaStore::IsAuthed - WebDAO component for check current user.

=head1 SYNOPSIS

    ...
    <regclass class="MetaStore::IsAuthed" alias="isauth"/>
    <object class="isauth" id="auth_switch1">
    <auth>
        <object class="man" id="manager">1</object>
    </auth>
    <noauth>
       <object class="main" id="page"/>

    </noauth>
    ...

=head1 DESCRIPTION

WebDAO component for check current user.

=head1 METHODS

=cut

use Data::Dumper;
use strict;
use warnings;
use base qw(WebDAO::Element);
__PACKAGE__->attributes( qw/ __init /);
our $VERSION = '0.1';

sub init {
    my $self = shift;
    my %arg  = @_;
    $self->__init( \%arg );
}

sub __get_self_refs {
    my $self = shift;

    #get user
    my %args = %{ $self->__init };
    return $self->_root_->_auth->is_authed ? $args{auth} : $args{noauth};
}


1;
__END__

=head1 SEE ALSO

MetaStore, WebDAO::Element, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

