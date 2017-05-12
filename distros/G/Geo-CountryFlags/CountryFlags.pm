#!/usr/bin/perl
package Geo::CountryFlags;
use strict;
use Geo::CountryFlags::I2C;
use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $i2c = subref Geo::CountryFlags::I2C;

=head1 NAME

  Geo::CountryFlags - dynamically fetch flag gif's from CIA

=head1 SYNOPSIS

  use Geo::CountryFlags

  $gcf = new Geo::CountryFlags;

return a local path to the flag file
fetch the file from CIA if necessary
and put it in the flag directory

  $flag_path = $gcf->get_flag($country_code,[flag_dir])

  default:
  flag_dir = ./flags

retrieve the CIA country code

  $cia_code	= $gcf->cc2cia($country_code)

retrieve the ISO country name

  $gci = new Geo::CountryFlags::ISO;
  $country_name	= $gci->value($country_code);

retrieve the CIA country name

  $gcc = new Geo::CountryFlags::CIA;
  $country_name = $gcc->value($cia_code);

=head1 DESCRIPTION

Provides methods to display / retrieve flag gifs dynamically from the web
site of the Central Intelligence Agency. Permanently caches a
local copy of the flag gif in your web site sub directory.

The flags for all country codes as of module publication are included
in the ./flags directory should you wish to install them. However,
If LWP::Simple is installed, Geo::CountryFlags will fetch them as needed
and store them in ./flags [default] or the directory of you choice on your
web site.

To fetch a single flag PATH the usage is simply:

  my $cc = 'US';	# country code

  my $flag_path = Geo::CountryFlags->new->get_flag($cc);

  for multiple flags:

  $gcf = new Geo::CountryFlags;
  for (blah.... blah) {
    my $cc = function_of(blah...);
    my $flag_path = $gcf->get_flag($cc);
    ....
  }

=head1 METHODS

=over 4

=item $gcf = new Geo::CountryFlags;

  input:	none
  returns:	blessed package reference

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
}

=item $flag_path=$gf->get_flag($country_code,[flag_dir]);

  input:	country code,
		flag directory (optional)
		  default = ./flags

  output:	path_to/flag.image
		or undef if the country 
		flag is not available

  $@	:	clear on normal return
		set to error if unable to 
		connect or retrieve file
		from target flag server
		(only set on undef return)

=cut

my $gcu;

sub get_flag {
  my ($self,$cc,$fd) = @_;
  return undef unless $cc;
  $fd = './flags' unless $fd;
  unless ( -e $fd) {
    if (-d $fd) {
      eval {die "$fd is not a directory"};
      return undef;
    } else {
      mkdir $fd, 0755;
    }
  }
  undef $@;
  my $fp = $fd .'/'. $cc .'-flag.gif';
  return $fp if -e $fp;			# return flag if it exists

  my $cia = $i2c->($cc) or return undef;
  require LWP::Simple;
  unless ($gcu) {
    require Geo::CountryFlags::URLs;
    $gcu = new Geo::CountryFlags::URLs;
  }
  return undef unless eval {		# response must be 200, OK
	200 == ($_ = &LWP::Simple::getstore(
		$gcu->CIAFLAGS . $cia .'-flag.gif',
		$fp)) ||
		die $_
	};
  return $fp;
}

=item $cia_code=$gf->cc2cia($country_code);

  input:	country code
  output:	cia code
		  or
		undef is cia code
		is known absent

=cut

sub cc2cia {
  shift;
  goto &$i2c;
}

=pod

=back

=cut

1;
__END__

=head1 MODULE UPDATES

This module has several extensions that are auto-created by the data
directly from the CIA and ISO web sites. To force a rebuild follow this
procedure:

	perl Makefile.PL
	make realclean
	perl Makefile.PL
	make
	make test
	make install

This modules has two files that allow you to keep it up to date.

	Valid_Urls
	Map_Exceptions

=over 4

=item * Valid_Urls

This file contains the valid URL's for the CIA flags page, the CIA flags
directory and the ISO flag code text files. If these change, you can updated
the Valid_Urls file then remake the module as follows:

	perl Makefile.PL
	make
	make test
	make install

=item * Map_Exceptions

During the 'perl Makefile.PL' process, the unmatched entries from both the
ISO and CIA data bases are printed in the terminal window. The
Map_Exceptions file should be updated so that the left hand side contains
the exact text from the ISO data that does not match and the right hand side
contains at least the minimum text from the related CIA data that will uniquely match the ISO data.

=back

=head1 UTILITIES

The ./util directory contains two utility programs

	get_flags.pl
	make_htm.pl

=head2 get_flags.pl names

    lists all flags by: [sorted by country name]
      country-code, CIA-code, ISO country-name

=head2 get_flags.pl

    retrieves all flags from CIA and stores 
    in locally created directory ./flags

If run from the build directory after module installation, this script will
create/update the B<flags> directory with all available ISO flags matching
the CIA database. If the module is remade from scratch with a

  make realclean

this process will update the MANIFEST with the new B<flag> list as well.

=head2 make_htm.pl

    prints the text for an html page containing all
    the flags sorted by country name from a 
    local ./flags directory

=head1 DEPENDENCIES

	File::SafeDO
	LWP::Simple	[optional]

LWP::Simple is required for dynamic operation. If you are simply going to
server static gifs from the flags directory without EVER fetching a new one
from the CIA, then LWP::Simple is not needed.

Likewise, if you intend to use this module in conjunction with showing flags
for IP addresses, then you want to have a look at either;

	Geo::IP::PurePerl
    or
	Geo::IP

=head1 AUTHOR

Michael Robinton michael@bizsystems.com

=head1 COPYRIGHT and LICENSE

  Copyright 2003 - 2006 Michael Robinton, michael@bizsystems.com

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

Geo::IP::PurePerl

=cut

1;
