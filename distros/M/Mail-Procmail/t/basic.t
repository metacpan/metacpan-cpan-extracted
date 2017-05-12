# $Id: basic.t,v 1.2 2003-08-05 11:36:44+02 jv Exp $	-*-perl-*-

use Test::More tests => 5;

use_ok('Mail::Procmail');

-d "t" && chdir "t";

# It is tempting to use DATA, but this seems to give problems on some
# perls on some platforms.
ok(open(FH, "basic.dat"), "basic.dat");

my $m_obj = pm_init ( fh => \*FH, logfile => 'stderr', loglevel => 2 );

ok($m_obj, "pm_init");

my $m_from		    = pm_gethdr("from");
my $m_to		    = pm_gethdr("to");
my $m_subject		    = pm_gethdr("subject");

my $m_header                = $m_obj->head->as_string || '';
my $m_body                  = join("", @{$m_obj->body});
my $m_size		    = length($m_body);
my $m_lines		    = @{$m_obj->body};

# Start logging.
pm_log(3, "Mail from $m_from");
pm_log(3, "To: $m_to");
pm_log(3, "Subject: $m_subject");

is($m_lines, 1, "lines");

ok($m_to =~ /jane/, "To");
