use strict;
use warnings;
use Test::More;
use Eshu;

sub pl { Eshu->indent_pl($_[0]) }

# ── already-formatted snippets pass through unchanged ──────────────

# 1. simple sub
{
	my $code = <<'END';
sub greet {
	my ($name) = @_;
	return "Hello, $name!";
}
END
	is(pl($code), $code, 'Perl: simple sub');
}

# 2. sub with multiple returns
{
	my $code = <<'END';
sub divide {
	my ($a, $b) = @_;
	if ($b == 0) {
		die "division by zero\n";
	}
	return $a / $b;
}
END
	is(pl($code), $code, 'Perl: sub with die guard');
}

# 3. package declaration
{
	my $code = <<'END';
package Animal;

sub new {
	my ($class, %args) = @_;
	return bless {
		name  => $args{name},
		sound => $args{sound} // 'silence',
	}, $class;
}

sub speak {
	my ($self) = @_;
	printf "%s says %s\n", $self->{name}, $self->{sound};
}
END
	is(pl($code), $code, 'Perl: package with new and method');
}

# 4. OOP inheritance
{
	my $code = <<'END';
package Dog;
use parent -norequire, 'Animal';

sub new {
	my ($class, %args) = @_;
	$args{sound} = 'woof';
	return $class->SUPER::new(%args);
}

sub fetch {
	my ($self) = @_;
	print $self->{name} . " fetches the ball!\n";
}
END
	is(pl($code), $code, 'Perl: OOP inheritance');
}

# 5. regex with /x modifier
{
	my $code = <<'END';
sub parse_date {
	my ($str) = @_;
	if ($str =~ /
			(\d{4})   # year
			[-\/]
			(\d{1,2}) # month
			[-\/]
			(\d{1,2}) # day
			/x) {
		return ($1, $2, $3);
	}
	return;
}
END
	is(pl($code), $code, 'Perl: regex with /x modifier');
}

# 6. map/grep
{
	my $code = <<'END';
sub process_words {
	my (@words) = @_;
	my @clean  = grep { /\A\w+\z/ } @words;
	my @upper  = map  { uc($_) }    @clean;
	return @upper;
}
END
	is(pl($code), $code, 'Perl: map and grep chain');
}

# 7. hash reference
{
	my $code = <<'END';
sub build_user {
	my (%args) = @_;
	return {
		id       => $args{id},
		name     => $args{name},
		email    => $args{email},
		created  => time(),
	};
}
END
	is(pl($code), $code, 'Perl: hash reference builder');
}

# 8. array reference manipulation
{
	my $code = <<'END';
sub dedupe {
	my ($aref) = @_;
	my %seen;
	return [ grep { !$seen{$_}++ } @$aref ];
}
END
	is(pl($code), $code, 'Perl: dedupe with hash seen');
}

# 9. eval/die exception handling
{
	my $code = <<'END';
sub safe_eval {
	my ($code_ref) = @_;
	my $result = eval { $code_ref->() };
	if (my $err = $@) {
		chomp $err;
		warn "caught: $err\n";
		return;
	}
	return $result;
}
END
	is(pl($code), $code, 'Perl: eval/die exception handling');
}

# 10. Schwartzian transform
{
	my $code = <<'END';
sub sort_by_length {
	my (@words) = @_;
	return map  { $_->[0] }
	sort { $a->[1] <=> $b->[1] }
	map  { [$_, length($_)] }
	@words;
}
END
	is(pl($code), $code, 'Perl: Schwartzian transform');
}

# 11. File::Find callback
{
	my $code = <<'END';
sub find_pl_files {
	my ($dir) = @_;
	my @found;
	File::Find::find(sub {
		return unless -f $_;
		push @found, $File::Find::name if /\.pl\z/;
	}, $dir);
	return @found;
}
END
	is(pl($code), $code, 'Perl: File::Find callback');
}

# 12. dispatch table
{
	my $code = <<'END';
my %CMD = (
	add  => sub { $_[0] + $_[1] },
	sub  => sub { $_[0] - $_[1] },
	mul  => sub { $_[0] * $_[1] },
	div  => sub { $_[1] != 0 ? $_[0] / $_[1] : die "div by zero\n" },
);

sub dispatch {
	my ($op, $a, $b) = @_;
	die "unknown op: $op\n" unless exists $CMD{$op};
	return $CMD{$op}->($a, $b);
}
END
	is(pl($code), $code, 'Perl: dispatch table');
}

