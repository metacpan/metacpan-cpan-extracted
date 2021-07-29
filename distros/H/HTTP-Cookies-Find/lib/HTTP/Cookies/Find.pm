
package HTTP::Cookies::Find;

use warnings;
use strict;

use base 'HTTP::Cookies';

use Carp;
use Config::IniFiles;
use Data::Dumper;  # for debugging only
use File::HomeDir;
use File::Spec::Functions;
use File::Slurp;
use HTTP::Cookies::Mozilla;
use HTTP::Cookies::Netscape;
use User;

our
$VERSION = 1.417;

=head1 NAME

HTTP::Cookies::Find - Locate cookies for the current user on the local machine.

=head1 SYNOPSIS

  use HTTP::Cookies::Find;
  my $oCookies = HTTP::Cookies::Find->new('domain.com');
  my @asMsg = HTTP::Cookies::Find::errors;
  # Now $oCookies is a subclass of HTTP::Cookies
  # and @asMsg is an array of error messages

  # Call in array context to find cookies from multiple
  # browsers/versions:
  my @aoCookies = HTTP::Cookies::Find->new('domain.com');
  # Now @aoCookies is an array of HTTP::Cookies objects

=head1 DESCRIPTION

Looks in various normal places for HTTP cookie files.

=head1 METHODS

=over

=item new

Returns a list of cookie jars of type HTTP::Cookies::[vendor],
for all vendor browsers found on the system.
If called in scalar context, returns one cookie jar for the "first" vendor browser found on the system.
The returned cookie objects are not tied to the cookie files on disk;
the returned cookie objects are read-only copies of the found cookies.
If no argument is given, the returned cookie objects contain read-only copies of ALL cookies.
If an argument is given, the returned cookie objects contain read-only copies of only those cookies whose hostname "matches" the argument.
Here "matches" means case-insensitive pattern match;
you can pass a qr{} regexp as well as a plain string for matching.

=cut

############################################# main pod documentation end ##

use constant DEBUG_NEW => 0;
use constant DEBUG_GET => 0;

# We use global variables so that the callback function can see them:
use vars qw( $sUser $sHostGlobal $oReal );

our @asError;

sub _add_error
  {
  my $sMsg = shift || '';
  # print STDERR " DDD   add error ==$sMsg==\n";
  push @asError, $sMsg;
  } # _add_error

