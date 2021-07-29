
use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;

our $VERSION = 1.12;

BEGIN { use_ok('Data::Dumper') };
BEGIN { use_ok('HTTP::Cookies::Find') };

use vars qw( $iCount );

SKIP:
  {
  skip 'This is not Windows', 8 if ($^O !~ m!win32!i);

  diag(q{Using real MSIE info from your system});
  # goto DEBUG_NOW;
  my $o = new HTTP::Cookies::Find(q{no host in the world matches this});
  dump_errors();
  if (ref($o) && $o->isa('HTTP::Cookies::Microsoft'))
    {
    $iCount = 0;
    $o->scan(\&cb_count);
    is($iCount, 0, 'no cookies for impossible host');
    } # if

  $o = new HTTP::Cookies::Find();
  dump_errors();
  if (ref($o) && $o->isa('HTTP::Cookies::Microsoft'))
    {
    # diag(q{The object created is of type }. ref $o);
    $iCount = 0;
    $o->scan(\&cb_count);
    diag(sprintf(q{You have a total of %d cookies in MSIE}, $iCount));
    cmp_ok(0, '<', $iCount, 'found ANY msie cookies');
    } # if

  my $sHost = 'soft';
  $o = new HTTP::Cookies::Find($sHost);
  dump_errors();
  if (ref($o) && $o->isa('HTTP::Cookies::Microsoft'))
    {
    $iCount = 0;
    $o->scan(\&cb_count);
    diag(sprintf(qq{Found %d MSIE cookies that match host $sHost}, $iCount));
    }

  $sHost = qr'yaho+';
  $o = new HTTP::Cookies::Find($sHost);
  dump_errors();
  if (ref($o) && $o->isa('HTTP::Cookies::Microsoft'))
    {
    $iCount = 0;
    $o->scan(\&cb_count);
    diag(sprintf(qq{Found %d MSIE cookies that match host $sHost}, $iCount));
    # cmp_ok(0, '<', $iCount);
    }
  if (0)
    {
    diag(q{Here is a list of all the cookies:});
    $o->scan(\&cb_dump);
    } # if

 DEBUG_NOW:
  # Now call array context.
  $sHost = 'ebay';
  # Trick it into finding our test files:
  $ENV{WINDIR} = './t';
  diag(qq{Using fake Netscape info from directory $ENV{WINDIR}});
  my @ao1 = HTTP::Cookies::Find->new($sHost);
  dump_errors();
  foreach my $o1 (@ao1)
    {
    ok(ref($o1));
    my $sBrowser = ref($o1);
    $sBrowser =~ s!.*::!!;
    $iCount = 0;
    $o1->scan(\&cb_count);
    diag(sprintf(qq{Found %d cookies for $sBrowser\'s browser that match host $sHost}, $iCount));
    } # foreach

  } # end of SKIP block

sub cb_count
  {
  $iCount++;
  } # cb_count

sub cb_dump
  {
  my ($version,
      $key, $val,
      $path, $domain, $port, $path_spec,
      $secure, $expires, $discard, $hash) = @_;
  # port is usually undef:
  $port ||= '';
  print STDERR " + cookie is as follows:\n";
  print STDERR " +   key==$key==\n";
  print STDERR " +   val==$val==\n";
  print STDERR " +   path==$path==\n";
  print STDERR " +   domain==$domain==\n";
  print STDERR " +   port==$port==\n";
  print STDERR " +   path_spec==$path_spec==\n";
  print STDERR " +   secure==$secure==\n";
  print STDERR " +   expires==$expires==\n";
  print STDERR " +   discard==$discard==\n";
  print STDERR " +   hash==", Dumper($hash);
  } # cb_dump

sub dump_errors
  {
  foreach my $sError (HTTP::Cookies::Find::errors)
    {
    # print STDERR $sError;
    diag($sError);
    } # foreach
  } # dump_errors

done_testing();

1;

__END__

