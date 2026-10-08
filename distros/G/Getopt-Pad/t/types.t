use v5.26;
use Test2::V0;

use File::Temp qw(tempdir);
use JSON::PP ();
use Math::BigInt;
use Getopt::Pad::Type;
use Getopt::Pad::Spec;

my $registry = Getopt::Pad::Type::registry();

subtest 'registry resolves names and aliases' => sub {
	is $registry->resolve('s'),      'Getopt::Pad::Type::String', 'short name';
	is $registry->resolve('string'), 'Getopt::Pad::Type::String', 'long name';
	is $registry->resolve('!'),      'Getopt::Pad::Type::Bool',   'symbolic name';
	is $registry->resolve('FILE'),   'Getopt::Pad::Type::File',   'case insensitive';
	like dies { $registry->resolve('nope') }, qr/unknown option type 'nope' \(known:.*string/, 'unknown type dies with known list';
};

subtest 'a type builds itself from spec keys' => sub {
	my %spec = (type => 'dir', mustExist => 1, help => 'Work here');
	my ($type, $typeName) = Getopt::Pad::Type::takeFromSpec(\%spec, 'flag', "option 'work-dir'");
	isa_ok $type, ['Getopt::Pad::Type::Dir'], 'type resolved from the spec';
	is $typeName, 'dir', 'name reported as given';
	ok $type->mustExist, 'SPEC_KEYS reached the constructor';
	is \%spec, { help => 'Work here' }, 'type name and SPEC_KEYS taken out, the rest left alone';

	my %bare = (help => 'x');
	my ($default, $defaultName) = Getopt::Pad::Type::takeFromSpec(\%bare, 'flag', "option 'x'");
	isa_ok $default, ['Getopt::Pad::Type::Flag'], 'default type used when the spec names none';
	is $defaultName, 'flag', 'default name reported';

	like dies { Getopt::Pad::Type::takeFromSpec({ type => 'nope' }, 'flag', "option 'x'") }, qr/unknown option type 'nope'/, 'unknown type dies';
	like dies { Getopt::Pad::Type::takeFromSpec({ type => 'i', min => 10, max => 5 }, 'flag', "option 'workers'") },
		qr/option 'workers': min 10 is larger than max 5/, 'the type checks its SPEC_KEYS for the owner';
};

subtest 'value taking' => sub {
	ok !Getopt::Pad::Type::Flag->new->takesValue,   'flag takes no value';
	ok !Getopt::Pad::Type::Bool->new->takesValue,   'bool takes no value';
	ok !Getopt::Pad::Type::Counter->new->takesValue, 'counter takes no value';
	ok(Getopt::Pad::Type::String->new->takesValue, 'string takes a value');
};

subtest 'bool and counter' => sub {
	my $bool = Getopt::Pad::Type::Bool->new;
	is $bool->check($_), undef, "bool accepts '$_'" foreach ('1', '0', '');
	is $bool->check(JSON::PP::false()), undef, 'bool accepts a JSON boolean';
	is $bool->check('no'), "'no' is not a boolean (use true or false)", 'bool rejects other words';
	is ref($bool->coerce(JSON::PP::false())), '', 'a JSON boolean is stored as a plain scalar';

	my $counter = Getopt::Pad::Type::Counter->new;
	is $counter->check('3'), undef, 'counter accepts a count';
	is $counter->check('lots'), "'lots' is not a count", 'counter rejects words';
};

subtest 'int' => sub {
	my $int = Getopt::Pad::Type::Int->new(min => 1, max => 10);
	is $int->check('5'),   undef,                                   'in range';
	is $int->check('abc'), "'abc' is not an integer",               'non-integer';
	is $int->check('0'),   '0 is smaller than the minimum of 1',    'below min';
	is $int->check('11'),  '11 is larger than the maximum of 10',   'above max';
	is $int->coerce('05'), 5,                                       'coerced to number';
	is $int->check("5\n"), "'5\n' is not an integer",                'trailing newline rejected';
	is $int->check("\x{663}"), "'\x{663}' is not an integer",        'non-ASCII digits rejected';

	# The integer range of this perl, and one past each end.
	my $largest  = Math::BigInt->new(~0);
	my $smallest = Math::BigInt->new(-(~0 >> 1))->bdec;
	my $wide     = Getopt::Pad::Type::Int->new;
	is $wide->check($_), undef, sprintf('%s fits', $_) foreach qw(-0 +007 -007), $largest->bstr, $smallest->bstr;
	like $wide->check($largest->copy->binc->bstr), qr/is too large for an integer/, 'one past the largest integer';
	like $wide->check($smallest->copy->bdec->bstr), qr/is too large for an integer/, 'one past the smallest';
	like $wide->check('9' x 400), qr/is too large for an integer/, 'a value that would read as Inf';

	my $huge = '123456789012345678901234567890';
	my $big  = Getopt::Pad::Type::Int->new(bigint => 1, min => '100000000000000000001');
	is $big->check($huge), undef, 'bigint accepts any size';
	isa_ok $big->coerce('+007'), ['Math::BigInt'], 'and converts to a Math::BigInt';
	is $big->coerce($huge)->bstr, $huge, 'exactly';
	is $big->check('100000000000000000000'), '100000000000000000000 is smaller than the minimum of 100000000000000000001', 'bounds compare exactly';
	like $big->check('1.5'), qr/is not an integer/, 'it still takes integers only';
	is Getopt::Pad::Type::Int->checkSpecKeys(bigint => 1, max => '1e3'), "max must be an integer with bigint, not '1e3'", 'bigint bounds must be integers';
};

subtest 'float' => sub {
	my $float = Getopt::Pad::Type::Float->new;
	is $float->check('3.14'), undef, 'float ok';
	like $float->check('x'), qr/not a number/, 'non-number rejected';
	like $float->check('NaN'), qr/not a finite number/, 'NaN rejected';
	like $float->check('-Inf'), qr/not a finite number/, 'infinity rejected';
	like $float->check('1e999'), qr/'1e999' is not a finite number/, 'a value overflowing to infinity rejected';
};

subtest 'file and dir' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = "$dir/exists.txt";
	open my $fh, '>', $file or die $!;
	close $fh;

	is Getopt::Pad::Type::File->new(mustExist => 1)->check("$dir/nope"), undef, 'check leaves existence to verify';
	is Getopt::Pad::Type::File->new(mustExist => 1)->verify($file), undef, 'existing file ok';
	like Getopt::Pad::Type::File->new(mustExist => 1)->verify("$dir/nope"), qr/^file '.*nope' does not exist$/, 'missing file rejected';
	is Getopt::Pad::Type::File->new->verify("$dir/nope"), undef, 'missing file ok without mustExist';
	is [Getopt::Pad::Type::File->new(mustExist => 1)->constraintNotes], ['has to exist'], 'constraint note';
	like Getopt::Pad::Type::File->new(mustExist => 1)->verify($dir), qr/^'.*' is not a file$/, 'a directory is not a file';

	is Getopt::Pad::Type::Dir->new(mustExist => 1)->verify($dir), undef, 'existing dir ok';
	like Getopt::Pad::Type::Dir->new(mustExist => 1)->verify($file), qr/^'.*exists\.txt' is not a directory$/, 'a file is not a directory';
	like Getopt::Pad::Type::Dir->new(createPathIfMissing => 1)->verify($file), qr/is not a directory$/, 'nor can it be created as one';
};