# 13. accessor generation
{
	my $code = <<'END';
for my $attr (qw(name age email)) {
	no strict 'refs';
	*{"MyClass::$attr"} = sub {
		my ($self, $val) = @_;
		$self->{$attr} = $val if defined $val;
		return $self->{$attr};
	};
}
END
	is(pl($code), $code, 'Perl: dynamic accessor generation');
}

# 14. complex data structure
{
	my $code = <<'END';
my %config = (
	database => {
		host => 'localhost',
		port => 5432,
		name => 'myapp',
	},
	cache => {
		driver  => 'redis',
		host    => 'localhost',
		port    => 6379,
		timeout => 30,
	},
);
END
	is(pl($code), $code, 'Perl: nested config hash');
}

# 15. string processing pipeline
{
	my $code = <<'END';
sub normalise_text {
	my ($text) = @_;
	$text =~ s/\r\n/\n/g;
	$text =~ s/^\s+|\s+$//g;
	$text =~ s/\s+/ /g;
	$text = lc $text;
	return $text;
}
END
	is(pl($code), $code, 'Perl: text normalisation pipeline');
}

# 16. while/readline pattern
{
	my $code = <<'END';
sub count_lines {
	my ($file) = @_;
	open my $fh, '<', $file or die "open $file: $!\n";
	my $n = 0;
	while (<$fh>) {
		$n++;
	}
	close $fh;
	return $n;
}
END
	is(pl($code), $code, 'Perl: line counter with readline');
}

# 17. DBI query pattern
{
	my $code = <<'END';
sub get_users {
	my ($dbh, $active) = @_;
	my $sql = <<'SQL';
SELECT id, name, email
FROM   users
WHERE  active = ?
ORDER BY name
SQL
	my $sth = $dbh->prepare($sql);
	$sth->execute($active);
	return $sth->fetchall_arrayref({});
}
END
	is(pl($code), $code, 'Perl: DBI query with fetchall_arrayref');
}

# 18. AUTOLOAD
{
	my $code = <<'END';
our $AUTOLOAD;
sub AUTOLOAD {
	my ($self, @args) = @_;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;
	return if $method eq 'DESTROY';
	die "No method '$method' in " . ref($self) . "\n";
}
END
	is(pl($code), $code, 'Perl: AUTOLOAD handler');
}

# 19. BEGIN block
{
	my $code = <<'END';
BEGIN {
	my $version = $ENV{APP_VERSION} || '0.0.0';
	our $VERSION = $version;
}
END
	is(pl($code), $code, 'Perl: BEGIN block');
}

# 20. overloaded operators
{
	my $code = <<'END';
use overload
'+'  => \&add,
'-'  => \&subtract,
'""' => \&stringify,
'==' => \&equal;

sub add {
	my ($self, $other) = @_;
	return MyNum->new($self->{val} + $other->{val});
}
END
	is(pl($code), $code, 'Perl: overloaded operators');
}

# 21. tied scalar
{
	my $code = <<'END';
package TiedLog;

sub TIESCALAR {
	my ($class, $name) = @_;
	return bless { name => $name, value => undef }, $class;
}

sub FETCH {
	my ($self) = @_;
	return $self->{value};
}

sub STORE {
	my ($self, $val) = @_;
	warn "$self->{name} set to $val\n";
	$self->{value} = $val;
}
END
	is(pl($code), $code, 'Perl: tied scalar class');
}

# 22. for/foreach loop
{
	my $code = <<'END';
sub sum_squares {
	my (@nums) = @_;
	my $total = 0;
	for my $n (@nums) {
		$total += $n * $n;
	}
	return $total;
}
END
	is(pl($code), $code, 'Perl: for/foreach sum');
}

# 23. nested loops
{
	my $code = <<'END';
sub multiply_table {
	my ($n) = @_;
	my @table;
	for my $i (1..$n) {
		for my $j (1..$n) {
			$table[$i][$j] = $i * $j;
		}
	}
	return \@table;
}
END
	is(pl($code), $code, 'Perl: nested loops multiplication table');
}

