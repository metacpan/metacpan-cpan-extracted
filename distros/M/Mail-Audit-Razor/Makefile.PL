unless (eval { $ENV{RAZOR_INSTALLED} or require Razor::Client; 1 }) {
  warn "Mail::Audit::Razor requires the not-on-CPAN Razor::Client\n";
  exit 0;
}

use inc::Module::Install;

name          ('Mail-Audit-Razor');
author        ('Ricardo SIGNES <rjbs@cpan.org>');

license       ('perl');

version_from  ('lib/Mail/Audit/Razor.pm');

requires      ('Mail::Audit'        => 2.217);
requires      ('Razor::Client'      => 0);
requires      ('Razor::Agent'       => 0);
requires      ('Razor::String'      => 0);

WriteAll();