subtest 'paths created on demand' => sub {
	my $dir = tempdir(CLEANUP => 1);

	my $dirType = Getopt::Pad::Type::Dir->new(createPathIfMissing => 1);
	is $dirType->prepare("$dir/a/b"), undef, 'nested directory created';
	ok -d "$dir/a/b", 'directory exists afterwards';
	is $dirType->prepare($dir), undef, 'an existing directory is left alone';
	open my $blocker, '>', "$dir/blocker" or die $!;
	close $blocker;
	like $dirType->prepare("$dir/blocker/sub"), qr/cannot create directory '.*blocker\/sub': \w/, 'creation failure reported';
	is [$dirType->constraintNotes], ['created if missing'], 'constraint note';

	my $fileType = Getopt::Pad::Type::File->new(createPathIfMissing => 1);
	is $fileType->prepare("$dir/c/d.txt"), undef, 'file created with its parent';
	ok -f "$dir/c/d.txt", 'file exists afterwards';
	like $fileType->prepare("$dir/a"), qr/cannot create file '.*': \w/, 'a directory in the way is reported';
	is Getopt::Pad::Type::File->new->prepare("$dir/untouched"), undef, 'nothing created without the key';
	ok !-e "$dir/untouched", 'path still missing';

	like Getopt::Pad::Type::File->checkSpecKeys(mustExist => 1, createPathIfMissing => 1), qr/mutually exclusive/, 'mustExist and createPathIfMissing exclude each other';
};

subtest 'url' => sub {
	my $url = Getopt::Pad::Type::Url->new;
	is $url->check('https://example.com/x'), undef, 'https url';
	is $url->check('ssh://git@host/project.git'), undef, 'ssh url';
	like $url->check('dave@oldserver.example.com:/srv/git/project.git'), qr/is not a URL/, 'scp-like address rejected';
	like $url->check('not a url'), qr/is not a URL/, 'garbage rejected';
	like $url->check("https://example.com/x\n"), qr/is not a URL/, 'trailing newline rejected';
};

