package Mac::AppleScript;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mac::AppleScript ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	&RunAppleScript
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.04';

bootstrap Mac::AppleScript $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Mac::AppleScript - Perl extension to execute applescript commands on OS X

=head1 SYNOPSIS

  use Mac::AppleScript qw(RunAppleScript);
  RunAppleScript(qq(tell application "Finder"\nactivate\nend tell))
    or die "Didn't work!";

=head1 DESCRIPTION

Simple interface to the OSA scripting stuff.

Returns undef on error and sets $@ to the error code. Codes are listed
in the AppleScript documentation. On successful completion, this
returns the output of the AppleScript command. For empty returns, like
with the sample script in the SYNOPSIS, AppleScript appears to return
the string "{}" ( That's an open and close squiggle bracket, without
the quotes)

=head2 EXPORT

None by default.

=head1 AUTHOR

Dan Sugalski, dan@sidhe.org

Chunks of the code came from Apple Tech Notes, though that'll be cleaned out soon.

=head1 SEE ALSO

perl(1).

=cut
