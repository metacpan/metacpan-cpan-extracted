use strict;
use warnings;
use Test::More;
use Eshu;

sub ph { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple function
{
    my $code = <<'END';
<?php

function greet(string $name): string {
    return "Hello, $name!";
}
END
    is(ph($code), $code, 'PHP: simple function');
}

# 2. if/elseif/else
{
    my $code = <<'END';
<?php

function classify(int $n): string {
    if ($n < 0) {
        return 'negative';
    } elseif ($n === 0) {
        return 'zero';
    } else {
        return 'positive';
    }
}
END
    is(ph($code), $code, 'PHP: if/elseif/else');
}

# 3. class
{
    my $code = <<'END';
<?php

class Animal {
    public function __construct(
    private string $name,
    private string $sound,
    ) {}

    public function speak(): string {
        return "{$this->name} says {$this->sound}";
    }

    public function __toString(): string {
        return "Animal({$this->name})";
    }
}
END
    is(ph($code), $code, 'PHP: class with constructor promotion');
}

# 4. inheritance
{
    my $code = <<'END';
<?php

class Dog extends Animal {
    private array $tricks = [];

    public function __construct(string $name) {
        parent::__construct($name, 'woof');
    }

    public function learn(string $trick): void {
        $this->tricks[] = $trick;
    }

    public function perform(): string {
        if (empty($this->tricks)) {
            return "{$this->getName()} knows no tricks";
        }
        return "{$this->getName()} can: " . implode(', ', $this->tricks);
    }
}
END
    is(ph($code), $code, 'PHP: class inheritance');
}

# 5. interface
{
    my $code = <<'END';
<?php

interface Repository {
    public function findById(int $id): ?object;
    public function findAll(): array;
    public function save(object $entity): void;
    public function delete(int $id): bool;
}

interface Countable {
    public function count(): int;
}
END
    is(ph($code), $code, 'PHP: interfaces');
}

# 6. trait
{
    my $code = <<'END';
<?php

trait Timestamps {
    private ?\DateTimeImmutable $createdAt = null;
    private ?\DateTimeImmutable $updatedAt = null;

    public function touch(): void {
        $now = new \DateTimeImmutable();
        if ($this->createdAt === null) {
            $this->createdAt = $now;
        }
        $this->updatedAt = $now;
    }

    public function getCreatedAt(): ?\DateTimeImmutable {
        return $this->createdAt;
    }
}
END
    is(ph($code), $code, 'PHP: trait');
}

# 7. match expression
{
    my $code = <<'END';
<?php

function describeStatus(int $code): string {
    return match (true) {
        $code >= 500 => 'server error',
        $code >= 400 => 'client error',
        $code >= 300 => 'redirect',
        $code >= 200 => 'success',
        default      => 'informational',
    };
}
END
    is(ph($code), $code, 'PHP: match expression');
}

# 8. enum
{
    my $code = <<'END';
<?php

enum Status: string {
    case Pending   = 'pending';
    case Active    = 'active';
    case Cancelled = 'cancelled';
    case Done      = 'done';

    public function isTerminal(): bool {
        return match ($this) {
            self::Cancelled, self::Done => true,
            default => false,
        };
    }

    public function label(): string {
        return ucfirst($this->value);
    }
}
END
    is(ph($code), $code, 'PHP: backed enum');
}

# 9. arrow function
{
    my $code = <<'END';
<?php

$double  = fn(int $x): int => $x * 2;
$isEven  = fn(int $x): bool => $x % 2 === 0;
$compose = fn(callable $f, callable $g) => fn($x) => $f($g($x));

$numbers    = range(1, 10);
$evenDoubles = array_map($double, array_filter($numbers, $isEven));
END
    is(ph($code), $code, 'PHP: arrow functions');
}

# 10. named arguments
{
    my $code = <<'END';
<?php

function createUser(
string $name,
string $email,
string $role = 'user',
bool   $active = true,
): array {
    return compact('name', 'email', 'role', 'active');
}

$user = createUser(
email: 'alice@example.com',
name: 'Alice',
role: 'admin',
);
END
    is(ph($code), $code, 'PHP: named arguments');
}

# 11. readonly properties
{
    my $code = <<'END';
<?php

class Config {
    public function __construct(
    public readonly string $host    = 'localhost',
    public readonly int    $port    = 8080,
    public readonly bool   $debug   = false,
    public readonly string $version = '1.0.0',
    ) {}

    public function baseUrl(): string {
        return "http://{$this->host}:{$this->port}";
    }
}
END
    is(ph($code), $code, 'PHP: readonly constructor properties');
}

# 12. Fiber
{
    my $code = <<'END';
<?php

$fiber = new Fiber(function (): string {
    $value = Fiber::suspend('first');
    echo "Got: $value\n";
    $value = Fiber::suspend('second');
    echo "Got: $value\n";
    return 'done';
});

$result = $fiber->start();
echo "Fiber yielded: $result\n";
$result = $fiber->resume('hello');
echo "Fiber yielded: $result\n";
$fiber->resume('world');
echo "Fiber returned: " . $fiber->getReturn() . "\n";
END
    is(ph($code), $code, 'PHP: Fiber');
}

# 13. exception handling
{
    my $code = <<'END';
<?php

class HttpException extends \RuntimeException {
    public function __construct(
    string $message,
    public readonly int $statusCode = 500,
    ?\Throwable $previous = null,
    ) {
        parent::__construct($message, $statusCode, $previous);
    }
}

function fetchApi(string $url): array {
    try {
        $response = file_get_contents($url);
        if ($response === false) {
            throw new HttpException("Request failed: $url", 502);
        }
        $data = json_decode($response, true, flags: JSON_THROW_ON_ERROR);
        return $data;
    } catch (\JsonException $e) {
        throw new HttpException("Invalid JSON: " . $e->getMessage(), 502, $e);
    }
}
END
    is(ph($code), $code, 'PHP: custom exception');
}

# 14. generator
{
    my $code = <<'END';
<?php

function fibonacci(): Generator {
    [$a, $b] = [0, 1];
    while (true) {
        yield $a;
        [$a, $b] = [$b, $a + $b];
    }
}

function take(int $n, iterable $seq): array {
    $result = [];
    foreach ($seq as $item) {
        $result[] = $item;
        if (count($result) >= $n) {
            break;
        }
    }
    return $result;
}
END
    is(ph($code), $code, 'PHP: generator function');
}

# 15. array operations
{
    my $code = <<'END';
<?php

function groupBy(array $items, callable $keyFn): array {
    $groups = [];
    foreach ($items as $item) {
        $key = $keyFn($item);
        $groups[$key][] = $item;
    }
    return $groups;
}

function pluck(array $items, string $key): array {
    return array_column($items, $key);
}

function chunk(array $items, int $size): array {
    return array_chunk($items, $size);
}
END
    is(ph($code), $code, 'PHP: array utilities');
}

# 16. PSR-style namespace
{
    my $code = <<'END';
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Psr\Log\LoggerInterface;

class UserService {
    public function __construct(
    private UserRepository  $users,
    private LoggerInterface $logger,
    ) {}

    public function activate(int $id): User {
        $user = $this->users->findOrFail($id);
        $user->activate();
        $this->users->save($user);
        $this->logger->info("User {$id} activated");
        return $user;
    }
}
END
    is(ph($code), $code, 'PHP: PSR namespace and DI');
}

# 17. closure binding
{
    my $code = <<'END';
<?php

class Counter {
    private int $value = 0;
}

$inc = Closure::bind(
function (int $step = 1): void {
    $this->value += $step;
},
new Counter(),
Counter::class,
);

$get = Closure::bind(
fn(): int => $this->value,
new Counter(),
Counter::class,
);
END
    is(ph($code), $code, 'PHP: Closure binding');
}

# 18. static methods and properties
{
    my $code = <<'END';
<?php

class Registry {
    private static array $entries = [];

    public static function register(string $name, mixed $value): void {
        self::$entries[$name] = $value;
    }

    public static function get(string $name): mixed {
        return self::$entries[$name] ?? null;
    }

    public static function has(string $name): bool {
        return array_key_exists($name, self::$entries);
    }

    public static function all(): array {
        return self::$entries;
    }
}
END
    is(ph($code), $code, 'PHP: static registry');
}

# 19. abstract class
{
    my $code = <<'END';
<?php

abstract class Formatter {
    abstract protected function doFormat(mixed $value): string;

    public function format(mixed $value): string {
        return $this->doFormat($value);
    }

    public function formatMany(array $values): array {
        return array_map([$this, 'format'], $values);
    }
}

class JsonFormatter extends Formatter {
    protected function doFormat(mixed $value): string {
        return json_encode($value, JSON_PRETTY_PRINT | JSON_THROW_ON_ERROR);
    }
}
END
    is(ph($code), $code, 'PHP: abstract formatter');
}

# 20. interface + implementation
{
    my $code = <<'END';
<?php

interface Cache {
    public function get(string $key): mixed;
    public function set(string $key, mixed $value, int $ttl = 0): void;
    public function delete(string $key): void;
    public function clear(): void;
}

class ArrayCache implements Cache {
    private array $data    = [];
    private array $expires = [];

    public function get(string $key): mixed {
        if (isset($this->expires[$key]) && time() > $this->expires[$key]) {
            $this->delete($key);
        }
        return $this->data[$key] ?? null;
    }

    public function set(string $key, mixed $value, int $ttl = 0): void {
        $this->data[$key] = $value;
        if ($ttl > 0) {
            $this->expires[$key] = time() + $ttl;
        }
    }

    public function delete(string $key): void {
        unset($this->data[$key], $this->expires[$key]);
    }

    public function clear(): void {
        $this->data    = [];
        $this->expires = [];
    }
}
END
    is(ph($code), $code, 'PHP: Cache interface and implementation');
}

# 21. for/foreach loops
{
    my $code = <<'END';
<?php

function matrix_multiply(array $a, array $b): array {
    $n = count($a);
    $m = count($b[0]);
    $k = count($b);
    $c = array_fill(0, $n, array_fill(0, $m, 0));
    for ($i = 0; $i < $n; $i++) {
        for ($j = 0; $j < $m; $j++) {
            for ($p = 0; $p < $k; $p++) {
                $c[$i][$j] += $a[$i][$p] * $b[$p][$j];
            }
        }
    }
    return $c;
}
END
    is(ph($code), $code, 'PHP: nested for loops');
}

# 22. string functions
{
    my $code = <<'END';
<?php

function slugify(string $text): string {
    $text = mb_strtolower($text, 'UTF-8');
    $text = preg_replace('/[^\pL\d]+/u', '-', $text);
    $text = trim($text, '-');
    return $text;
}

function truncate(string $text, int $length, string $suffix = '...'): string {
    if (mb_strlen($text) <= $length) {
        return $text;
    }
    return mb_substr($text, 0, $length - mb_strlen($suffix)) . $suffix;
}
END
    is(ph($code), $code, 'PHP: string utility functions');
}

# 23. recursive function
{
    my $code = <<'END';
<?php

function flatten(array $arr, int $depth = PHP_INT_MAX): array {
    $result = [];
    foreach ($arr as $item) {
        if (is_array($item) && $depth > 0) {
            array_push($result, ...flatten($item, $depth - 1));
        } else {
            $result[] = $item;
        }
    }
    return $result;
}
END
    is(ph($code), $code, 'PHP: recursive flatten');
}

# 24. variadic function
{
    my $code = <<'END';
<?php

function pipe(mixed $value, callable ...$fns): mixed {
    foreach ($fns as $fn) {
        $value = $fn($value);
    }
    return $value;
}

function compose(callable ...$fns): callable {
    return function (mixed $value) use ($fns): mixed {
        foreach (array_reverse($fns) as $fn) {
            $value = $fn($value);
        }
        return $value;
    };
}
END
    is(ph($code), $code, 'PHP: pipe and compose');
}

# 25. first-class callable syntax
{
    my $code = <<'END';
<?php

$numbers = [3, 1, 4, 1, 5, 9, 2, 6];

$doubled = array_map(fn(int $n) => $n * 2, $numbers);
$evens   = array_filter($numbers, fn(int $n) => $n % 2 === 0);
$total   = array_reduce($numbers, fn(int $carry, int $n) => $carry + $n, 0);

$unique  = array_values(array_unique($numbers));
sort($unique);
END
    is(ph($code), $code, 'PHP: array functions with closures');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
<?php
function factorial(int $n): int {
if ($n <= 1) {
return 1;
}
return $n * factorial($n - 1);
}
END
    my $exp = <<'END';
<?php
function factorial(int $n): int {
    if ($n <= 1) {
        return 1;
    }
    return $n * factorial($n - 1);
}
END
    is(ph($in), $exp, 'PHP: unindented factorial normalised');
}

# 27
{
    my $in = <<'END';
<?php
function binarySearch(array $arr, mixed $target): int {
$lo = 0;
$hi = count($arr) - 1;
while ($lo <= $hi) {
$mid = intdiv($lo + $hi, 2);
if ($arr[$mid] === $target) {
return $mid;
} elseif ($arr[$mid] < $target) {
$lo = $mid + 1;
} else {
$hi = $mid - 1;
}
}
return -1;
}
END
    my $exp = <<'END';
<?php
function binarySearch(array $arr, mixed $target): int {
    $lo = 0;
    $hi = count($arr) - 1;
    while ($lo <= $hi) {
        $mid = intdiv($lo + $hi, 2);
        if ($arr[$mid] === $target) {
            return $mid;
        } elseif ($arr[$mid] < $target) {
            $lo = $mid + 1;
        } else {
            $hi = $mid - 1;
        }
    }
    return -1;
}
END
    is(ph($in), $exp, 'PHP: unindented binary search normalised');
}

# 28
{
    my $in = <<'END';
<?php
class Stack {
private array $items = [];
public function push(mixed $item): void {
$this->items[] = $item;
}
public function pop(): mixed {
if (empty($this->items)) {
throw new \UnderflowException('Stack is empty');
}
return array_pop($this->items);
}
public function isEmpty(): bool {
return empty($this->items);
}
}
END
    my $exp = <<'END';
<?php
class Stack {
    private array $items = [];
    public function push(mixed $item): void {
        $this->items[] = $item;
    }
    public function pop(): mixed {
        if (empty($this->items)) {
            throw new \UnderflowException('Stack is empty');
        }
        return array_pop($this->items);
    }
    public function isEmpty(): bool {
        return empty($this->items);
    }
}
END
    is(ph($in), $exp, 'PHP: unindented Stack class normalised');
}

# 29
{
    my $in = <<'END';
<?php
function quickSort(array $arr): array {
if (count($arr) <= 1) {
return $arr;
}
$pivot = $arr[0];
$left = [];
$right = [];
for ($i = 1; $i < count($arr); $i++) {
if ($arr[$i] <= $pivot) {
$left[] = $arr[$i];
} else {
$right[] = $arr[$i];
}
}
return array_merge(quickSort($left), [$pivot], quickSort($right));
}
END
    my $exp = <<'END';
<?php
function quickSort(array $arr): array {
    if (count($arr) <= 1) {
        return $arr;
    }
    $pivot = $arr[0];
    $left = [];
    $right = [];
    for ($i = 1; $i < count($arr); $i++) {
        if ($arr[$i] <= $pivot) {
            $left[] = $arr[$i];
        } else {
            $right[] = $arr[$i];
        }
    }
    return array_merge(quickSort($left), [$pivot], quickSort($right));
}
END
    is(ph($in), $exp, 'PHP: unindented quicksort normalised');
}

# 30
{
    my $in = <<'END';
<?php
function memoize(callable $fn): Closure {
$cache = [];
return function () use ($fn, &$cache) {
$key = serialize(func_get_args());
if (!array_key_exists($key, $cache)) {
$cache[$key] = $fn(...func_get_args());
}
return $cache[$key];
};
}
END
    my $exp = <<'END';
<?php
function memoize(callable $fn): Closure {
    $cache = [];
    return function () use ($fn, &$cache) {
        $key = serialize(func_get_args());
        if (!array_key_exists($key, $cache)) {
            $cache[$key] = $fn(...func_get_args());
        }
        return $cache[$key];
    };
}
END
    is(ph($in), $exp, 'PHP: unindented memoize normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "<?php\nclass EventDispatcher{\nprivate array \$listeners=[];\npublic function on(string \$event,callable \$fn):void{\n\$this->listeners[\$event][]= \$fn;\n}\npublic function emit(string \$event,mixed ...\$args):void{\nforeach(\$this->listeners[\$event]??[] as \$fn){\n\$fn(...\$args);\n}\n}\n}\n",
    "<?php\nfunction retry(int \$n,callable \$fn,int \$delay=0):mixed{\n\$last=null;\nfor(\$i=0;\$i<\$n;\$i++){\ntry{return \$fn();}\ncatch(\\Throwable \$e){\$last=\$e;\nif(\$delay&&\$i<\$n-1)usleep(\$delay*1000);\n}\n}\nthrow \$last;\n}\n",
    "<?php\nclass Collection{\nprivate function __construct(private array \$items){};\npublic static function of(array \$items):self{return new self(\$items);}\npublic function map(callable \$fn):self{return new self(array_map(\$fn,\$this->items));}\npublic function filter(callable \$fn):self{return new self(array_values(array_filter(\$this->items,\$fn)));}\npublic function reduce(callable \$fn,mixed \$init=null):mixed{return array_reduce(\$this->items,\$fn,\$init);}\npublic function toArray():array{return \$this->items;}\n}\n",
    "<?php\nfunction partition(array \$items,callable \$pred):array{\n[\$yes,\$no]=[[],[]];\nforeach(\$items as \$item){\n\$pred(\$item)?\$yes[]=\$item:\$no[]=\$item;\n}\nreturn[\$yes,\$no];\n}\n",
    "<?php\nfunction deepMerge(array \$base,array ...\$overrides):array{\nforeach(\$overrides as \$override){\nforeach(\$override as \$k=>\$v){\nif(is_array(\$v)&&isset(\$base[\$k])&&is_array(\$base[\$k])){\n\$base[\$k]=deepMerge(\$base[\$k],\$v);\n}else{\n\$base[\$k]=\$v;\n}\n}\n}\nreturn \$base;\n}\n",
    "<?php\nfunction once(callable \$fn):Closure{\n\$called=false;\n\$result=null;\nreturn function() use(\$fn,&\$called,&\$result){\nif(!\$called){\$called=true;\$result=\$fn(...func_get_args());}\nreturn \$result;\n};\n}\n",
    "<?php\nfunction debounce(callable \$fn,float \$delay):Closure{\n\$timer=null;\nreturn function() use(\$fn,\$delay,&\$timer){\nif(\$timer)pcntl_alarm(0);\n// note: in real code use event loop instead of signals\n\$timer=true;\n\$fn(...func_get_args());\n};\n}\n",
    "<?php\nclass TypedList{\nprivate array \$items=[];\npublic function __construct(private string \$type){}\npublic function add(mixed \$item):void{\nif(!(\$item instanceof \$this->type)){\nthrow new \\InvalidArgumentException(\"Expected {\$this->type}\");\n}\n\$this->items[]=\$item;\n}\npublic function getAll():array{return \$this->items;}\n}\n",
    "<?php\nfunction flatMap(array \$arr,callable \$fn):array{\nreturn array_merge(...array_map(\$fn,\$arr));\n}\nfunction zipWith(array \$a,array \$b,callable \$fn):array{\nreturn array_map(\$fn,\$a,\$b);\n}\nfunction takeWhile(array \$arr,callable \$pred):array{\n\$result=[];\nforeach(\$arr as \$item){\nif(!\$pred(\$item))break;\n\$result[]=\$item;\n}\nreturn \$result;\n}\n",
    "<?php\nfunction csv_parse(string \$text):array{\n\$lines=explode(\"\\n\",trim(\$text));\n\$header=str_getcsv(array_shift(\$lines));\n\$rows=[];\nforeach(\$lines as \$line){\nif(trim(\$line)==='')continue;\n\$rows[]=array_combine(\$header,str_getcsv(\$line));\n}\nreturn \$rows;\n}\n",
) {
    my $once = ph($snippet);
    is(ph($once), $once, 'PHP: snippet idempotent');
}

done_testing;