# 24. last/next in loop
{
	my $code = <<'END';
sub first_even {
	my (@nums) = @_;
	for my $n (@nums) {
		next if $n % 2 != 0;
		return $n;
	}
	return;
}
END
	is(pl($code), $code, 'Perl: next/last in loop');
}

# 25. chained method calls (fluent API)
{
	my $code = <<'END';
package Builder;

sub new    { bless {}, shift }
sub name   { my ($s,$v)=@_; $s->{name}  =$v; $s }
sub age    { my ($s,$v)=@_; $s->{age}   =$v; $s }
sub email  { my ($s,$v)=@_; $s->{email} =$v; $s }
sub build  { my ($s)=@_;    return {%$s} }
END
	is(pl($code), $code, 'Perl: fluent builder');
}

# 26. glob-based export
{
	my $code = <<'END';
package Utils;

use Exporter 'import';
our @EXPORT_OK = qw(trim slugify truncate);

sub trim {
	my ($s) = @_;
	$s =~ s/^\s+|\s+$//g;
	return $s;
}
END
	is(pl($code), $code, 'Perl: Exporter-based module');
}

# 27. wantarray
{
	my $code = <<'END';
sub items {
	my @list = (1, 2, 3);
	return wantarray ? @list : scalar @list;
}
END
	is(pl($code), $code, 'Perl: wantarray context check');
}

# 28. local variables
{
	my $code = <<'END';
our $indent = 0;

sub with_indent {
	my ($code_ref) = @_;
	local $indent = $indent + 1;
	return $code_ref->();
}
END
	is(pl($code), $code, 'Perl: local variable for dynamic scope');
}

# 29. qw list
{
	my $code = <<'END';
my @days = qw(
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
	Sunday
);
END
	is(pl($code), $code, 'Perl: multi-line qw list');
}

# 30. complex regex substitution
{
	my $code = <<'END';
sub render_template {
	my ($tmpl, $vars) = @_;
	$tmpl =~ s/\{\{(\w+)\}\}/
		exists $vars->{$1} ? $vars->{$1} : "{{$1}}"
	/ge;
	return $tmpl;
}
END
	is(pl($code), $code, 'Perl: template substitution with /e');
}

# ── normalization tests ────────────────────────────────────────────

# 31
{
	my $in = <<'END';
sub factorial {
my ($n) = @_;
return 1 if $n <= 1;
return $n * factorial($n - 1);
}
END
	my $exp = <<'END';
sub factorial {
	my ($n) = @_;
	return 1 if $n <= 1;
	return $n * factorial($n - 1);
}
END
	is(pl($in), $exp, 'Perl: unindented factorial normalised');
}

# 32
{
	my $in = <<'END';
sub clamp {
my ($v, $lo, $hi) = @_;
if ($v < $lo) {
return $lo;
} elsif ($v > $hi) {
return $hi;
}
return $v;
}
END
	my $exp = <<'END';
sub clamp {
	my ($v, $lo, $hi) = @_;
	if ($v < $lo) {
		return $lo;
	} elsif ($v > $hi) {
		return $hi;
	}
	return $v;
}
END
	is(pl($in), $exp, 'Perl: unindented clamp normalised');
}

# 33
{
	my $in = <<'END';
sub flatten {
my (@nested) = @_;
my @result;
for my $item (@nested) {
if (ref $item eq 'ARRAY') {
push @result, flatten(@$item);
} else {
push @result, $item;
}
}
return @result;
}
END
	my $exp = <<'END';
sub flatten {
	my (@nested) = @_;
	my @result;
	for my $item (@nested) {
		if (ref $item eq 'ARRAY') {
			push @result, flatten(@$item);
		} else {
			push @result, $item;
		}
	}
	return @result;
}
END
	is(pl($in), $exp, 'Perl: unindented flatten normalised');
}

# 34
{
	my $in = <<'END';
sub retry {
my ($n, $code) = @_;
for my $attempt (1..$n) {
my $result = eval { $code->() };
return $result unless $@;
warn "attempt $attempt failed: $@";
}
die "all $n attempts failed\n";
}
END
	my $exp = <<'END';
sub retry {
	my ($n, $code) = @_;
	for my $attempt (1..$n) {
		my $result = eval { $code->() };
		return $result unless $@;
		warn "attempt $attempt failed: $@";
	}
	die "all $n attempts failed\n";
}
END
	is(pl($in), $exp, 'Perl: unindented retry normalised');
}

