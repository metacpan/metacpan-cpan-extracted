use strict;
use warnings;
use Test::More tests => 12;
use Eshu;

# Moo-style accessor class
{
    my $in = <<'END';
package Person;
use strict;
use warnings;

my %defaults = (name => 'Unknown', age => 0, email => '');

sub new {
my ($class, %args) = @_;
return bless {
%defaults,
%args,
}, $class;
}

for my $attr (keys %defaults) {
no strict 'refs';
*{"Person::$attr"} = sub {
my ($self, $val) = @_;
$self->{$attr} = $val if @_ > 1;
return $self->{$attr};
};
}

sub to_string {
my ($self) = @_;
return sprintf('%s <%s> age=%d', $self->name, $self->email, $self->age);
}

1;
END
    my $exp = <<'END';
package Person;
use strict;
use warnings;

my %defaults = (name => 'Unknown', age => 0, email => '');

sub new {
	my ($class, %args) = @_;
	return bless {
		%defaults,
		%args,
	}, $class;
}

for my $attr (keys %defaults) {
	no strict 'refs';
	*{"Person::$attr"} = sub {
		my ($self, $val) = @_;
		$self->{$attr} = $val if @_ > 1;
		return $self->{$attr};
	};
}

sub to_string {
	my ($self) = @_;
	return sprintf('%s <%s> age=%d', $self->name, $self->email, $self->age);
}

1;
END
    is(Eshu->indent_pl($in), $exp, 'Perl: Moo-style class with dynamic accessors');
}

# DBI-style database interaction
{
    my $in = <<'END';
sub fetch_users {
my ($dbh, %opts) = @_;
my $limit  = $opts{limit}  // 100;
my $offset = $opts{offset} // 0;

my $sql = <<'SQL';
SELECT id, name, email, created_at
FROM users
WHERE active = 1
ORDER BY created_at DESC
LIMIT ? OFFSET ?
SQL

my $sth = $dbh->prepare($sql);
$sth->execute($limit, $offset);

my @rows;
while (my $row = $sth->fetchrow_hashref) {
push @rows, {
id    => $row->{id},
name  => $row->{name},
email => $row->{email},
};
}
return \@rows;
}
END
    my $exp = <<'END';
sub fetch_users {
	my ($dbh, %opts) = @_;
	my $limit  = $opts{limit}  // 100;
	my $offset = $opts{offset} // 0;

	my $sql = <<'SQL';
SELECT id, name, email, created_at
FROM users
WHERE active = 1
ORDER BY created_at DESC
LIMIT ? OFFSET ?
SQL

	my $sth = $dbh->prepare($sql);
	$sth->execute($limit, $offset);

	my @rows;
	while (my $row = $sth->fetchrow_hashref) {
		push @rows, {
			id    => $row->{id},
			name  => $row->{name},
			email => $row->{email},
		};
	}
	return \@rows;
}
END
    is(Eshu->indent_pl($in), $exp, 'Perl: DBI fetch with heredoc SQL and hashref rows');
}

# Exception handling with nested eval
{
    my $in = <<'END';
sub safe_connect {
my ($dsn, $user, $pass) = @_;
my $dbh;
eval {
local $SIG{ALRM} = sub { die "timeout\n" };
alarm(10);
$dbh = DBI->connect($dsn, $user, $pass, {
RaiseError => 1,
AutoCommit => 1,
});
alarm(0);
};
if ($@) {
alarm(0);
my $err = $@;
chomp $err;
warn "Connection failed: $err\n";
return;
}
return $dbh;
}
END
    my $exp = <<'END';
sub safe_connect {
	my ($dsn, $user, $pass) = @_;
	my $dbh;
	eval {
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm(10);
		$dbh = DBI->connect($dsn, $user, $pass, {
			RaiseError => 1,
			AutoCommit => 1,
		});
		alarm(0);
	};
	if ($@) {
		alarm(0);
		my $err = $@;
		chomp $err;
		warn "Connection failed: $err\n";
		return;
	}
	return $dbh;
}
END
    is(Eshu->indent_pl($in), $exp, 'Perl: eval/die exception handling with local %SIG');
}

# File::Find callback pattern
{
    my $in = <<'END';
use File::Find qw(find);

sub collect_pm_files {
my ($root) = @_;
my @files;
find(
sub {
return unless -f $_ && /\.pm$/;
push @files, $File::Find::name;
},
$root
);
return sort @files;
}
END
    my $exp = <<'END';
use File::Find qw(find);

sub collect_pm_files {
	my ($root) = @_;
	my @files;
	find(
		sub {
			return unless -f $_ && /\.pm$/;
			push @files, $File::Find::name;
		},
		$root
	);
	return sort @files;
}
END
    is(Eshu->indent_pl($in), $exp, 'Perl: File::Find callback with regex filter');
}

