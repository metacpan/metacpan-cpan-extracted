#!/usr/bin/perl -w

use strict;

use Test::More tests => 33;

# Override the exit function
use base 'Exporter';
our @EXPORT_OK;
BEGIN { 
  @EXPORT_OK = ('exit');
  main->export('CORE::GLOBAL','exit'); 
}

our $last_exitstat;
sub exit
{
  $last_exitstat = $_[0];
}

BEGIN {
  use_ok('Mail::Qmail::Queue::Error',qw(:errcodes :fail :test));
};

# Don't print warnings.
our $lastwarn;
$SIG{__WARN__} = sub { $lastwarn = join("",@_);};

# Test the basic failures
tempfail QQ_EXIT_TIMEOUT,"Timeout error";
is($last_exitstat,QQ_EXIT_TIMEOUT);
like($lastwarn,qr/^Timeout error at t\/10Error\.t/);

permfail QQ_EXIT_REFUSED,"Message refused";
is($last_exitstat,QQ_EXIT_REFUSED);
like($lastwarn,qr/^Message refused at t\/10Error\.t/);

qfail QQ_EXIT_NOMEM,"No memory!!";
is($last_exitstat,QQ_EXIT_NOMEM);
like($lastwarn,qr/^No memory!! at t\/10Error\.t/);

# Do they work with no numeric arg?
tempfail "Temp error";
is($last_exitstat,QQ_EXIT_BUG);
like($lastwarn,qr/^Temp error at t\/10Error\.t/);

permfail "Perm error";
is($last_exitstat,QQ_EXIT_REFUSED);
like($lastwarn,qr/^Perm error at t\/10Error\.t/);

qfail "General Error!!";
is($last_exitstat,QQ_EXIT_BUG);
like($lastwarn,qr/^General Error!! at t\/10Error\.t/);


ok(is_permfail(QQ_EXIT_ADDR_TOO_LONG));
ok(is_permfail(QQ_EXIT_REFUSED));
ok(is_tempfail(QQ_EXIT_NOMEM));
ok(is_tempfail(QQ_EXIT_TIMEOUT));
ok(is_tempfail(QQ_EXIT_WRITEERR));
ok(is_tempfail(QQ_EXIT_READERR));
ok(is_tempfail(QQ_EXIT_BADCONF));
ok(is_tempfail(QQ_EXIT_NETERR));
ok(is_tempfail(QQ_EXIT_BADQHOME));
ok(is_tempfail(QQ_EXIT_BADQUEUEDIR));
ok(is_tempfail(QQ_EXIT_BADQUEUEPID));
ok(is_tempfail(QQ_EXIT_BADQUEUEMESS));
ok(is_tempfail(QQ_EXIT_BADQUEUEINTD));
ok(is_tempfail(QQ_EXIT_BADQUEUETODO));
ok(is_tempfail(QQ_EXIT_TEMPREFUSE));
ok(is_tempfail(QQ_EXIT_CONNTIMEOUT));
ok(is_tempfail(QQ_EXIT_NETREJECT));
ok(is_tempfail(QQ_EXIT_NETFAIL));
ok(is_tempfail(QQ_EXIT_BUG));
ok(is_tempfail(QQ_EXIT_BADENVELOPE));
