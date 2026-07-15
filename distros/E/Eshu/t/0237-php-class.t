use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── interface ────────────────────────────────────────────────────

{
    my $src = <<'END';
interface Countable {
public function count(): int;
}
END
    my $out = p($src);
    like($out, qr/^interface Countable \{$/m,       'interface at depth 0');
    like($out, qr/^    public function count\(\)/m,  'method signature at depth 1');
}

# ── abstract class ───────────────────────────────────────────────

{
    my $src = <<'END';
abstract class Base {
abstract protected function run(): void;
public function start() {
$this->run();
}
}
END
    my $out = p($src);
    like($out, qr/^abstract class Base \{$/m,          'abstract class at depth 0');
    like($out, qr/^    abstract protected function/m,   'abstract method at depth 1');
    like($out, qr/^    public function start\(\)/m,     'concrete method at depth 1');
    like($out, qr/^        \$this->run\(\);$/m,         'method body at depth 2');
}

# ── trait ────────────────────────────────────────────────────────

{
    my $src = <<'END';
trait Greetable {
public function greet(): string {
return "Hello, " . $this->name;
}
}
END
    my $out = p($src);
    like($out, qr/^trait Greetable \{$/m,          'trait at depth 0');
    like($out, qr/^    public function greet/m,    'trait method at depth 1');
    like($out, qr/^        return "Hello, "/m,     'trait method body at depth 2');
}

# ── enum (PHP 8.1) ───────────────────────────────────────────────

{
    my $src = <<'END';
enum Status {
case Active;
case Inactive;
public function label(): string {
return match($this) {
Status::Active => 'Active',
Status::Inactive => 'Inactive',
};
}
}
END
    my $out = p($src);
    like($out, qr/^enum Status \{$/m,             'enum at depth 0');
    like($out, qr/^    case Active;$/m,            'enum case at depth 1');
    like($out, qr/^    public function label/m,    'enum method at depth 1');
    like($out, qr/^        return match/m,          'method body at depth 2');
    like($out, qr/^            Status::Active/m,   'match arm at depth 3');
}

# ── extends + implements ─────────────────────────────────────────

{
    my $src = <<'END';
class Dog extends Animal implements Runnable, Jumpable {
public function run() {
echo "running";
}
}
END
    my $out = p($src);
    like($out, qr/^class Dog extends Animal/m,  'class with extends at depth 0');
    like($out, qr/^    public function run/m,   'method at depth 1');
    like($out, qr/^        echo "running";$/m,  'method body at depth 2');
}

done_testing;
