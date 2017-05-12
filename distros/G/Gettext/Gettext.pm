package Gettext;
use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use POSIX 'locale_h';
use locale;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( );

$VERSION = '0.01';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

   my $gettextcmd = ( -e '/bin/gettext' ? '/bin/gettext' : '/usr/bin/gettext' );

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = {};

   $self->{'DOMAINNAME'} = untaint($ENV{'DOMAINNAME'}) || 'messages';
   $self->{'DIRNAME'} = untaint($ENV{'TEXTDOMAINDIR'}) || ( -d '/usr/lib/locale' ? '/usr/lib/locale' : '/usr/share/locale' );

   bless($self, $class);

   return $self;
}

sub bindtextdomain {
   my $self = shift;
   my ($domainname, $dirname) = @_;

   return '' if not defined $domainname or $domainname eq '';

   return $self->{'DIRNAME'} if not defined $dirname or $dirname eq '';

   $self->{'DOMAINNAME'} = $domainname;
   $self->{'DIRNAME'} = $dirname;

   return $dirname;
}

sub textdomain {
   my $self = shift;
   my ($domainname) = @_;

   return $self->{'DOMAINNAME'} if not defined $domainname;

   if ($domainname eq '') {
      $self->{'DOMAINNAME'} = 'messages'
   }
   else {
      # really should be input validation for a valid filespec ...
      $self->{'DOMAINNAME'} = $domainname;
   }

   return $self->{'DOMAINNAME'};
}

sub gettext {
   my $self = shift;
   my ($msgid) = @_;

   # Even more checking should be done here (and LC_CTYPE changed to LC_MESSAGES when Perl supports LC_MESSAGES) ...

   if ((not defined $ENV{'NLSPATH'} or $ENV{'NLSPATH'} eq '') and 
       (setlocale(LC_CTYPE) eq 'C')) {
      return $msgid;
   }

   my $oldlocale = setlocale(LC_CTYPE);

   return `LC_MESSAGES=$oldlocale;LANGUAGE=$oldlocale;TEXTDOMAINDIR=$self->{'DIRNAME'};$gettextcmd $self->{'DOMAINNAME'} $msgid`;
}

sub dgettext {
   my $self = shift;
   my ($domainname, $msgid) = @_;

   # Even more checking should be done here (and LC_CTYPE changed to LC_MESSAGES when Perl supports LC_MESSAGES) ...

   if ((not defined $ENV{'NLSPATH'} or $ENV{'NLSPATH'} eq '') and 
       (setlocale(LC_CTYPE) eq 'C')) {
      return $msgid;
   }

   my $oldlocale = setlocale(LC_CTYPE);

   return `LC_MESSAGES=$oldlocale;LANGUAGE=$oldlocale;TEXTDOMAINDIR=$self->{'DIRNAME'};$gettextcmd $domainname $msgid`;
}

sub dcgettext {
   my $self = shift;
   my ($domainname, $msgid, $category) = @_;

   # Even more checking should be done here (and LC_CTYPE changed to LC_MESSAGES when Perl supports LC_MESSAGES) ...

   if ((not defined $ENV{'NLSPATH'} or $ENV{'NLSPATH'} eq '') and 
       (setlocale(LC_CTYPE) eq 'C')) {
      return $msgid;
   }

   # the env must be set, but this is kind of a shotgun approach ...
   return `LANGUAGE=$category;LC_MESSAGES=$category;TEXTDOMAINDIR=$self->{'DIRNAME'};$gettextcmd $domainname $msgid`;
}

sub untaint {
   my $str = shift || '';

   return '' if $str eq '';

   $str =~ s/[^\w.\\\/-]//g;

   return $str;
}

1;
__END__

=head1 NAME

Gettext - Perl extension for emulating gettext-related API.

=head1 SYNOPSIS

  use Gettext;

=head1 DESCRIPTION

Gettext.pm emulates the gettext library routines in Perl, although it calls the external utility program gettext to actually read .mo files.

man gettext on Solaris has pretty good documentation.

The steps to use this module are:

=over 4

=item *

install the gnu gettext package if necessary (not needed on Solaris or Red Hat)

=item *

set TEXTDOMAINDIR, LANGUAGE, LANG, and LC_* if needed in your env.

=item *

use xgettext on your script that contains gettext calles  to make the .po
(portable message object) file, run msgfmt to make the
.mo (message object) file, and move the .mo
file to where you want it, normally $TEXTDOMAINDIR/lang/LC_MESSAGES.

=item *

call setlocale before calling these functions.

=back

use Gettext;

my $gt = new Gettext;

$gt->textdomain('domainname');

$gt->bindtextdomain('domainname', 'dirname');

$gt->gettext('msgid');

$gt->dgettext('domainname', 'msgid');

$gt->dcgettext('domainname', 'msgid', 'category (locale)');

=head1 SAMPLE

use strict;

use diagnostics;

use POSIX 'locale_h';

use locale;

use Gettext;

   setlocale(LC_CTYPE, 'es_ES');

   my $gt = new Gettext();

   $gt->bindtextdomain("messages", "/root/work");

   print $gt->gettext("flower"),"\n";
   print $gt->gettext("yellow"),"\n";

   print $gt->dgettext("messages", "flower"),"\n";
   print $gt->dgettext("messages", "yellow"),"\n";

   print $gt->dcgettext("messages", "flower", "fr_FR"),"\n";
   print $gt->dcgettext("messages", "yellow", "fr_FR"),"\n";

   print $gt->textdomain(),"\n";
   print $gt->textdomain(''),"\n";

Tested on Solaris 2.6 and Red Hat Linux 6.0

=head1 AUTHOR

James Briggs, james@rf.net

=head1 SEE ALSO

perldoc perllocale

=head1 TO DO

Gettext.pm calls the external gettext utility program, but someday should
have an internal routine to directory read .mo files.

=cut