# 35
{
	my $in = <<'END';
sub group_by {
my ($aref, $key_fn) = @_;
my %groups;
for my $item (@$aref) {
my $k = $key_fn->($item);
push @{$groups{$k}}, $item;
}
return \%groups;
}
END
	my $exp = <<'END';
sub group_by {
	my ($aref, $key_fn) = @_;
	my %groups;
	for my $item (@$aref) {
		my $k = $key_fn->($item);
		push @{$groups{$k}}, $item;
	}
	return \%groups;
}
END
	is(pl($in), $exp, 'Perl: unindented group_by normalised');
}

# 36
{
	my $in = <<'END';
sub memoize {
my ($fn) = @_;
my %cache;
return sub {
my $key = join "\0", @_;
unless (exists $cache{$key}) {
$cache{$key} = $fn->(@_);
}
return $cache{$key};
};
}
END
	my $exp = <<'END';
sub memoize {
	my ($fn) = @_;
	my %cache;
	return sub {
		my $key = join "\0", @_;
		unless (exists $cache{$key}) {
			$cache{$key} = $fn->(@_);
		}
		return $cache{$key};
	};
}
END
	is(pl($in), $exp, 'Perl: unindented memoize normalised');
}

# 37
{
	my $in = <<'END';
sub parse_csv_line {
my ($line) = @_;
chomp $line;
my @fields;
while ($line =~ /("(?:[^"\\]|\\.)*"|[^,]*),?/g) {
my $f = $1;
$f =~ s/^"|"$//g if $f =~ /^"/;
push @fields, $f;
}
return @fields;
}
END
	my $exp = <<'END';
sub parse_csv_line {
	my ($line) = @_;
	chomp $line;
	my @fields;
	while ($line =~ /("(?:[^"\\]|\\.)*"|[^,]*),?/g) {
		my $f = $1;
		$f =~ s/^"|"$//g if $f =~ /^"/;
		push @fields, $f;
	}
	return @fields;
}
END
	is(pl($in), $exp, 'Perl: unindented CSV parser normalised');
}

# 38
{
	my $in = <<'END';
sub deep_clone {
my ($ref) = @_;
if (ref $ref eq 'HASH') {
return { map { $_ => deep_clone($ref->{$_}) } keys %$ref };
} elsif (ref $ref eq 'ARRAY') {
return [ map { deep_clone($_) } @$ref ];
} else {
return $ref;
}
}
END
	my $exp = <<'END';
sub deep_clone {
	my ($ref) = @_;
	if (ref $ref eq 'HASH') {
		return { map { $_ => deep_clone($ref->{$_}) } keys %$ref };
	} elsif (ref $ref eq 'ARRAY') {
		return [ map { deep_clone($_) } @$ref ];
	} else {
		return $ref;
	}
}
END
	is(pl($in), $exp, 'Perl: unindented deep_clone normalised');
}

# 39
{
	my $in = <<'END';
sub zip {
my (@lists) = @_;
my $max = 0;
$max < @$_ && ($max = @$_) for @lists;
return map {
my $i = $_;
[ map { $_->[$i] } @lists ]
} 0..$max-1;
}
END
	my $exp = <<'END';
sub zip {
	my (@lists) = @_;
	my $max = 0;
	$max < @$_ && ($max = @$_) for @lists;
	return map {
		my $i = $_;
		[ map { $_->[$i] } @lists ]
	} 0..$max-1;
}
END
	is(pl($in), $exp, 'Perl: unindented zip normalised');
}

