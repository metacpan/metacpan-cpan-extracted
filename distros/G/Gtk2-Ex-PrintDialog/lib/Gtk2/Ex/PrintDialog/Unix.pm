# $Id: Unix.pm,v 1.5 2007/04/25 10:44:04 gavin Exp $
# Copyright (c) 2005 Gavin Brown. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms as
# Perl itself.
package Gtk2::Ex::PrintDialog::Unix;
use Gtk2::Ex::PrintDialog;
use Net::CUPS;
use vars qw($LPR $PRINTCMD $PS2PDF $PDFCMD);
use strict;

our $LPR	= 'lpr';
our $PRINTCMD	= Gtk2::Ex::PrintDialog::which($LPR);
our $PS2PDF	= 'ps2pdf';
our $PDFCMD	= Gtk2::Ex::PrintDialog::which($PS2PDF);


sub new {
	my $self = {};
	$self->{cups} = Net::CUPS->new;
	bless($self, shift);
}

sub get_printers {
	my $self = shift;
	return grep { defined } $self->{cups}->getDestinations;
}

sub print_file {
	my ($self, $printer, $file) = @_;
	$self->{cups}->getDestination($printer)->printFile($file, ref($self));
}

sub get_default_print_command {
	my $self = shift;
	return (-x $PRINTCMD ? $PRINTCMD : $LPR);
}

sub can_print_pdf {
	return -x $PDFCMD;
}

sub print_to_pdf {
	my ($self, $data, $file) = @_;
	my $cmd = sprintf('%s - "%s"', $PDFCMD, $file);
	Gtk2::Ex::PrintDialog::_print_data_to_command(undef, $data, $cmd);
}

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::PrintDialog::Unix - generic Unix backend for L<Gtk2::Ex::PrintDialog>

=head1 DESCRIPTION

This module is a printing backend for L<Gtk2::Ex::PrintDialog>. You should
never need to access it directly.

=head1 AUTHOR

Gavin Brown (gavin dot brown at uk dot com)  

=head1 COPYRIGHT

(c) 2005 Gavin Brown. All rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.     

=cut
