package Mail::ListDetector;

use strict;
use warnings;

use Carp qw(carp croak);

require Exporter;
use AutoLoader qw(AUTOLOAD);
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);
use vars qw(@DETECTORS);

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::ListDetector ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '1.04';

my @default_detectors = qw(Mailman Ezmlm Smartlist Listar Ecartis Yahoogroups CommuniGatePro GoogleGroups Listbox AutoShare RFC2919 Fml ListSTAR RFC2369 CommuniGate LetterRip Lyris Onelist Majordomo Listserv);

foreach (@default_detectors) {
  s/^/Mail::ListDetector::Detector::/;
  Mail::ListDetector->register_plugin($_);
}

# package subs

sub new {
  my $proto = shift;
  my $message = shift;
  carp("Mail::ListDetector:: no message supplied\n") unless defined($message);
  my $class = ref($proto) || $proto;

  # get message

  # for all detectors, instantiate and pass until one returns
  # an object
  my $list;
  foreach my $detector_name (@DETECTORS) {
    my $detector;
    $detector = eval "new $detector_name";
    if ($@) {
    	die $@;
    }
    if ($list = $detector->match($message)) {
      return $list;
    }
  }
  
  return undef;
}

# load a plugin module
sub register_plugin {
  my $self = shift;
  my $plugin_name = shift;

  eval "require $plugin_name; ${plugin_name}->import;";
  croak("register_plugin couldn't load $plugin_name: $@") if $@; 
  push @DETECTORS, $plugin_name;
}

1;
__END__

=head1 NAME

Mail::ListDetector - Perl extension for detecting mailing list messages

=head1 SYNOPSIS

  use Mail::ListDetector;

=head1 DESCRIPTION

This module analyzes mail objects in any of the classes handled by
L<Email::Abstract>. It returns a Mail::ListDetector::List object
representing the mailing list.

The RFC2369 mailing list detector is also capable of matching some
Mailman and Ezmlm messages. It is deliberately checked last to allow
the more specific Mailman and Ezmlm parsing to happen first, and more
accurately identify the type of mailing list involved.

=head1 METHODS

=head2 new

This method is the core of the module. Pass it a mail object, it will
either return a Mail::ListDetector::List object that describes the
mailing list that the message was posted to, or C<undef> if it appears
not to have been a mailing list post.

=head2 register_plugin($plugin_name)

Registers a new plugin module that might recognise lists. Should
be a subclass of Mail::ListDetector::Detector::Base, and provide
the same interface as the other detector modules.

You can eval arbitrary perl code with this, so don't do that if that's
not what you want.

=head1 EMAILS USED

This module includes a number of sample emails from various mailing
lists. In all cases, mails are used with permission of the author, and
must not be distributed separately from this archive. If you believe
I may have accidentally used your email or content without permission,
contact me, and if this turns out to be the case I will immediately remove
it from the latest version of the archive.

=head1 BUGS

=over 4

=item *

A lot of the code applies fairly simple regular expressions to email
address to extract information. This may fall over for really weird
email addresses, but I'm hoping no-one will use those for names of
mailing lists.

=item *

The majordomo and smartlist recognisers don't have much to go on,
and therefore are probably not as reliable as the other detectors.
This is liable to be hard to fix.

=item *

Forwarding messages (for example using procmail) can sometimes break
the C<Sender: > header information needed to recognise some list
types.

=back

=head1 AUTHORS

=over 4

=item *

Michael Stevens - michael@etla.org.

=item *

Andy Turner - turner@mikomi.org.

=item *

Adam Lazur - adam@lazur.org.

=item *

Peter Oliver - p.d.oliver@mavit.freeserve.co.uk

=item *

Matthew Walker - matthew@walker.wattle.id.au

=item *

Tatsuhiko Miyagawa - miyagawa@bulknews.net

=item *

johnnnnnn - john@phaedrusdeinus.org

=item *

Mik Firestone - mik@racerx.homedns.org

=item *

Simon Cozens - simon@simon-cozens.org

=back

=head1 SEE ALSO

perl(1). The Mail::Audit::List module, which is a convenient way of using
Mail::Audit and Mail::ListDetector together.

=cut
