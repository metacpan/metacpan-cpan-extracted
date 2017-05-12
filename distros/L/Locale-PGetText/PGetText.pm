# $Id: PGetText.pm,v 1.3 1998/11/18 11:23:11 msh Exp msh $
#
# (C) 1998 Mike Shoyher
#

package Locale::PGetText;


$VERSION = "0.16" ;


=head1 NAME

PGetText - pure perl i18n routines

=head1 SYNOPSIS

 
  use Locale::PGetText;

  Locale::PGetText::setLocaleDir('/usr/local/perl/locale');
  Locale::PGetText::setLanguage('ru-koi8r');
  
  print gettext("Welcome!"), "\n";

=head1 DESCRIPTION

PGetText provides the same functionality as GNU gettext does, but it is written in pure perl and doesn't require any system locale stuff.

I<setLocaleDir()> sets directory where messages database is stored (there are no default and no domains).

I<setLanguage()> switches languages. 

I<gettext()> retrieves message in local language corresponding to given message. 

=head1 SEE ALSO

MsgFormat(1)

=head1 AUTHOR

Mike Shoyher <msh@corbina.net>, <msh@apache.lexa.ru>

=cut

# Code

use Exporter;
use Fcntl;
use strict;

use vars  qw(%messages $locale_dir);

BEGIN {
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use vars qw($module);
@ISA = qw(Exporter);
@EXPORT = qw(gettext);

# Here goes some AnyDBM-like magic

my ($dbm_kosher,$mod);
$dbm_kosher=0;
my @modules=qw(GDBM_File SDBM_File DB_File NDBM_File ODBM_File); 
for $mod (@modules){
    $module=$mod;
    if (eval "require $mod") {
           $dbm_kosher=1;
           last;
    }
}
die "No suitable DBM library" unless ($dbm_kosher);
}


END {
untie(%messages);
}



return 1;

sub setLocaleDir($)
{
$locale_dir=shift;
}

sub setLanguage($)
{
my $lang=shift;
my $path="$locale_dir/$lang";
die "Call setLocaleDir() first" unless ($locale_dir);
tie(%messages, $module, $path, O_RDONLY,0644) || die ("Cannot open language file $path");
}

sub gettext($)
{
my $s=shift;
my $msg=$messages{$s};
return $msg if ($msg);
return $s;
}


