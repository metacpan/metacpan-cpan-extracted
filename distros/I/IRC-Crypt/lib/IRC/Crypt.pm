package IRC::Crypt;

use 5.000;
use strict;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
@ISA = qw(Exporter
	DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IRC::Crypt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&IRC::Crypt::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

bootstrap IRC::Crypt $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

IRC::Crypt - Perl wrapper for the irc-crypt library

=head1 SYNOPSIS

  use IRC::Crypt;
  IRC::Crypt::add_default_key("#chan",  "key");
  my $crypted = IRC::Crypt::encrypt_message_to_address("#chan", "myNick", "hello, world");
  my ($plain, $nick, $tdiff) = IRC::Crypt::decrypt_message($crypted);
  print $plain;

=head1 DESCRIPTION

Simple wrapper for the irc-crypt -library.

=head1 FUNCTIONS

=head2 add_known_key( key )

  Add key to the known key pool.
  
=head2 delete_known_key( key )

  Delete key from the known key pool.
  
=head2 add_default_key( addr, key )

  Add default key for recipient (channel or nick).

=head2 delete_default_key( addr )

  Delete default key from a recipient (channel or nick).
  
=head2 delete_all_keys( )

  Delete all default and known keys.
  
=head2 delete_all_default_keys( )

  Delete all default keys.
  
=head2 delete_all_known_keys( )

  Delete all known keys.
  
=head2 encrypt_message_to_address( addr, sender_nick, message )

  Encrypt message to address (with default key).
  Returns the encrypted message or undef on failure.

=head2 encrypt_message_with_key( key, sender_nick, message )

  Encrypt message with key.
  Returns the encrypted message or undef on failure.

=head2 decrypt_message( crypted )

  Decrypts message. Returns ( msg, nick, tdiff )
  if succesful, ( msg, undef, undef ) otherwise.

=head2 is_encrypted_message_p( msg )

  Return true if message is in valid crypto message format.

=head2 set_key_expand_version( n )

  Set default key expand version to n = (1,2,3).
  
=head2 key_expand_version( )

  Return current default key expand version.
  
=head1 SEE ALSO

http://people.ssh.fi/tri/irchat/index.html
http://www.kivela.net/jaska/projects/perl-IRC-Crypt/

=head1 AUTHOR

Jaska Kivelä, E<lt>jaska@kivela.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jaska Kivelä

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
