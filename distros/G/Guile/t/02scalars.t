use Test;
BEGIN { plan tests => 9 }

use Guile;

# try creating some SCMs explicitely with implicit types
my $ten = new Guile::SCM 10;
ok(Guile::number_p($ten) and not Guile::string_p($ten));
my $ten_str = new Guile::SCM "10";
ok(Guile::string_p($ten_str) and not Guile::number_p($ten_str));
my $pi = new Guile::SCM 3.14;
ok(Guile::real_p($pi) and not Guile::string_p($pi));

# try explicit creations with explicit types
my $five = new Guile::SCM integer => "5";
ok(Guile::number_p($five));
my $fiver = new Guile::SCM real => "5.10";
ok(Guile::real_p($fiver) and $fiver == 5.10);
my $name = new Guile::SCM 'string', "Sam Tregar";
ok(Guile::string_p($name));
ok($name eq 'Sam Tregar');

# try some implicit creations
ok(Guile::number_p(10));
ok(Guile::string_p("sam"));
