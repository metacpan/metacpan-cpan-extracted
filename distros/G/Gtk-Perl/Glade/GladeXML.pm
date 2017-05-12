

package Gtk::GladeXML;

require Gtk;
require Exporter;
require DynaLoader;
require AutoLoader;

use Carp;
use strict;

our $VERSION = "0.7010";

@Gtk::GladeXML::ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@Gtk::GladeXML::EXPORT = qw(
        
);
# Other items we are prepared to export if requested
@Gtk::GladeXML::EXPORT_OK = qw(
);

bootstrap Gtk::GladeXML;

require Gtk::GladeXML::Types;

sub dl_load_flags {Gtk::dl_load_flags()}

my $verbose = 0;

sub import {
	my $self = shift;
	foreach (@_) {
		$verbose++,  next if /^-verbose$/;
	}
}

# Autoload methods go after __END__, and are processed by the autosplit program.

sub _connect_helper {
	my ($handler_name, $object, $signal_name, $signal_data, 
		$connect_object, $after, $handler, @data) = @_;
	
	no strict qw/refs/;

	if ($connect_object) {
		my ($func) = $after? "signal_connect_object_after" : "signal_connect_object";
		$object->$func ($signal_name, $connect_object, $handler, @data, $signal_data);
	} else {
		my ($func) = $after? "signal_connect_after" : "signal_connect";
		$object->$func ($signal_name, $handler, $signal_data);
	}
}

sub _autoconnect_helper {
	my ($handler_name, $object, $signal_name, $signal_data, 
		$connect_object, $after, $package) = @_;
	my ($handler) = $handler_name;
	
	no strict qw/refs/;

	if (ref $package) {
		$handler = sub { $package->$handler_name(@_) };
	} else {
		$handler = $package ."::". $handler_name
			if ($package && $handler !~ /::/);
	}

	if ($connect_object) {
		my ($func) = $after? "signal_connect_object_after" : "signal_connect_object";
		$object->$func ($signal_name, $connect_object, $handler, $signal_data);
	} else {
		my ($func) = $after? "signal_connect_after" : "signal_connect";
		$object->$func ($signal_name, $handler, $signal_data);
	}
}

sub handler_connect {
	my ($self, $hname, @handler) = @_;

	$self->signal_connect_full($hname, \&_connect_helper, @handler);
}

sub signal_autoconnect_from_package {
	my ($self, $package) = @_;
	my ($handler);
	my ($chunk);
	($package, undef, undef) = caller() unless $package;
	$self->signal_autoconnect_full(\&_autoconnect_helper, $package);
}

sub _init_handler {
	my ($symbol, @libs) = @_;
	my ($libref, $handle, $error);
	$handle = DynaLoader::dl_find_symbol_anywhere ($symbol);
	unless ($handle) {
		@libs = DynaLoader::dl_findfile(@libs);
		foreach my $lib (@libs) {
			$libref = DynaLoader::dl_load_file($lib, 0);
			#warn "Cannot load: $lib\n" unless $libref;
			$handle = DynaLoader::dl_find_symbol($libref, $symbol) if $libref;
			#warn "Found symbol in $lib: $symbol\n" if $handle;
			last if $handle;
		}
	} else {
		#warn "Found symbol: $symbol\n";
	}
	if ($handle) {
		Gtk::GladeXML->call_init($handle);
	} else {
		warn "No libglade support: unknown symbol $symbol: ", DynaLoader::dl_error(), "\n"
			if $verbose;;
	}
}

sub gnome_init {
	# platform specific, but should do for now
	Gtk::GladeXML::_init_handler("glade_gnome_init", "glade-gnome", "libglade-gnome.so.0");
}

sub bonobo_init {
	Gtk::GladeXML::_init_handler("glade_bonobo_init", "glade-bonobo");
}

sub gnomedb_init {
	Gtk::GladeXML::_init_handler("glade_gnome_db_init", "glade-gnomedb");
}

Gtk->mod_init_add('Gtk', sub {
	init Gtk::GladeXML;
});

Gtk->mod_init_add('Gnome', sub {
	gnome_init Gtk::GladeXML;
});

1;
__END__
