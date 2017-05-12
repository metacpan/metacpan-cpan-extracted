# $Id: linux.t,v 1.4 2005/07/09 14:40:38 Daddy Exp $

use ExtUtils::testlib;
# use LWP::Debug qw( + );  # So we can see more error messages, if any
use Test::More no_plan;

BEGIN { use_ok('Data::Dumper') };
BEGIN { use_ok('HTTP::Cookies::Find') };

use vars qw( $iCount );
use warnings;

SKIP:
  {
  skip 'This is not Linux', 7 if ($^O !~ m!linux!i);

  my $o = new HTTP::Cookies::Find(q{no host in the world matches this});
  &dump_errors;
 SKIP:
    {
    skip 'current user has no Mozilla cookies file', 6 unless (ref($o) eq 'HTTP::Cookies::Mozilla');

    $iCount = 0;
    $o->scan(\&cb_count);
    is($iCount, 0);

    $o = new HTTP::Cookies::Find();
    &dump_errors;
    isa_ok($o, 'HTTP::Cookies::Mozilla');
    $iCount = 0;
    $o->scan(\&cb_count);
    cmp_ok(0, '<', $iCount);
    diag(sprintf(q{You have a total of %d cookies in Mozilla}, $iCount));

    my $sHost = 'google';
    $o = new HTTP::Cookies::Find($sHost);
    &dump_errors;
    ok(ref $o);
    is(ref($o), 'HTTP::Cookies::Mozilla');
    $iCount = 0;
    $o->scan(\&cb_count);
    diag(sprintf(qq{Found %d cookies that match host $sHost}, $iCount));

    if (0)
      {
      diag(q{Here is a list of all the cookies:});
      $o->scan(\&cb_dump);
      } # if
    } # end of SKIP block
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
    diag($sError);
    } # foreach
  } # dump_errors

1;

__END__