sub new
  {
  my $class = shift;
  $sHostGlobal = shift || '';
  my @aoRet;
  if ($^O =~ m!win32!i)
    {
 WIN32_MSIE:
      {
      # Massage the hostname in an attempt to make it match MS' highlevel
      # naming scheme:
      my $sHost = $sHostGlobal;
      print STDERR " DDD raw    sHost is $sHost\n" if DEBUG_NEW;
      $sHost =~ s!\.(com|edu|gov|net|org)\Z!!;  # delete USA domain
      $sHost =~ s!\.[a-z][a-z]\.[a-z][a-z]\Z!!;  # delete intl domain
      print STDERR " DDD cooked sHost is $sHost\n" if DEBUG_NEW;
      # We only look at cookies for the logged-in user:
      $sUser = lc User->Login;
      print STDERR " + Finding cookies for user $sUser with host matching ($sHost)...\n" if DEBUG_NEW;
      my ($sDir, %hsRegistry);
      eval q{require HTTP::Cookies::Microsoft};
      if ($@)
        {
        _add_error qq{ EEE can not load module HTTP::Cookies::Microsoft: $@\n};
        last WIN32_MSIE;
        } # if
      eval q{use Win32::TieRegistry(
                                    Delimiter => '/',
                                    TiedHash => \%hsRegistry,
                                   )};
      if ($@)
        {
        _add_error qq{ EEE can not load module Win32::TieRegistry: $@\n};
        last WIN32_MSIE;
        } # if
      print STDERR " DDD check registry...\n" if DEBUG_NEW;
      $sDir = $hsRegistry{"CUser/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders/Cookies"} || '';
      if ( ! defined($sDir) || ($sDir eq ''))
        {
        _add_error qq{ EEE can not find registry entry for MSIE cookies\n};
        last WIN32_MSIE;
        } # if
      if ( ! -d $sDir)
        {
        ; _add_error qq{ EEE registry entry for MSIE cookies is $sDir but that directory does not exist.\n}
        ; last WIN32_MSIE
        } # unless
      # index.dat is for XP; Low/index.dat is for Vista:
      foreach my $sFnameBase (qw( index.dat Low/index.dat ))
        {
        my $sFnameCookies = "$sDir\\$sFnameBase";
        if (-f $sFnameCookies)
          {
          _get_cookies($sFnameCookies, 'HTTP::Cookies::Microsoft');
          last WIN32_MSIE;
          } # if
        else
          {
          print STDERR " WWW cookie file $sFnameCookies does not exist\n" if DEBUG_NEW;
          }
        } # foreach
      } # end of WIN32_MSIE block
    # At this point, $oReal contains MSIE cookies (or undef).
    if (ref($oReal))
      {
      return $oReal if ! wantarray;
      push @aoRet, $oReal;
      } # if found MSIE cookies
    # If wantarray, or the MSIE cookie search failed, go on and look
    # for Netscape cookies:
 WIN32_NETSCAPE:
      {
      $oReal = undef;
      my $sDirWin = $ENV{WINDIR};
      my $sFnameWinIni = catfile($sDirWin, 'win.ini');
      if (! -f $sFnameWinIni)
        {
        _add_error qq{ EEE Windows ini file $sFnameWinIni does not exist\n};
        last WIN32_NETSCAPE;
        } # if
      my $oIniWin = new Config::IniFiles(
                                         -file => $sFnameWinIni,
                                        );
      if (! ref($oIniWin))
        {
        _add_error qq{ EEE can not parse $sFnameWinIni\n};
        last WIN32_NETSCAPE;
        } # if
      my $sFnameNSIni = $oIniWin->val('Netscape', 'ini');
      if (! defined $sFnameNSIni)
        {
        _add_error qq{ EEE Netscape / Mozilla is not installed\n};
        last WIN32_NETSCAPE;
        } # if
      if (! -f $sFnameNSIni)
        {
        _add_error qq{ EEE Netscape ini file $sFnameNSIni does not exist\n};
        last WIN32_NETSCAPE;
        } # if
      my $oIniNS = Config::IniFiles->new(
                                         -file => $sFnameNSIni,
                                        );
      if (! ref($oIniNS))
        {
        _add_error qq{ EEE can not parse $sFnameNSIni\n};
        last WIN32_NETSCAPE;
        } # if
      my $sFnameCookies = $oIniNS->val('Cookies', 'Cookie File');
      _get_cookies($sFnameCookies, 'HTTP::Cookies::Netscape');
      } # end of WIN32_NETSCAPE block
    # At this point, $oReal contains Netscape cookies (or undef).
    if (ref($oReal))
      {
      return $oReal if ! wantarray;
      push @aoRet, $oReal;
      } # if found Netscape cookies
      # If wantarray, or the previous cookie searches failed, go on and
    # look for FireFox cookies:
 WIN32_FIREFOX:
      {
      $oReal = undef;
      my $sProfileDir = "$ENV{APPDATA}/Mozilla/Firefox/Profiles";
      if (! opendir (DIR, $sProfileDir))
        {
        _add_error qq{ EEE Can't open Mozilla profile directory ( $sProfileDir ): $! };
        last WIN32_FIREFOX;
        } # if
      my $bMozFound;
      while ( my $test = readdir( DIR ) )
        {
        if ( -d "$sProfileDir/$test" && -f "$sProfileDir/$test/cookies.txt" )
          {
          $bMozFound = 1;
          my $sFnameCookies = "$sProfileDir/$test/cookies.txt";
          _get_cookies($sFnameCookies, 'HTTP::Cookies::Mozilla');
          } # if
        } # while
      closedir DIR or warn;
      if ( ! $bMozFound )
        {
        _add_error qq{ EEE No Mozilla cookie files found under $sProfileDir\\* }
        } # if
      } # end of WIN32_FIREFOX block
    # At this point, $oReal contains Netscape cookies (or undef):
    if (ref($oReal))
      {
      return $oReal if ! wantarray;
      push @aoRet, $oReal;
      } # if found Mozilla cookies
    # No more places to look, fall through and return what we've
    # found.
    } # if MSWin32
  elsif (
         ($^O =~ m!solaris!i)
         ||
         ($^O =~ m!linux!i)
        )
    {
    # Unix-like operating systems.
    $oReal = undef;
 UNIX_NETSCAPE4:
      {
      ; my $sFname = catfile(home(), '.netscape', 'cookies')
      ; print STDERR " + try $sFname...\n" if DEBUG_NEW
      ; _get_cookies($sFname, 'HTTP::Cookies::Netscape')
      ; last UNIX_NETSCAPE4 unless ref($oReal)
      ; push @aoRet, $oReal
      } # end of UNIX_NETSCAPE4 block
    # At this point, $oReal contains Netscape 7 cookies (or undef).
    ; if (ref($oReal))
      {
      ; return $oReal if ! wantarray
      ; push @aoRet, $oReal
      } # if found any cookies
 UNIX_NETSCAPE7:
      {
      ;
      } # end of UNIX_NETSCAPE7 block
    # At this point, $oReal contains Netscape 7 cookies (or undef).
    ; if (ref($oReal))
      {
      ; return $oReal if ! wantarray
      ; push @aoRet, $oReal
      } # if found any cookies
 UNIX_MOZILLA:
      {
      ; eval q{use HTTP::Cookies::Mozilla}
      ; my $sAppregFname = catfile(home(), '.mozilla', 'appreg')
      # ; print STDERR " + try to read appreg ==$sAppregFname==\n"
      ; if (! -f $sAppregFname)
        {
        ; _add_error qq{ EEE Mozilla file $sAppregFname does not exist\n};
        ; last UNIX_MOZILLA
        } # if
      ; my $sAppreg
      ; eval { $sAppreg = read_file($sAppregFname, binmode => ':raw') }
      ; $sAppreg ||= '';
      ; my ($sDir) = ($sAppreg =~ m!(.mozilla/.+?\.slt)\b!)
      # ; print STDERR " + found slt ==$sDir==\n"
      ; my $sFname = catfile(home(), $sDir, 'cookies.txt')
      # ; print STDERR " + try to read cookies ==$sFname==\n"
      ; _get_cookies($sFname, 'HTTP::Cookies::Mozilla')
      } # end of UNIX_MOZILLA block
    # At this point, $oReal contains Mozilla cookies (or undef).
    # ; print STDERR " +   After mozilla cookie check, oReal is ==$oReal==\n"
    ; if (ref($oReal))
      {
      ; return $oReal if ! wantarray
      # ; print STDERR " +   wantarray, keep looking\n"
      ; push @aoRet, $oReal
      } # if found Mozilla cookies
    } # if Unix
  else
    {
    # Future expansion: implement Netscape / other OS combinations
    }
  return wantarray ? @aoRet : $oReal;
  } # new

=item errors

If anything went wrong while finding cookies,
errors() will return a list of string(s) describing the error(s).

=cut

sub errors
  {
  return @asError;
  } # errors

sub _get_cookies
  {
  # Required arg1 = cookies filename:
  my $sFnameCookies = shift;
  # Required arg2 = cookies object type:
  my $sClass = shift;
  my $rcCallback = ($sClass =~ m!Microsoft!) ? \&_callback_msie
                 : ($sClass =~ m!Netscape!)  ? \&_callback_mozilla
                 : ($sClass =~ m!Mozilla!)   ? \&_callback_mozilla
                 :                             \&_callback_mozilla;
  # Our return value is an object of type HTTP::Cookies.
  print STDERR " DDD _get_cookies($sFnameCookies,$sClass)\n" if DEBUG_GET;
  if (! -f $sFnameCookies)
    {
    _add_error qq{ EEE cookies file $sFnameCookies does not exist\n};
    return undef;
    } # if
  # Because $oReal is a global variable, force creation of a new
  # object into a new variable:
  my $oRealNS = $sClass->new;
  unless (ref $oRealNS)
    {
    _add_error qq{ EEE failed to create an empty $sClass object.\n};
    return undef;
    } # unless
  print STDERR " +   created oRealNS ==$oRealNS==...\n" if DEBUG_GET;
  $oReal = $oRealNS;
  # This is a dummy object that we use to find the appropriate
  # cookies:
  my $oDummy = $sClass->new(
                            File => $sFnameCookies,
                            'delayload' => 1,
                           );
  unless (ref $oDummy)
    {
    _add_error qq{ EEE can not create an empty $sClass object.\n};
    return undef;
    } # unless
  print STDERR " +   created oDummy ==$oDummy==...\n" if DEBUG_GET;
  $oDummy->scan($rcCallback) if ref($oDummy);
  print STDERR " +   return oReal ==$oReal==...\n" if DEBUG_GET;
  return $oReal;
  } # _get_cookies

sub _callback_msie
  {
  my ($version,
      $key, $val,
      $path, $domain, $port, $path_spec,
      $secure, $expires, $discard, $hash) = @_;
  # All we care about at this level is the filename, which is in the
  # $val slot:
  print STDERR " + consider cookie, val==$val==\n" if (DEBUG_NEW);
  return unless ($val =~ m!\@.*$sHostGlobal!i);
  print STDERR " +   matches host ($sHostGlobal)\n" if (1 < DEBUG_NEW);
  return unless ($val =~ m!\\$sUser\@!);
  print STDERR " +   matches user ($sUser)\n" if (1 < DEBUG_NEW);
  # This cookie file matches the user and host.  Add it to the cookies
  # we'll keep:
  $oReal->load_cookie($val);
  } # _callback_msie

sub _callback_mozilla
  {
  # print STDERR " + _callback got a cookie: ", Dumper(\@_);
  # return;
  # my ($version,
  #     $key, $val,
  #     $path, $domain, $port, $path_spec,
  #     $secure, $expires, $discard, $hash) = @_;
  my $sDomain = $_[4];
  print STDERR " +   consider cookie from domain ($sDomain), want host ($sHostGlobal)...\n" if DEBUG_NEW;
  return if (($sHostGlobal ne '') && ($sDomain !~ m!$sHostGlobal!i));
  print STDERR " +     domain ($sDomain) matches host ($sHostGlobal)\n" if DEBUG_NEW;
  $oReal->set_cookie(@_);
  } # _callback_mozilla

1;

__END__

=back

=head1 BUGS

Please notify the author if you find any.

=head1 AUTHOR

Martin Thurn C<mthurn at cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTTP::Cookies, HTTP::Cookies::Microsoft, HTTP::Cookies::Mozilla, HTTP::Cookies::Netscape

=head1 SPECIAL THANKS

To David Gilder, for the FireFox (Mozilla) code additions.
To David Gilder, for the Vista MSIE code additions.

=cut

