=head1 NAME

Konstrukt::Settings - Settings management

=head1 SYNOPSIS

	#there is one registy object that may be used from everywhere in the konstrukt-code
	#set a default value. very useful in the init() method of your plugin
	$Konstrukt::Settings->default('yourplugin/key' => 'defaultvalue');
	#set a value
	$Konstrukt::Settings->set('yourplugin/key' => 'value');
	#get a value
	my $value = $Konstrukt::Settings->get('key');

=head1 DESCRIPTION

This is the place where all settings are stored. The initial settings
will be loaded from your konstrukt.settings, which is placed in the document root
of each site.

Note that the settings are not persistent between multiple requests!
They will be (re)loaded on each request. For persistance take a look at
L<Konstrukt::Session>.

For further information take a look at the documentation for each method.

=head1 CONFIGURATION

All initial settings are stored in your konstrukt.settings, which is placed in the
document root of each site.

Each directive looks like this:

	some/plugins/setting   here go the values #this comment will be ignored

Take a look at the documentation of each module/plugin. If it offers settings,
they will be described at the CONFIGURATION section of each module/plugin.

=cut

package Konstrukt::Settings;

use strict;
use warnings;

use Konstrukt::Debug;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless { _reg => {} }, $class;
}
#= /new

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	$self->{_reg} = {};
	$self->load_settings('/konstrukt.settings');
	return 1;
}
#= /init

=head2 load_settings

Loads the settings from the specified file

B<Parameters>:

=over

=item * $file - The path (relative to the document root) to the settings file.

=back

=cut
sub load_settings {
	my ($self, $filename) = @_;

	my $file = $Konstrukt::File->read($filename);
	if (not defined $file) {#file could not be read
		$Konstrukt::Debug->error_message("Settings file '$filename' could not be read! Using lame default settings.") if Konstrukt::Debug::ERROR;
	} else {
		my @lines = split /(\r?\n|\r)/, $file;
		my ($setting,$value);
		foreach (@lines) {
			if ($_) {
				if (/\#/) {#We have an inline comment. Kill everything behind it
					$_ =~ s/\#.*//;
				}
				#kill leading and tailing spaces
				$_ =~ s/\s*$//;
				$_ =~ s/^\s*//;
				($setting,$value) = (split /\s+/, $_, 2);
				#no undefs please
				$value = "" if not defined $value;
				$self->set($setting => $value) if defined $setting;
			}#if $_
		}#foreach @lines
	}#if doesn't exist
	
	return 1;
}
#= /load_settings

=head2 get

Returns a value from the konstrukt settings.

B<Parameters>:

=over

=item * $key - The settings key

=back

=cut
sub get {
	my ($self, $key) = @_;
	
	return (exists $self->{_reg}->{$key} ? $self->{_reg}->{$key} : undef);
}
#= /get

=head2 set

Works similary to get() but accepts two parameters
and lets you set values instead of reading them.

B<Parameters>:

=over

=item * $key - The name of the entry

=item * $value - The value you want to set

=back

=cut
sub set {
	my ($self, $key, $value) = @_;
	
	$self->{_reg}->{$key} = $value;
	
	return 1;
}
#= /set

=head2 default

Only sets a value if it's not been set, yet. Useful for specifying default settins.

B<Parameters>:

=over

=item * $key - The name of the entry

=item * $value - The value you want to set

=back

=cut
sub default {
	my ($self, $key, $value) = @_;
	
	$self->{_reg}->{$key} = $value unless exists $self->{_reg}->{$key};
	
	return 1;
}
#= /default

=head2 delete

Works similary to get() and set() but instead of reading or writing from or to
an entry you simply clear a value of a specific entry.

B<Parameters>:

=over

=item * $key - The entry to delete

=back

=cut
sub delete {
	my ($self, $key) = @_;

	delete $self->{_reg}->{$key};
}
#= /delete

#create global object
sub BEGIN { $Konstrukt::Settings = __PACKAGE__->new() unless defined $Konstrukt::Settings; }

return 1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