# Complex regex with /x modifier
{
    my $in = <<'END';
sub parse_iso8601 {
my ($str) = @_;
my $re = qr/
^
(\d{4})          # year
-(\d{2})         # month
-(\d{2})         # day
(?:
T(\d{2})         # hour
:(\d{2})         # minute
(?::(\d{2}))?    # optional second
(?:Z|([+-]\d{2}:\d{2}))?  # timezone
)?
$/x;
return unless $str =~ $re;
return {
year  => $1, month  => $2, day    => $3,
hour  => $4, minute => $5, second => $6 // 0,
tz    => $7,
};
}
END
    my $exp = <<'END';
sub parse_iso8601 {
	my ($str) = @_;
	my $re = qr/
^
(\d{4})          # year
-(\d{2})         # month
-(\d{2})         # day
(?:
T(\d{2})         # hour
:(\d{2})         # minute
(?::(\d{2}))?    # optional second
(?:Z|([+-]\d{2}:\d{2}))?  # timezone
)?
$/x;
	return unless $str =~ $re;
	return {
		year  => $1, month  => $2, day    => $3,
		hour  => $4, minute => $5, second => $6 // 0,
		tz    => $7,
	};
}
END
    is(Eshu->indent_pl($in), $exp, 'Perl: ISO8601 parser with /x multiline regex');
}

# Role-like mixin pattern
{
    my $in = <<'END';
package Role::Printable;
use strict;
use warnings;
use Scalar::Util qw(blessed);

sub print_self {
my ($self) = @_;
my $class = blessed($self) // ref($self) // 'UNKNOWN';
printf "[%s]\n", $class;
for my $key (sort keys %$self) {
printf "  %-20s = %s\n", $key, $self->{$key} // '(undef)';
}
}

sub to_json {
my ($self) = @_;
my @pairs;
for my $key (sort keys %$self) {
my $val = $self->{$key};
if (!defined $val) {
push @pairs, qq("$key": null);
} elsif ($val =~ /^\d+$/) {
push @pairs, qq("$key": $val);
} else {
$val =~ s/"/\\"/g;
push @pairs, qq("$key": "$val");
}
}
return '{' . join(', ', @pairs) . '}';
}

1;
END
    my $exp = <<'END';
package Role::Printable;
use strict;
use warnings;
use Scalar::Util qw(blessed);

sub print_self {
	my ($self) = @_;
	my $class = blessed($self) // ref($self) // 'UNKNOWN';
	printf "[%s]\n", $class;
	for my $key (sort keys %$self) {
		printf "  %-20s = %s\n", $key, $self->{$key} // '(undef)';
	}
}

sub to_json {
	my ($self) = @_;
	my @pairs;
	for my $key (sort keys %$self) {
		my $val = $self->{$key};
		if (!defined $val) {
			push @pairs, qq("$key": null);
		} elsif ($val =~ /^\d+$/) {
			push @pairs, qq("$key": $val);
		} else {
			$val =~ s/"/\\"/g;
			push @pairs, qq("$key": "$val");
		}
	}
	return '{' . join(', ', @pairs) . '}';
}

1;
END
    is(Eshu->indent_pl($in), $exp, 'Perl: role mixin with nested if/elsif and qq');
}

# Overloaded operators
{
    my $in = <<'END';
package Vector;
use strict;
use warnings;
use overload(
'+' => \&add,
'-' => \&subtract,
'*' => \&scale,
'""' => \&stringify,
);

sub new {
my ($class, $x, $y) = @_;
return bless { x => $x, y => $y }, $class;
}

sub add {
my ($self, $other) = @_;
return Vector->new($self->{x} + $other->{x}, $self->{y} + $other->{y});
}

sub subtract {
my ($self, $other) = @_;
return Vector->new($self->{x} - $other->{x}, $self->{y} - $other->{y});
}

sub scale {
my ($self, $factor, $swap) = @_;
return Vector->new($self->{x} * $factor, $self->{y} * $factor);
}

sub stringify {
my ($self) = @_;
return sprintf('(%g, %g)', $self->{x}, $self->{y});
}

1;
END
    my $exp = <<'END';
package Vector;
use strict;
use warnings;
use overload(
	'+' => \&add,
	'-' => \&subtract,
	'*' => \&scale,
	'""' => \&stringify,
);

sub new {
	my ($class, $x, $y) = @_;
	return bless { x => $x, y => $y }, $class;
}

sub add {
	my ($self, $other) = @_;
	return Vector->new($self->{x} + $other->{x}, $self->{y} + $other->{y});
}

sub subtract {
	my ($self, $other) = @_;
	return Vector->new($self->{x} - $other->{x}, $self->{y} - $other->{y});
}

sub scale {
	my ($self, $factor, $swap) = @_;
	return Vector->new($self->{x} * $factor, $self->{y} * $factor);
}

sub stringify {
	my ($self) = @_;
	return sprintf('(%g, %g)', $self->{x}, $self->{y});
}

1;
END
    is(Eshu->indent_pl($in), $exp, 'Perl: overloaded operator class');
}

