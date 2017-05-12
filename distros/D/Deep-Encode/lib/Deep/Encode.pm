package Deep::Encode;
# vim: ts=8 sts=4 sw=4 et
use strict;
use warnings;

require Exporter;
require Encode;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Deep::Encode ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    all => [
        qw(
            deep_utf8_check
            deep_utf8_off
            deep_utf8_on
            deep_utf8_upgrade
            deep_utf8_downgrade
            deep_utf8_decode
            deep_utf8_encode
            deep_from_to
            deep_encode
            deep_decode

            deep_str_clone

            deepc_utf8_upgrade
            deepc_utf8_downgrade
            deepc_utf8_decode
            deepc_utf8_encode
            deepc_from_to
            deepc_encode
            deepc_decode

        )
    ],
);

our @EXPORT_OK = ( map @$_, map  $EXPORT_TAGS{$_} , 'all' );
our @EXPORT =  ( map @$_, map  $EXPORT_TAGS{$_} , 'all');

our $VERSION = '0.19';

require XSLoader;
XSLoader::load('Deep::Encode', $VERSION);

sub deepc_utf8_upgrade{
	deep_utf8_upgrade( my $val = deep_str_clone( $_[0] ));
	return $val;
}

sub deepc_utf8_downgrade{
	deep_utf8_downgrade( my $val = deep_str_clone( $_[0] ));
	return $val;
}
sub deepc_utf8_decode{
	deep_utf8_decode( my $val = deep_str_clone( $_[0] ));
	return $val;
}

sub deepc_utf8_encode{
	deep_utf8_encode( my $val = deep_str_clone( $_[0] ));
	return $val;
}
sub deepc_decode{
	deep_decode( my $val = deep_str_clone( $_[0] ), $_[1]);
	return $val;
}
sub deepc_encode{
	deep_encode( my $val = deep_str_clone( $_[0] ), $_[1]);
	return $val;
}
sub deepc_from_to{
	deep_from_to( my $val = deep_str_clone( $_[0] ), $_[1], $_[2]);
	return $val;
}
1;