subtest 'date and duration need DateTime::Format::Natural' => sub {
	delete local $INC{'DateTime/Format/Natural.pm'};
	local @INC = (sub { die "not installed\n" if $_[1] eq 'DateTime/Format/Natural.pm'; return }, @INC);
	is Getopt::Pad::Type::Date->checkSpecKeys, "type 'date' requires the DateTime::Format::Natural module", 'date';
	is Getopt::Pad::Type::Duration->checkSpecKeys, "type 'duration' requires the DateTime::Format::Natural module", 'duration';
};

subtest 'date' => sub {
	skip_all('DateTime::Format::Natural is not installed') if !Getopt::Pad::Type::Temporal->isNaturalInstalled;

	my $date = Getopt::Pad::Type::Date->new(timezone => 'UTC');
	is $date->check('tomorrow 3pm'), undef, 'natural language accepted';
	like $date->check('blurb'), qr/'blurb' is not a date/, 'garbage rejected';
	my $coerced = $date->coerce('2026-10-06 14:00');
	isa_ok $coerced, ['DateTime'], 'coerced to a DateTime';
	is "$coerced", '2026-10-06T14:00:00', 'the date given';
	is $coerced->time_zone->name, 'UTC', 'in the timezone of the spec';

	my $spec    = Getopt::Pad::Spec->new(raw => { options => { since => { type => 'date', default => 'yesterday' } } });
	my ($since) = $spec->root->declaredOptions;
	isa_ok $since->default, ['DateTime'], 'the default is coerced';
	is $since->presentedDefault, 'yesterday', 'help and config files show it as the spec wrote it';
	like $spec->helperFor($spec->root, programName => 'demo', width => 100, color => 0)->renderHelp, qr/Default = yesterday$/m, 'in the help output';

	like Getopt::Pad::Type::Date->checkSpecKeys(timezone => 'Nowhere/Bogus'), qr/timezone 'Nowhere\/Bogus' is not a known time zone/, 'unknown timezone';
	is Getopt::Pad::Type::Date->new->timezone, 'local', 'local by default';

	my $originalNew = \&DateTime::TimeZone::new;
	no warnings 'redefine';
	local *DateTime::TimeZone::new = sub { my ($class, %args) = @_; die "Cannot determine local time zone\n" if $args{name} eq 'local'; return $originalNew->(@_) };
	is Getopt::Pad::Type::Date->new->zone->name, 'floating', 'an unknown local zone falls back to floating';
};

subtest 'duration' => sub {
	skip_all('DateTime::Format::Natural is not installed') if !Getopt::Pad::Type::Temporal->isNaturalInstalled;

	my $duration = Getopt::Pad::Type::Duration->new;
	my $minutes  = $duration->coerce('90 minutes');
	isa_ok $minutes, ['DateTime::Duration'], 'coerced to a DateTime::Duration';
	is [$minutes->in_units(qw(minutes nanoseconds))], [90, 0], 'a bare length';
	is [$duration->coerce('for 2 days')->in_units('days')], [2], 'a leading for';
	like $duration->check('1 hour 30 minutes'), qr/'1 hour 30 minutes' is not a duration/, 'one number and unit only';
	like $duration->check('soon'), qr/'soon' is not a duration/, 'garbage rejected';
};

subtest 'custom type registration' => sub {
	package My::Test::Hex {
		use Object::Pad;
		use Getopt::Pad::Type;

		class My::Test::Hex :isa(Getopt::Pad::Type) {
			use constant NAMES => ['hex'];
			method glSuffix() { return '=s' }
			method check($value) { return $value =~ /^[0-9a-f]+$/i ? undef : "'$value' is not hex" }
		}
	}

	Getopt::Pad::Type::registerType('My::Test::Hex');
	is $registry->resolve('hex'), 'My::Test::Hex', 'custom type resolvable';
	is $registry->resolve('hex')->new->check('deadbeef'), undef, 'custom check passes';

	package My::Test::Hex::Rival {
		use Object::Pad;
		use Getopt::Pad::Type;

		class My::Test::Hex::Rival :isa(Getopt::Pad::Type) {
			use constant NAMES => ['hex'];
			method glSuffix() { return '=s' }
		}
	}
	like dies { Getopt::Pad::Type::registerType('My::Test::Hex::Rival') },
		qr/option type name 'hex' is already registered by My::Test::Hex at \S*types\.t line \d+/, 'a taken name is refused, at the registering call';
	ok lives { Getopt::Pad::Type::registerType('My::Test::Hex') }, 'registering the same class again is harmless';
	is $registry->resolve('hex'), 'My::Test::Hex', 'the first class keeps the name';

	package My::Test::Nameless {
		use Object::Pad;
		use Getopt::Pad::Type;

		class My::Test::Nameless :isa(Getopt::Pad::Type) {
			method glSuffix() { return '=s' }
		}
	}
	like dies { Getopt::Pad::Type::registerType('My::Test::Nameless') },
		qr/option type class My::Test::Nameless does not provide a NAMES list/, 'a defined class without NAMES is reported as such, not as a missing file';
};

done_testing;
