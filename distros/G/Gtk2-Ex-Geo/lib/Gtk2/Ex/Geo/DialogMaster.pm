## @class Gtk2::Ex::Geo::DialogMaster
# @brief A helper module for managing Glade XML dialogs
# @author Copyright (c) Ari Jolma
# @author This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.5 or,
# at your option, any later version of Perl 5 you may have available.

package Gtk2::Ex::Geo::DialogMaster;

use strict;
use warnings;
use Carp;

BEGIN {
    use Exporter 'import';
    our @EXPORT = qw();
    our @EXPORT_OK = qw();
    our %EXPORT_TAGS = ( FIELDS => [ @EXPORT_OK, @EXPORT ] );
}

=pod

=head1 NAME

Gtk2::Ex::Geo::DialogMaster - A class which maintains a set of glade dialogs

The <a href="http://geoinformatics.aalto.fi/doc/Geoinformatica/html/">
documentation of Gtk2::Ex::Geo</a> is written in doxygen format.

=cut

sub new {
    my($class, %params) = @_;
    my $self = {};
    $self->{buffer} = $params{buffer};
    bless $self => (ref($class) or $class);
}

sub get_dialog {
    my($self, $dialog_name) = @_;
    my @buf = ('<glade-interface>');
    my $push = 0;
    for (@{$self->{buffer}}) {
        # assumes Glade 3 style XML...
	$push = 1 if (/^  <widget/ and /$dialog_name/);
	push @buf, $_ if $push;
	$push = 0 if /^  <\/widget/;
    }
    push @buf, '</glade-interface>';
    my $gladexml = Gtk2::GladeXML->new_from_buffer("@buf");
    my $dialog = $gladexml->get_widget($dialog_name);
    return unless $dialog;
    return $gladexml;
}

1;