# Schwartzian transform and data pipeline
{
    my $in = <<'END';
sub top_words {
my ($text, $n) = @_;
$n //= 10;

my %freq;
$freq{lc $_}++ for split /\W+/, $text;

return [
map  { $_->[0] }
sort { $b->[1] <=> $a->[1] || $a->[0] cmp $b->[0] }
map  { [$_, $freq{$_}] }
keys %freq
][ 0 .. ($n - 1) ];
}
END
    my $exp = <<'END';
sub top_words {
	my ($text, $n) = @_;
	$n //= 10;

	my %freq;
	$freq{lc $_}++ for split /\W+/, $text;

	return [
		map  { $_->[0] }
		sort { $b->[1] <=> $a->[1] || $a->[0] cmp $b->[0] }
		map  { [$_, $freq{$_}] }
		keys %freq
	][ 0 .. ($n - 1) ];
}
END
    is(Eshu->indent_pl($in), $exp, 'Perl: Schwartzian transform pipeline');
}

# BEGIN / END blocks with package-level state
{
    my $in = <<'END';
package Registry;
use strict;
use warnings;

my %registry;

BEGIN {
%registry = ();
}

sub register {
my ($class, $name, $handler) = @_;
die "Already registered: $name\n" if exists $registry{$name};
$registry{$name} = $handler;
}

sub lookup {
my ($class, $name) = @_;
return $registry{$name};
}

END {
%registry = ();
}

1;
END
    my $exp = <<'END';
package Registry;
use strict;
use warnings;

my %registry;

BEGIN {
	%registry = ();
}

sub register {
	my ($class, $name, $handler) = @_;
	die "Already registered: $name\n" if exists $registry{$name};
	$registry{$name} = $handler;
}

sub lookup {
	my ($class, $name) = @_;
	return $registry{$name};
}

END {
	%registry = ();
}

1;
END
    is(Eshu->indent_pl($in), $exp, 'Perl: BEGIN/END blocks with package-level hash');
}

# Tied variable implementation
{
    my $in = <<'END';
package Tie::ReadOnly;
use strict;
use warnings;

sub TIESCALAR {
my ($class, $val) = @_;
return bless \$val, $class;
}

sub FETCH {
my ($self) = @_;
return $$self;
}

sub STORE {
my ($self, $val) = @_;
die "Cannot modify read-only variable\n";
}

sub DESTROY { }

1;
END
    my $exp = <<'END';
package Tie::ReadOnly;
use strict;
use warnings;

sub TIESCALAR {
	my ($class, $val) = @_;
	return bless \$val, $class;
}

sub FETCH {
	my ($self) = @_;
	return $$self;
}

sub STORE {
	my ($self, $val) = @_;
	die "Cannot modify read-only variable\n";
}

sub DESTROY { }

1;
END
    is(Eshu->indent_pl($in), $exp, 'Perl: tied variable TIESCALAR implementation');
}

# Command-line script with Getopt::Long pattern
{
    my $in = <<'END';
#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage   qw(pod2usage);

my %opt = (
verbose => 0,
output  => '-',
format  => 'text',
);

GetOptions(\%opt,
'verbose|v!',
'output|o=s',
'format|f=s',
'help|h',
) or pod2usage(2);

pod2usage(1) if $opt{help};

unless (@ARGV) {
warn "No input files specified\n";
pod2usage(2);
}

for my $file (@ARGV) {
open my $fh, '<', $file or do {
warn "Cannot open $file: $!\n";
next;
};
process($fh, \%opt);
close $fh;
}
END
    my $exp = <<'END';
#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage   qw(pod2usage);

my %opt = (
	verbose => 0,
	output  => '-',
	format  => 'text',
);

GetOptions(\%opt,
	'verbose|v!',
	'output|o=s',
	'format|f=s',
	'help|h',
) or pod2usage(2);

pod2usage(1) if $opt{help};

unless (@ARGV) {
	warn "No input files specified\n";
	pod2usage(2);
}

for my $file (@ARGV) {
	open my $fh, '<', $file or do {
		warn "Cannot open $file: $!\n";
		next;
	};
	process($fh, \%opt);
	close $fh;
}
END
    is(Eshu->indent_pl($in), $exp, 'Perl: CLI script with Getopt::Long and error handling');
}

# Idempotency across all Perl patterns in this file
{
    my @srcs = (
        "package Foo;\nsub new { bless {}, shift }\nsub run {\nmy (\$self) = \@_;\nfor (1..10) {\nif (\$_ % 2) {\nprint \"\$_\\n\";\n}\n}\n}\n1;\n",
        "my \@data = map { \$_ * 2 } grep { \$_ > 0 } -5..5;\n",
        "eval { die \"oops\" };\nif (\$@) {\nwarn \$@;\n}\n",
    );
    my $ok = 1;
    for my $src (@srcs) {
        my $once  = Eshu->indent_pl($src);
        my $twice = Eshu->indent_pl($once);
        $ok = 0 unless $once eq $twice;
    }
    ok($ok, 'Perl: realworld snippets are idempotent');
}
