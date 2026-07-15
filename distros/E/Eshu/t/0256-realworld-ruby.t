use strict;
use warnings;
use Test::More;
use Eshu;

sub rb { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple method
{
    my $code = <<'END';
def greet(name)
  "Hello, #{name}!"
end
END
    is(rb($code), $code, 'Ruby: simple method');
}

# 2. if/elsif/else
{
    my $code = <<'END';
def classify(n)
  if n < 0
    "negative"
  elsif n.zero?
    "zero"
  else
    "positive"
  end
end
END
    is(rb($code), $code, 'Ruby: if/elsif/else');
}

# 3. class definition
{
    my $code = <<'END';
class Animal
  attr_reader :name, :sound

  def initialize(name, sound)
    @name  = name
    @sound = sound
  end

  def speak
    "#{@name} says #{@sound}"
  end

  def to_s
    "Animal(#{@name})"
  end
end
END
    is(rb($code), $code, 'Ruby: basic class');
}

# 4. class inheritance
{
    my $code = <<'END';
class Dog < Animal
  attr_reader :tricks

  def initialize(name)
    super(name, "woof")
    @tricks = []
  end

  def learn(trick)
    @tricks << trick
    self
  end

  def perform
    return "#{@name} knows no tricks" if @tricks.empty?
    "#{@name} can: #{@tricks.join(', ')}"
  end
end
END
    is(rb($code), $code, 'Ruby: class inheritance');
}

# 5. module mixin
{
    my $code = <<'END';
module Greetable
  def greet(other)
    "Hello from #{name} to #{other.name}!"
  end

  def farewell(other)
    "Goodbye from #{name} to #{other.name}!"
  end
end

class Person
  include Greetable
  attr_reader :name

  def initialize(name)
    @name = name
  end
end
END
    is(rb($code), $code, 'Ruby: module mixin with include');
}

# 6. Comparable mixin
{
    my $code = <<'END';
class Version
  include Comparable

  attr_reader :major, :minor, :patch

  def initialize(str)
    @major, @minor, @patch = str.split('.').map(&:to_i)
  end

  def <=>(other)
    return major <=> other.major unless major == other.major
    return minor <=> other.minor unless minor == other.minor
    patch <=> other.patch
  end

  def to_s
    "#{major}.#{minor}.#{patch}"
  end
end
END
    is(rb($code), $code, 'Ruby: Comparable mixin');
}

# 7. Enumerable mixin
{
    my $code = <<'END';
class NumberList
  include Enumerable

  def initialize(*nums)
    @nums = nums
  end

  def each(&block)
    @nums.each(&block)
  end

  def sum
    @nums.sum
  end

  def average
    sum.to_f / @nums.size
  end
end
END
    is(rb($code), $code, 'Ruby: Enumerable mixin');
}

# 8. blocks and procs
{
    my $code = <<'END';
def transform(arr, &block)
  arr.map(&block)
end

double  = ->(x) { x * 2 }
squared = proc { |x| x ** 2 }

result1 = transform([1, 2, 3], &double)
result2 = transform([1, 2, 3]) { |x| x + 1 }
END
    is(rb($code), $code, 'Ruby: blocks, procs, lambdas');
}

# 9. Struct
{
    my $code = <<'END';
Point = Struct.new(:x, :y) do
  def distance_to(other)
    Math.sqrt((x - other.x) ** 2 + (y - other.y) ** 2)
  end

  def translate(dx, dy)
    Point.new(x + dx, y + dy)
  end

  def to_s
    "(#{x}, #{y})"
  end
end
END
    is(rb($code), $code, 'Ruby: Struct with methods');
}

# 10. method_missing
{
    my $code = <<'END';
class FlexObject
  def initialize
    @attrs = {}
  end

  def method_missing(name, *args)
    key = name.to_s
    if key.end_with?('=')
      @attrs[key.chomp('=')] = args.first
    elsif @attrs.key?(key)
      @attrs[key]
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    true
  end
end
END
    is(rb($code), $code, 'Ruby: method_missing');
}

# 11. Fiber
{
    my $code = <<'END';
def fibonacci
  Fiber.new do
    a, b = 0, 1
    loop do
      Fiber.yield a
      a, b = b, a + b
    end
  end
end

fib = fibonacci
10.times { print "#{fib.resume} " }
END
    is(rb($code), $code, 'Ruby: Fiber generator');
}

# 12. exception handling
{
    my $code = <<'END';
class AppError < StandardError
  attr_reader :code

  def initialize(message, code: 500)
    super(message)
    @code = code
  end
end

def load_config(path)
  JSON.parse(File.read(path))
rescue Errno::ENOENT
  raise AppError.new("Config not found: #{path}", code: 404)
rescue JSON::ParserError => e
  raise AppError.new("Invalid JSON: #{e.message}", code: 400)
end
END
    is(rb($code), $code, 'Ruby: custom exception');
}

# 13. symbol to proc
{
    my $code = <<'END';
words    = %w[hello world foo bar]
upcased  = words.map(&:upcase)
lengths  = words.map(&:length)
sorted   = words.sort_by(&:length)
filtered = words.select { |w| w.length > 3 }
grouped  = words.group_by { |w| w.length }
END
    is(rb($code), $code, 'Ruby: symbol-to-proc and block methods');
}

# 14. open class / monkey patching
{
    my $code = <<'END';
class Integer
  def factorial
    return 1 if self <= 1
    self * (self - 1).factorial
  end

  def times_do
    i = 0
    while i < self
      yield i
      i += 1
    end
  end
end

class String
  def palindrome?
    stripped = downcase.gsub(/[^a-z0-9]/, '')
    stripped == stripped.reverse
  end
end
END
    is(rb($code), $code, 'Ruby: open class extensions');
}

# 15. begin/rescue/ensure
{
    my $code = <<'END';
def with_connection(url)
  conn = DB.connect(url)
  begin
    yield conn
  rescue DB::Error => e
    conn.rollback
    raise
  ensure
    conn.close
  end
end
END
    is(rb($code), $code, 'Ruby: begin/rescue/ensure');
}

# 16. hash operations
{
    my $code = <<'END';
def transform_hash(h)
  h
  .select { |_k, v| v }
  .transform_values { |v| v.to_s.strip }
  .transform_keys { |k| k.to_s.downcase.to_sym }
  .reject { |_k, v| v.empty? }
end

def deep_merge(a, b)
  a.merge(b) do |_key, va, vb|
    va.is_a?(Hash) && vb.is_a?(Hash) ? deep_merge(va, vb) : vb
  end
end
END
    is(rb($code), $code, 'Ruby: hash transform and deep merge');
}

# 17. Enumerable advanced
{
    my $code = <<'END';
records = [
{ name: 'Alice', score: 95, team: 'A' },
{ name: 'Bob',   score: 87, team: 'B' },
{ name: 'Carol', score: 92, team: 'A' },
{ name: 'Dave',  score: 78, team: 'B' },
]

by_team    = records.group_by { |r| r[:team] }
top_scorer = records.max_by { |r| r[:score] }
avg_score  = records.sum { |r| r[:score] }.to_f / records.size
END
    is(rb($code), $code, 'Ruby: Enumerable group_by/max_by');
}

# 18. frozen string
{
    my $code = <<'END';
# frozen_string_literal: true

module Config
  DEFAULTS = {
    host:    'localhost',
    port:    8080,
    debug:   false,
    timeout: 30,
  }.freeze

  def self.load(overrides = {})
    DEFAULTS.merge(overrides).freeze
  end
end
END
    is(rb($code), $code, 'Ruby: frozen string literal and frozen hash');
}

# 19. protected/private
{
    my $code = <<'END';
class BankAccount
  def initialize(balance)
    @balance = balance
  end

  def >(other)
    balance > other.balance
  end

  def to_s
    "Account($#{@balance})"
  end

  protected

  def balance
    @balance
  end

  private

  def validate!(amount)
    raise ArgumentError, "Amount must be positive" unless amount.positive?
  end
end
END
    is(rb($code), $code, 'Ruby: protected and private methods');
}

# 20. attr_accessor and lazy initialization
{
    my $code = <<'END';
class Config
  attr_accessor :host, :port, :debug

  def initialize
    @host  = 'localhost'
    @port  = 3000
    @debug = false
  end

  def connection_string
    @connection_string ||= "#{host}:#{port}"
  end

  def to_h
    { host: host, port: port, debug: debug }
  end
end
END
    is(rb($code), $code, 'Ruby: attr_accessor and ||= memoization');
}

# 21. case/when
{
    my $code = <<'END';
def describe(value)
  case value
  when Integer   then "integer: #{value}"
  when Float     then "float: #{value}"
  when String    then "string: #{value.inspect}"
  when Array     then "array of #{value.size}"
  when Hash      then "hash with #{value.keys.size} keys"
  when NilClass  then "nil"
  when TrueClass, FalseClass then "boolean: #{value}"
  else "unknown: #{value.class}"
  end
end
END
    is(rb($code), $code, 'Ruby: case/when with types');
}

# 22. tap and then/yield_self
{
    my $code = <<'END';
result = []
.tap { |a| a << 1 }
  .tap { |a| a << 2 }
    .tap { |a| a << 3 }

      value = "hello"
      .then { |s| s.upcase }
      .then { |s| s.reverse }
      .then { |s| "Result: #{s}" }
END
    is(rb($code), $code, 'Ruby: tap and then chaining');
}

# 23. pattern matching (3.x)
{
    my $code = <<'END';
case response
  in { status: 200, body: { users: [*, { id:, name: }, *] } }
  puts "Found user #{id}: #{name}"
  in { status: 404 }
  puts "Not found"
  in { status: (500..) }
  puts "Server error"
else
  puts "Unexpected response"
end
END
    is(rb($code), $code, 'Ruby: pattern matching');
}

# 24. Comparable sort
{
    my $code = <<'END';
people = [
{ name: 'Charlie', age: 25 },
{ name: 'Alice',   age: 30 },
{ name: 'Bob',     age: 25 },
]

sorted = people.sort_by { |p| [p[:age], p[:name]] }
youngest = people.min_by { |p| p[:age] }
END
    is(rb($code), $code, 'Ruby: sort_by with multiple criteria');
}

# 25. class methods and self
{
    my $code = <<'END';
class Parser
  FORMATS = %w[json yaml toml csv].freeze

  def self.for(format)
    raise ArgumentError, "Unknown format: #{format}" unless FORMATS.include?(format)
    const_get("#{format.upcase}Parser").new
  end

  def self.supported_formats
    FORMATS
  end

  def parse(input)
    raise NotImplementedError, "#{self.class}#parse not implemented"
  end
end
END
    is(rb($code), $code, 'Ruby: class methods with self');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
def factorial(n)
if n <= 1
return 1
end
n * factorial(n - 1)
end
END
    my $exp = <<'END';
def factorial(n)
  if n <= 1
    return 1
  end
  n * factorial(n - 1)
end
END
    is(rb($in), $exp, 'Ruby: unindented factorial normalised');
}

# 27
{
    my $in = <<'END';
class Stack
def initialize
@data = []
end
def push(item)
@data.push(item)
self
end
def pop
raise "empty" if @data.empty?
@data.pop
end
def empty?
@data.empty?
end
end
END
    my $exp = <<'END';
class Stack
  def initialize
    @data = []
  end
  def push(item)
    @data.push(item)
    self
  end
  def pop
    raise "empty" if @data.empty?
    @data.pop
  end
  def empty?
    @data.empty?
  end
end
END
    is(rb($in), $exp, 'Ruby: unindented Stack class normalised');
}

# 28
{
    my $in = <<'END';
def binary_search(arr, target)
lo = 0
hi = arr.size - 1
while lo <= hi
mid = (lo + hi) / 2
if arr[mid] == target
return mid
elsif arr[mid] < target
lo = mid + 1
else
hi = mid - 1
end
end
-1
end
END
    my $exp = <<'END';
def binary_search(arr, target)
  lo = 0
  hi = arr.size - 1
  while lo <= hi
    mid = (lo + hi) / 2
    if arr[mid] == target
      return mid
    elsif arr[mid] < target
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  -1
end
END
    is(rb($in), $exp, 'Ruby: unindented binary search normalised');
}

# 29
{
    my $in = <<'END';
module Memoize
def memoize(method_name)
original = instance_method(method_name)
cache = {}
define_method(method_name) do |*args|
cache[args] ||= original.bind(self).call(*args)
end
end
end
END
    my $exp = <<'END';
module Memoize
  def memoize(method_name)
    original = instance_method(method_name)
    cache = {}
    define_method(method_name) do |*args|
      cache[args] ||= original.bind(self).call(*args)
    end
  end
end
END
    is(rb($in), $exp, 'Ruby: unindented Memoize module normalised');
}

# 30
{
    my $in = <<'END';
def deep_clone(obj)
case obj
when Hash
obj.transform_values { |v| deep_clone(v) }
when Array
obj.map { |v| deep_clone(v) }
else
obj.dup rescue obj
end
end
END
    my $exp = <<'END';
def deep_clone(obj)
  case obj
  when Hash
    obj.transform_values { |v| deep_clone(v) }
  when Array
    obj.map { |v| deep_clone(v) }
  else
    obj.dup rescue obj
  end
end
END
    is(rb($in), $exp, 'Ruby: unindented deep_clone normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "def pipe(value, *fns)\nfns.reduce(value) { |v, fn| fn.call(v) }\nend\n",
    "class Singleton\n@\ = nil\ndef self.instance\n@\ ||= new\nend\nprivate_class_method :new\nend\n",
    "module Observable\ndef self.included(base)\nbase.instance_variable_set(:\, {})\nbase.extend(ClassMethods)\nend\nmodule ClassMethods\ndef on(event, &block)\n\[event] ||= []\n\[event] << block\nend\ndef emit(event, *args)\n\.fetch(event, []).each { |cb| cb.call(*args) }\nend\nend\nend\n",
    "[1, 2, 3, 4, 5].each_with_object([]) { |n, acc| acc << n * 2 if n.odd? }\n",
    "def memoize(&block)\ncache = {}\n->(*args) { cache[args] ||= block.call(*args) }\nend\n",
    "words = %w[the quick brown fox]\nwords.each_with_object(Hash.new(0)) { |w, h| h[w.length] += 1 }\n",
    "class Tree\nattr_accessor :value, :children\ndef initialize(value)\n\ = value\n\ = []\nend\ndef each(&block)\nblock.call(value)\nchildren.each { |c| c.each(&block) }\nend\nend\n",
    "result = (1..10)\n.select(&:odd?)\n.map { |n| n ** 2 }\n.reduce(:+)\n",
    "h = { a: 1, b: 2, c: 3 }\nh.each_with_object({}) { |(k, v), acc| acc[v] = k }\n",
    "3.times.flat_map { |i| [i, i * 2] }\n",
) {
    my $once = rb($snippet);
    is(rb($once), $once, 'Ruby: snippet idempotent');
}

done_testing;
