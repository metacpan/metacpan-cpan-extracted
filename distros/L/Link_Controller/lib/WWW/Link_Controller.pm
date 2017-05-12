=head1 NAME

Link_Controller - perl module with LinkController constants

=head1 DESCRIPTION

This module includes various constants which are used within
LinkController for configuring each of the programs.  These are the
constants which are not expected to be changed during an installation.

=cut

package WWW::Link_Controller;
$REVISION=q$Revision: 1.3 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

# The $refresh_key is a key used in the link database to store the
# last time the link database was updated.

$refresh_key="%++refresh_time" ;

@special_keys = ($refresh_key);

$special_regex = qr/^\%\+\+/;
