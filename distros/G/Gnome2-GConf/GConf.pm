#
# Copyright (c) 2003-2006 by Emmanuele Bassi (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307  USA.

package Gnome2::GConf;

use 5.008;
use strict;
use warnings;

use Glib;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '1.044';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::GConf->bootstrap ($VERSION);


# Preloaded methods go here

package Gnome2::GConf::Value;

use overload
	'==' => sub { Gnome2::GConf::Value::compare($_[0], $_[1]) },
	fallback => 1;

use overload
	'""' => sub { Gnome2::GConf::Value::to_string($_[0]) },
	fallback => 1;

package Gnome2::GConf::Client;
use Carp;

sub get_list
{
	my $self = shift;	# the object
	my $key  = shift;
	my $check_error = shift || 1;

	my $val = $self->get($key, $check_error);
	return $val->{value};
}

sub get_pair
{
	my $self = shift;	# the object
	my $key  = shift;
	my $check_error = shift || 1;

	my $val = $self->get($key, $check_error);
	carp "$key is not bound to a pair" if not $val->{type} eq 'pair';

	return ($val->{car}, $val->{cdr});
}

sub set_list
{
	my $self = shift;	# the object
	my $key  = shift;
	my $type = shift;
	my $list = shift;
	my $check_error = shift || 1;

	$self->set($key, { type => $type, value => $list }, $check_error);
}

sub set_pair
{
	my $self = shift;	# the object
	my $key  = shift;
	my $car  = shift;
	my $cdr  = shift;
	my $check_error = shift || 1;

	$self->set($key, {
			type	=> 'pair',
			car		=> $car,
			cdr		=> $cdr,
		}, $check_error);
}

package Gnome2::GConf;

1;
__END__

=head1 NAME

Gnome2::GConf - Perl wrappers for the GConf configuration engine.

=head1 SYNOPSIS

  use Gnome2::GConf;

  my $client = Gnome2::GConf::Client->get_default;
  my $app_key = "/apps/myapp/mykey";
  
  $client->add_dir($app_key, 'preload-none');
  
  # add a notify for the key
  my $notify_id = $client->notify_add($app_key, sub {
      my ($client, $cnxn_id, $entry) = @_;
      return unless $entry->{value};
		
      if ($entry->{value}->{type} eq 'string') {
        printf "key '%s' changed to '%s'\n",
	       $entry->{key},
	       $entry->{value}->{value};
      }
    });
  
  my $string = $client->get_string($app_key);
  $string = 'some string' unless $string;
  
  $client->set($app_key, { type => 'string', data => $string });
  
  # set a schema for the key
  $client->set_schema ($app_key,
      {
        type => 'string',
	locale => 'C',
	short_desc => 'Some key.',
	long_desc => 'This key does something.',
	owner => 'some_program'
      });
  
  # remove the notification callback
  $client->notify_remove($notify_id);

=head1 ABSTRACT

Perl bindings to the 2.2 series of the GConf configuration engine
libraries, for use with gtk2-perl.

=head1 DESCRIPTION

This module allows you to use the GConf configuration system in order
to store/retrieve the configuration of an application.  The GConf
system is a powerful configuration manager based on a user daemon that
handles a set of key and value pairs, and notifies any changes of the
value to every program that monitors those keys.  GConf is used
by GNOME 2.x.

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

Find out more about Gnome at http://www.gnome.org.

=head1 DIFFERENT DATA TYPES

Some opaque data types in GConf are not registered inside the Glib type
system.  Thus, they have been implemented in a more perlish way, when
possible, for the sake of coherency and following the principle of
least surprise for the perl developer.  These changes try to preserve
semantics, to add syntactic sugar and to remove the need for accessor
methods.

=over

=item GConfEntry

See L<Gnome2::GConf::Entry>

=item GConfValue

See L<Gnome2::GConf::Value>

=item GConfChangeSet

See L<Gnome2::GConf::ChangeSet>

=item GConfSchema

See L<Gnome2::GConf::Schema>

=back

=head1 DIFFERENT CALL SIGNATURES

Reflecting the changes operated for the data types, some methods that use
those type have had the call signature modified.

=over

=item GConfNotifyFunc

In C, the function passed to C<Gnome2::GConf::notify_add> must have the
following signature:
	
	void (GConfNotifyFunc *) (GConfClient * client,
	                          guint cnxn_id,
	                          GConfEntry * entry);

Where C<GConfEntry> is a container for the key/value pair.  Since in
perl there's no C<GConfEntry> (see above), the C<entry> parameter is
an hashref.

=item GConfClient::get

=item GConfClient::set

In C, these accessor methods return/use a C<GConfValue>.  In perl, they
return/use an hashref.  See L<Gnome2::GConf::Value>

=item GConfClient::get_list

=item GConfClient::set_list

These accessor methods use a string for setting the type of the lists
(lists may have values of only B<one> type), and an arrayref containing
the values.

=item GConfClient::get_pair

=item GConfClient::set_pair

These accessor methods use two hashref (representing C<GConfValue>s)
for the C<car> and the C<cdr> parameters.

=item GConfClient::get_schema

=item GConfClient::set_schema

Similarly to the get/set pair above, these two methods return/use an
hashref. See L<Gnome2::GConf::Schema>.

=item GConfClient::commit_change_set

In C, this method return a boolean value (TRUE on success, FALSE on
failure). On user request (using the boolean parameter
C<remove_committed>), it also returns the C<GConfChangeSet>, pruned of
the successfully committed keys.  In perl, this method returns a
boolean value both in scalar context or if the user sets to FALSE the
C<remove_committed> parameter; in array context or if the user requests
the uncommitted keys, returns both the return value and the pruned
C<GConfChangeSet>.

=back

=head1 SEE ALSO

L<perl>(1), L<Glib>(3pm).

=head1 AUTHOR

Emmanuele Bassi E<lt>ebassi@gmail.comE<gt>

gtk2-perl created by the gtk2-perl team: http://gtk2-perl.sf.net

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006 by Emmanuele Bassi

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
