use v5.26;
use Test2::V0;

use File::Temp qw(tempdir);
use JSON::PP ();
use Getopt::Pad::Type;

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
};

subtest 'float' => sub {
	my $float = Getopt::Pad::Type::Float->new;
	is $float->check('3.14'), undef, 'float ok';
	like $float->check('x'), qr/not a number/, 'non-number rejected';
	like $float->check('NaN'), qr/not a finite number/, 'NaN rejected';
	like $float->check('-Inf'), qr/not a finite number/, 'infinity rejected';
};

subtest 'file and dir' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = "$dir/exists.txt";
	open my $fh, '>', $file or die $!;
	close $fh;

	is Getopt::Pad::Type::File->new(mustExist => 1)->check($file), undef, 'existing file ok';
	like Getopt::Pad::Type::File->new(mustExist => 1)->check("$dir/nope"), qr/does not exist/, 'missing file rejected';
	is Getopt::Pad::Type::File->new->check("$dir/nope"), undef, 'missing file ok without mustExist';
	is [Getopt::Pad::Type::File->new(mustExist => 1)->constraintNotes], ['has to exist'], 'constraint note';

	is Getopt::Pad::Type::Dir->new(mustExist => 1)->check($dir), undef, 'existing dir ok';
	like Getopt::Pad::Type::Dir->new(mustExist => 1)->check($file), qr/does not exist/, 'file is not a dir';
};

subtest 'url' => sub {
	my $url = Getopt::Pad::Type::Url->new;
	is $url->check('https://example.com/x'), undef, 'https url';
	is $url->check('ssh://git@host/project.git'), undef, 'ssh url';
	like $url->check('dave@oldserver.example.com:/srv/git/project.git'), qr/is not a URL/, 'scp-like address rejected';
	like $url->check('not a url'), qr/is not a URL/, 'garbage rejected';
	like $url->check("https://example.com/x\n"), qr/is not a URL/, 'trailing newline rejected';
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
};

done_testing;
