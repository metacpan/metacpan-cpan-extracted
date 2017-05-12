package Deeme::Backend;
use Deeme::Obj -base;
use Carp 'croak';

has 'deeme';

sub events_get {
    croak 'Method "events_get" not implemented by subclass';
}    #get events

sub events_reset {
    croak 'Method "events_reset" not implemented by subclass';
}    #reset events

sub events_onces {
    croak 'Method "events_onces" not implemented by subclass';
}    #onces of events

sub once_update {
    croak 'Method "once_update" not implemented by subclass';
} #once updates

sub event_add {
    croak 'Method "event_add" not implemented by subclass';
}    #add events

sub event_delete {
    croak 'Method "event_delete" not implemented by subclass';
}    #delete event

sub event_update {
    croak 'Method "event_update" not implemented by subclass';
}    #update event

1;

__END__
=encoding utf-8

=head1 NAME

Deeme::Backend - Database backend base class for Deeme

=head1 SYNOPSIS

  use Deeme::Obj "Deeme::Backend";

=head1 DESCRIPTION

Deeme::Backend is the base class used by the implemented backends

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
