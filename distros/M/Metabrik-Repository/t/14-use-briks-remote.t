use Test;
BEGIN { plan(tests => 11) }

ok(sub { eval("use Metabrik::Remote::Ssh"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Tcpdump"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Winexe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Wmi"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Msoffice"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Windows"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Windiff"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Sysmon"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Winsvc"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Sandbox"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Windefend"); $@ ? 0 : 1 }, 1, $@);