# 40
{
	my $in = <<'END';
sub topsort {
my (%deps) = @_;
my %visited;
my @order;
my $visit;
$visit = sub {
my ($node) = @_;
return if $visited{$node}++;
$visit->($_) for @{$deps{$node}};
push @order, $node;
};
$visit->($_) for sort keys %deps;
return @order;
}
END
	my $exp = <<'END';
sub topsort {
	my (%deps) = @_;
	my %visited;
	my @order;
	my $visit;
	$visit = sub {
		my ($node) = @_;
		return if $visited{$node}++;
		$visit->($_) for @{$deps{$node}};
		push @order, $node;
	};
	$visit->($_) for sort keys %deps;
	return @order;
}
END
	is(pl($in), $exp, 'Perl: unindented topological sort normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

# 41
{
	my $messy = <<'END';
package EventEmitter;
sub new { bless { _listeners => {} }, shift }
sub on { my ($self,$ev,$cb)=@_; push @{$self->{_listeners}{$ev}}, $cb }
sub emit { my ($self,$ev,@args)=@_; $_->(@args) for @{$self->{_listeners}{$ev}//[]} }
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: EventEmitter idempotent');
}

# 42
{
	my $messy = <<'END';
sub pipeline {
my @funcs = @_;
return sub {
my @args = @_;
my $val = shift @args;
for my $f (@funcs) { $val = $f->($val, @args) }
return $val;
};
}
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: pipeline combinator idempotent');
}

# 43
{
	my $messy = <<'END';
package Role::Printable;
sub print_info {
my ($self) = @_;
for my $key (sort keys %$self) {
printf "%-20s %s\n", $key, $self->{$key} // '(undef)';
}
}
package MyClass;
use parent -norequire, 'Role::Printable';
sub new { my ($cls,%a)=@_; bless \%a, $cls }
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: mixin role idempotent');
}

# 44
{
	my $messy = <<'END';
sub chunk {
my ($aref, $size) = @_;
my @chunks;
my @buf;
for my $item (@$aref) {
push @buf, $item;
if (@buf >= $size) { push @chunks, [@buf]; @buf = () }
}
push @chunks, [@buf] if @buf;
return @chunks;
}
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: chunk idempotent');
}

# 45
{
	my $messy = <<'END';
package Cache;
sub new { bless { _data => {}, _ttl => {} }, shift }
sub set { my ($s,$k,$v,$ttl)=@_; $s->{_data}{$k}=$v; $s->{_ttl}{$k}=time+($ttl//60) }
sub get {
my ($s,$k)=@_;
return undef unless exists $s->{_data}{$k};
if (time > $s->{_ttl}{$k}) { delete $s->{_data}{$k}; delete $s->{_ttl}{$k}; return undef }
return $s->{_data}{$k};
}
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: TTL cache idempotent');
}

# 46
{
	my $messy = <<'END';
sub walk_tree {
my ($node, $visitor, $depth) = @_;
$depth //= 0;
$visitor->($node, $depth);
if (ref $node->{children} eq 'ARRAY') {
walk_tree($_, $visitor, $depth + 1) for @{$node->{children}};
}
}
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: tree walker idempotent');
}

# 47
{
	my $messy = <<'END';
use Getopt::Long;
my %opts = (verbose => 0, output => '-');
GetOptions(\%opts,
'verbose|v!',
'output|o=s',
'format|f=s',
) or die "Usage: $0 [--verbose] [--output FILE] [--format FORMAT]\n";
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: Getopt::Long idempotent');
}

# 48
{
	my $messy = <<'END';
sub make_validator {
my (%rules) = @_;
return sub {
my (%data) = @_;
my @errors;
for my $field (keys %rules) {
my $check = $rules{$field};
push @errors, "$field: " . $check->($data{$field}) if !$check->($data{$field});
}
return @errors ? (0, \@errors) : (1, undef);
};
}
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: validator factory idempotent');
}

# 49
{
	my $messy = <<'END';
sub reduce {
my ($fn, $init, @list) = @_;
my $acc = $init;
for my $item (@list) {
$acc = $fn->($acc, $item);
}
return $acc;
}
sub any { my ($fn,@l)=@_; return !!grep { $fn->($_) } @l }
sub all { my ($fn,@l)=@_; return !grep { !$fn->($_) } @l }
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: higher-order functions idempotent');
}

# 50
{
	my $messy = <<'END';
package Observable;
sub new { bless { _subs => [] }, shift }
sub subscribe { my ($s,$fn)=@_; push @{$s->{_subs}}, $fn; return sub { $s->{_subs} = [grep { $_ != $fn } @{$s->{_subs}}] } }
sub next { my ($s,$v)=@_; $_->($v) for @{$s->{_subs}} }
sub map { my ($s,$fn)=@_; my $out=Observable->new; $s->subscribe(sub { $out->next($fn->($_[0])) }); $out }
END
	my $once = pl($messy);
	is(pl($once), $once, 'Perl: Observable pattern idempotent');
}

done_testing;
