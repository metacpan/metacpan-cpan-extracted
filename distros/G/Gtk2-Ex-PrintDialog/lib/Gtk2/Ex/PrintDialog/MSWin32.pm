# $Id: MSWin32.pm,v 1.1 2005/10/05 14:15:06 jodrell Exp $
# Copyright (c) 2005 Gavin Brown. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms as
# Perl itself.
package Gtk2::Ex::PrintDialog::MSWin32;
use Win32::Printer;
use Printer;
use strict;

sub new {
	my $self = bless({}, shift);
	$self->{prn} = Printer->new;     
	return $self;
}

sub get_printers {
	my $self = shift;
	use Data::Dumper;
	my %data = $self->{prn}->list_printers;
	return @{$data{name}};
}

sub print_file {
	my ($self, $printer, $file) = @_;
}

sub get_default_print_command {
	my $self = shift;
	return '';
}

sub can_print_pdf {
	return undef;
}

sub print_to_pdf {
	my ($self, $data, $file) = @_;
	return undef;
}

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::PrintDialog::MSWin32 - generic Windows backend for L<Gtk2::Ex::PrintDialog>

=head1 DESCRIPTION

This module is a printing backend for L<Gtk2::Ex::PrintDialog>. You should
never need to access it directly.

=head1 AUTHOR

Gavin Brown (gavin dot brown at uk dot com)  

=head1 COPYRIGHT

(c) 2005 Gavin Brown. All rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.     

=cut
