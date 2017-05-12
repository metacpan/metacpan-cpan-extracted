package Mail::SpamCannibal::Password;

use strict;
#use diagnostics;
#use warnings;
use Data::Password::Manager;
use vars qw($VERSION @ISA @EXPORT_OK @to64);
require Exporter;

@ISA = qw(Exporter);
$VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = @Data::Password::Manager::EXPORT_OK;
import Data::Password::Manager @EXPORT_OK;


=head1 NAME

Mail::SpamCannibal::Password - generate and check B<crypt - des> passwords

=head1 SYNOPSIS

  use Mail::SpamCannibal::Password qw(
        pw_gen
        pw_valid
        pw_obscure
        pw_clean
	pw_get
  );

  $password = pw_gen($cleartext);
  $ok = pw_valid($cleartxt,$password);
  $clean_text = pw_clean($dirty_text);
  ($code,$text) = $pw_obscure($newpass,$oldpass,$min_len);
  $passwd = pw_get($user,$passwd_file,\$error);

=head1 DESCRIPTION

Deprecated. All functions inherited from Data::Password::Manager

=head1 EXPORTS_OK 

        pw_gen
        pw_valid
        pw_clean
        pw_obscure
	pw_get

=head1 COPYRIGHT

Copyright 2006, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, BizSystems <michael@bizsystems.com>

=head1	SEE ALSO

L<Data::Password::Manager>

=cut

1;
