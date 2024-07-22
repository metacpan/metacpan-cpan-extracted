#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }

    if ($] < 5.005) {
	print "1..0 # skip: test works only with perl 5.005 or better\n";
	exit;
    }
}

my $yaml_mod_tests;
BEGIN {
    $yaml_mod_tests = 38;
    plan tests => 2 + $yaml_mod_tests + 60;
}

BEGIN {
    use_ok('Kwalify', 'validate');
}

my @w;
$SIG{__WARN__} = sub { push @w, @_ };

use_ok('Schema::Kwalify');

my $use_yaml_module;
for my $mod (qw(YAML::XS YAML::PP)) { # YAML::Syck currently does not work --- https://github.com/toddr/YAML-Syck/issues/52
    if (eval qq{ require $mod; 1 }) {
	if ($mod eq 'YAML::PP') {
	    no strict 'refs';
	    *YAML_Load = sub {
		YAML::PP->new(cyclic_refs => 'allow')->load_string($_[0]);
	    };
	} else {
	    no strict 'refs';
	    *YAML_Load = \&{$mod . '::Load'};
	}
	$use_yaml_module = $mod;
	last;
    }
}

sub is_valid_yaml {
    my($schema, $document, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    ok(validate(YAML_Load($schema), YAML_Load($document)), $testname);
}

sub is_invalid_yaml {
    my($schema, $document, $errors, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    ok(!eval { validate(YAML_Load($schema), YAML_Load($document)) }, $testname);
    for my $error (@$errors) {
	if (UNIVERSAL::isa($error, 'HASH')) {
	    my($pattern, $testname) = @{$error}{qw(pattern testname)};
	    like($@, $pattern, $testname);
	} else {
	    like($@, $error);
	}
    }
}

SKIP: {
    skip("Need a YAML loading module for tests", $yaml_mod_tests)
	if !$use_yaml_module;

    my $schema01 = <<'EOF';
type:   seq
sequence:
  - type:   str
EOF
    my $document01a = <<'EOF';
- foo
- bar
- baz
EOF
    is_valid_yaml($schema01, $document01a, "sequence of str");

    my $schema01b = <<'EOF';
type:   seq
sequence: [{}]
EOF
    is_valid_yaml($schema01b, $document01a, "sequence with default type (str)");

    my $document01b = <<'EOF';
- foo
- 123
- baz
EOF

    is_invalid_yaml($schema01,$document01b, 
		    [qr{\Q[/1] Non-valid data '123', expected a str}],
		    "Non valid data, int in sequence of str");
    
    my $schema02 = <<'EOF';
type:       map
mapping:
  name:
    type:      str
    required:  yes
  email:
    type:      str
    pattern:   /@/
  age:
    type:      int
  birth:
    type:      date
EOF

    my $document02a = <<'EOF';
name:   foo
email:  foo@mail.com
age:    20
birth:  1985-01-01
EOF
    is_valid_yaml($schema02, $document02a, "mapping");

    my $document02b = <<'EOF';
name:   foo
email:  foo(at)mail.com
age:    twenty
birth:  Jun 01, 1985
EOF
    is_invalid_yaml($schema02, $document02b,
		    [qr{\Q[/birth] Non-valid data 'Jun 01, 1985', expected a date (YYYY-MM-DD)},
		     qr{\Q[/age] Non-valid data 'twenty', expected an int},
		     qr{\Q[/email] Non-valid data 'foo(at)mail.com' does not match /@/},
		    ],
		    "invalid mapping");

    my $schema03 = <<'EOF';
type:      seq
sequence:
  - type:      map
    mapping:
      name:
        type:      str
        required:  true
      email:
        type:      str
EOF
    my $document03a = <<'EOF';
- name:   foo
  email:  foo@mail.com
- name:   bar
  email:  bar@mail.net
- name:   baz
  email:  baz@mail.org
EOF
    is_valid_yaml($schema03, $document03a, "sequence of mapping");
    my $document03b = <<'EOF';
- name:   foo
  email:  foo@mail.com
- naem:   bar
  email:  bar@mail.net
- name:   baz
  mail:   baz@mail.org
EOF
    is_invalid_yaml($schema03, $document03b,
		    [qr{\Q[/1] Expected required key 'name'},
		     qr{\Q[/1/naem] Unexpected key 'naem'},
		     qr{\Q[/2/mail] Unexpected key 'mail'},
		    ]);

    my $schema04 = <<'EOF';
type:      map
mapping:
  company:
    type:      str
    required:  yes
  email:
    type:      str
  employees:
    type:      seq
    sequence:
      - type:    map
        mapping:
          code:
            type:      int
            required:  yes
          name:
            type:      str
            required:  yes
          email:
            type:      str
EOF
    my $document04a = <<'EOF';
company:    Kuwata lab.
email:      webmaster@kuwata-lab.com
employees:
  - code:   101
    name:   foo
    email:  foo@kuwata-lab.com
  - code:   102
    name:   bar
    email:  bar@kuwata-lab.com
EOF
    is_valid_yaml($schema04, $document04a, "mapping of sequence");
    my $document04b = <<'EOF';
company:    Kuwata Lab.
email:      webmaster@kuwata-lab.com
employees:
  - code:   A101
    name:   foo
    email:  foo@kuwata-lab.com
  - code:   102
    name:   bar
    mail:   bar@kuwata-lab.com
EOF
    is_invalid_yaml($schema04, $document04b,
		    [qr{\Q[/employees/0/code] Non-valid data 'A101', expected an int},
		     qr{\Q[/employees/1/mail] Unexpected key 'mail'},
		    ]);

    my $schema05 = <<'EOF';
type:      seq                                # new rule
sequence:
  -
    type:      map                            # new rule
    mapping:
      name:
        type:       str                       # new rule
        required:   yes
      email:
        type:       str                       # new rule
        required:   yes
        pattern:    /@/
      password:
        type:       text                      # new rule
        length:     { max: 16, min: 8 }
      age:
        type:       int                       # new rule
        range:      { max: 30, min: 18 }
        # or assert: 18 <= val && val <= 30
      blood:
        type:       str                       # new rule
        enum:
          - A
          - B
          - O
          - AB
      birth:
        type:       date                      # new rule
      memo:
        type:       any                       # new rule
EOF
    my $document05a = <<'EOF';
- name:     foo
  email:    foo@mail.com
  password: xxx123456
  age:      20
  blood:    A
  birth:    1985-01-01
- name:     bar
  email:    bar@mail.net
  age:      25
  blood:    AB
  birth:    1980-01-01
EOF
    is_valid_yaml($schema05, $document05a, "Many rules");
    my $document05b = <<'EOF';
- name:     foo
  email:    foo(at)mail.com
  password: xxx123
  age:      twenty
  blood:    a
  birth:    1985-01-01
- given-name:  bar
  family-name: Bar
  email:    bar@mail.net
  age:      15
  blood:    AB
  birth:    1980/01/01
EOF
    is_invalid_yaml($schema05, $document05b,
		    [
		     qr{\Q[/0/blood] 'a': invalid blood value},
		     qr{\Q[/0/email] Non-valid data 'foo(at)mail.com' does not match /@/},
		     qr{\Q[/0/password] 'xxx123' is too short (length 6 < min 8)},
		     qr{\Q[/0/age] Non-valid data 'twenty', expected an int},
		     qr{\Q[/0/age] 'twenty' is too small (< min 18)},
		     qr{\Q[/1/birth] Non-valid data '1980/01/01', expected a date (YYYY-MM-DD)},
		     qr{\Q[/1] Expected required key 'name'},
		     qr{\Q[/1/age] '15' is too small (< min 18)},
		     qr{\Q[/1/given-name] Unexpected key 'given-name'},
		     qr{\Q[/1/family-name] Unexpected key 'family-name'},
		    ]);

    my $schema06 = <<'EOF';
type: seq
sequence:
  - type:     map
    required: yes
    mapping:
      name:
        type:     str
        required: yes
        unique:   yes
      email:
        type:     str
      groups:
        type:     seq
        sequence:
          - type: str
            unique:   yes
EOF
    my $document06a = <<'EOF';
- name:   foo
  email:  admin@mail.com
  groups:
    - users
    - foo
    - admin
- name:   bar
  email:  admin@mail.com
  groups:
    - users
    - admin
- name:   baz
  email:  baz@mail.com
  groups:
    - users
EOF
    is_valid_yaml($schema06, $document06a, "unique");
    my $document06b = <<'EOF';
- name:   foo
  email:  admin@mail.com
  groups:
    - foo
    - users
    - admin
    - foo
- name:   bar
  email:  admin@mail.com
  groups:
    - admin
    - users
- name:   bar
  email:  baz@mail.com
  groups:
    - users
EOF
    is_invalid_yaml($schema06, $document06b,
		    [qr{\Q[/0/groups/3] 'foo' is already used at '/0/groups/0'},
		     qr{\Q[/2/name] 'bar' is already used at '/1/name'},
		    ]);

    # testcase for RT #48800
    my $document_unique = <<'EOF';
- name:   foo
- name:   bar
- name:   barf
- name:   bar
EOF
    is_invalid_yaml($schema06, $document_unique,
		    [qr{\Q[/3/name] 'bar' is already used at '/1/name'},
		    ]);

    # Recursive mappings:
    my $recursive_schema = <<'EOF';
name:      MAIN
type:      map
required:  yes
mapping:   &main-rule
  "type":
    type:      str
    enum:
      - map
      - str
  "mapping":
    name:      MAPPING
    type:      map
    mapping:
      =:
        type:      map
        mapping:   *main-rule
        name:      MAIN
        #required:  yes
EOF
    my $non_recursive_document = <<'EOF';
type: map
mapping:
  recursive_hash:
    type: map
    mapping:
      bla:
        type: str
      foo:
        type: str
  another_key:
    type: str
EOF
    my $recursive_maps = <<'EOF';
type: map
mapping:
  recursive_hash: &recursive
    type: map
    mapping:
      bla:
        type: str
      foo:
        type: str
      bar: *recursive
  another_key:
    type: str
EOF

    is_valid_yaml($recursive_schema, $non_recursive_document, "valid data against schema with recursive rules (no endless loop)");
    is_valid_yaml($recursive_schema, $recursive_maps, "valid recursive data against schema with recursive rules (no endless loop)");
}

{
    my $schema06_pl =
	{
	 'sequence' => [
			{
			 'mapping' => {
				       'email' => {
						   'type' => 'str'
						  },
				       'groups' => {
						    'sequence' => [
								   {
								    'unique' => 'yes',
								    'type' => 'str'
								   }
								  ],
						    'type' => 'seq'
						   },
				       'name' => {
						  'unique' => 'yes',
						  'required' => 'yes',
						  'type' => 'str'
						 }
				      },
			 'required' => 'yes',
			 'type' => 'map'
			}
		       ],
	 'type' => 'seq'
	};

    my $document06a_pl =
	[
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'users',
		       'foo',
		       'admin'
		      ],
	  'name' => 'foo'
	 },
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'users',
		       'admin'
		      ],
	  'name' => 'bar'
	 },
	 {
	  'email' => 'baz@mail.com',
	  'groups' => [
		       'users'
		      ],
	  'name' => 'baz'
	 }
	];

    my $document06b_pl =
	[
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'foo',
		       'users',
		       'admin',
		       'foo'
		      ],
	  'name' => 'foo'
	 },
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'admin',
		       'users'
		      ],
	  'name' => 'bar'
	 },
	 {
	  'email' => 'baz@mail.com',
	  'groups' => [
		       'users'
		      ],
	  'name' => 'bar'
	 }
	];

    ok(validate($schema06_pl, $document06a_pl), "valid data against perl schema");
    eval { validate($schema06_pl, $document06b_pl) };
    ok($@, "invalid data against perl schema");
}

{
    # test length/range min/max-ex
    # (no tests in original document)

    my $schema_ex =
	{
	 type => "map",
	 mapping =>
	 {
	  password =>
	  {
	   type => "text",
	   length => { 'max-ex' => 16, 'min-ex' => 8 },
	  },
	  age =>
	  {
	   type => "int",
	   range => { 'max-ex' => 30, 'min-ex' => 18 },
	  },
	 }
	};

    my $document_length_min_ex_pass =
	{ password => "123456789" };
    ok(validate($schema_ex, $document_length_min_ex_pass), "min-ex length pass");

    my $document_length_min_ex_fail =
	{ password => "12345678" };
    eval { validate($schema_ex, $document_length_min_ex_fail) };
    like($@, qr{\Qis too short (length 8 <= min 8)}, "min-ex length fail");

    my $document_length_max_ex_pass =
	{ password => "123456789012345" };
    ok(validate($schema_ex, $document_length_max_ex_pass), "max-ex length pass");

    my $document_length_max_ex_fail =
	{ password => "1234567890123456" };
    eval { validate($schema_ex, $document_length_max_ex_fail) };
    like($@, qr{\Qis too long (length 16 >= max 16)}, "max-ex length fail");

    ######################################################################

    my $document_range_min_ex_pass =
	{ age => 19 };
    ok(validate($schema_ex, $document_range_min_ex_pass), "min-ex range pass");

    my $document_range_min_ex_fail =
	{ age => 18 };
    eval { validate($schema_ex, $document_range_min_ex_fail) };
    like($@, qr{\Qis too small (<= min 18)}, "min-ex range fail");

    my $document_range_max_ex_pass =
	{ age => 29 };
    ok(validate($schema_ex, $document_range_max_ex_pass), "max-ex range pass");

    my $document_range_max_ex_fail =
	{ age => 30 };
    eval { validate($schema_ex, $document_range_max_ex_fail) };
    like($@, qr{\Qis too large (>= max 30)}, "max-ex range fail");
}

{
    # missing length/range max tests
    my $schema =
	{
	 type => "map",
	 mapping =>
	 {
	  password =>
	  {
	   type => "text",
	   length => { 'max' => 16, 'min-ex' => 8 },
	  },
	  age =>
	  {
	   type => "int",
	   range => { 'max' => 16, 'min-ex' => 8 },
	  },
	 }
	};

    my $document_length_max_pass =
	{ password => "1234567890123456" };
    ok(validate($schema, $document_length_max_pass), "max length pass");

    my $document_length_max_fail =
	{ password => "12345678901234567" };
    eval { validate($schema, $document_length_max_fail) };
    like($@, qr{\Qis too long (length 17 > max 16)}, "max length fail");

    my $document_range_max_pass =
	{ age => 16 };
    ok(validate($schema, $document_range_max_pass), "max range pass");

    my $document_range_max_fail =
	{ age => 17 };
    eval { validate($schema, $document_range_max_fail) };
    like($@, qr{\Qis too large (> max 16)}, "max range fail");
}

{
    ok(validate({type=>"text",
		 name=>"A schema name",
		 classname=>"TestClass", # the old now undocumented "classname"
		 desc=>"Just testing the description.\nReally!",
		}, "foo"), "Passing name/classname/desc");
}

{
    ok(validate({type=>"text",
		 name=>"A schema name",
		 class=>"TestClass", # the new "class" (instead of "classname")
		 desc=>"Just testing the description.\nReally!",
		}, "foo"), "Passing name/class/desc");
}

{
    # Some validation tests, negative
    eval { validate({type => "text"}, [qw(a ref is not a text)]) };
    like($@, qr{Non-valid data}, "a ref is not a text");

    eval { validate({type => "text"}, undef) };
    like($@, qr{Non-valid data.*undef}, "undef is not a text");

    eval { validate({type => "str"}, [qw(a ref is not a str)]) };
    like($@, qr{Non-valid data}, "a str is not a text");

    eval { validate({type => "str"}, undef) };
    like($@, qr{Non-valid data.*undef}, "undef is not a str");

    eval { validate({type => "str"}, 1.2) };
    like($@, qr{Non-valid data}, "a number is not a str");

    eval { validate({type => "float"}, "xyz") };
    like($@, qr{Non-valid data}, "a non-float");

    eval { validate({type => "number"}, "xyz") };
    like($@, qr{Non-valid data}, "a non-number");

    eval { validate({type => "bool"}, "fasle") };
    like($@, qr{Non-valid data}, "a non-bool");

    ## Not clear what a "time" is actually...
    #eval { validate({type => "time"}, "123:45:67") };
    #like($@, qr{Non-valid data}, "a non-time");
}

{
    # Some validation tests, positive
    for (0, 1, 'yes', 'no', 'true', 'false') {
	ok validate({type => 'bool'}, $_), "validate '$_' as bool";
    }

    ok validate({type => 'float'}, 3.141592653), 'validate float';
    ok validate({type => 'number'}, 3.141592653), 'validate number';
    ok validate({type => 'time'}, '12:34:56'), 'validate time';
}

{
    # Various schema error conditions

    eval { validate([qw(schema not a hash)], {}) };
    like($@, qr{Schema structure must be a hash reference}, "schema must be hash");

    eval { validate({type=>"unknown"},{}) };
    like($@, qr{Invalid or unimplemented type .*unknown}, "unknown type");

    eval { validate({type=>"text",
		     length => "foo"}, "foo") };
    like($@, qr{length.* must be a hash with keys max and/or min}, "invalid length spec");

    eval { validate({type=>"text",
		     enum=>"not an array"}, "foo") };
    like($@, qr{must be an array}, "invalid enum spec");

    eval { validate({type=>"text",
		     range => "foo"}, "foo") };
    like($@, qr{range.* must be a hash with keys max and/or min}, "invalid range spec");

    eval { validate({type=>"text",
		     unknown_key => "foo"}, "foo") };
    like($@, qr{Unexpected key 'unknown_key' in type specification}, "unknown key in type");

    eval { validate({type=>"int",
		     range=>{foo => 1}}, "foo") };
    like($@, qr{Unexpected key 'foo' in range specification}, "unknown key in range");

    eval { validate({type=>"int",
		     length=>{foo => 1}}, "foo") };
    like($@, qr{Unexpected key 'foo' in length specification}, "unknown key in length");

    eval { validate({type=>"map",
		     mapping=>
		     {foo=>{type=>"text"}}
		    }, []) };
    like($@, qr{Non-valid data .*, expected mapping}, "expected hash in data");

    eval { validate({type=>'seq'}, []) };
    like($@, qr{'sequence' missing with 'seq' type}, 'wrong seq in schema');

    eval { validate({type=>'seq',sequence=>"this is not a sequence"}, []) };
    like($@, qr{Expected array in 'sequence'}, 'wrong seq in schema');

    eval { validate({type=>'seq',sequence=>['one','two']}, []) };
    like($@, qr{Expect exactly one element in sequence}, 'wrong seq in schema');

    eval { validate({type=>'seq',sequence=>[{type => 'any'}]}, 'no array') };
    like($@, qr{Non-valid data .*, expected sequence}, 'wrong data, no sequence');

    eval { validate({type=>'map'}, []) };
    like($@, qr{mapping' missing with 'map' type}, 'wrong map in schema');

    eval { validate({type=>'map',mapping=>"this is not a mapping"}, []) };
    like($@, qr{Expected hash in 'mapping'}, 'wrong map in schema');

    eval { validate({type=>'map',mapping=>{key => {type => 'any' }}}, undef) };
    like($@, qr{Undefined data, expected mapping}, 'wrong data, undefined');

    eval { validate({type=>'map',mapping=>{key => {type => 'any' }}}, 'something else') };
    like($@, qr{Non-valid data .*, expected mapping}, 'wrong data, no mapping');
}

{
    # Schema::Kwalify tests
    my $sk = Schema::Kwalify->new;
    isa_ok($sk, "Schema::Kwalify");
    ok($sk->validate({type=>"text"},"foo"), "Simple Schema::Kwalify validation");
    eval { $sk->validate({type=>"text"},[]) };
    isnt($@, "", "Simple Schema::Kwalify failure");
}

{
    # Test any with additional checks
    my $schema =
	{
	 type => "any",
	 pattern => "CODE",
	};
    ok(validate($schema, "CODE"), "type any with additional check, successful");
    eval {
	validate($schema, "CoDe");
    };
    like($@, qr{Non-valid data 'CoDe' does not match /CODE/}, "type any with additional check, failure");
}

{
    my $schema =
	{
	 type => "any",
	 enum => [1,2,undef],
	};
    ok(validate($schema, 1), "enum with defined value");
    ok(validate($schema, undef), "enum with undefined value");
}

{
    my $schema =
	{
	 type => "any",
	 pattern => '/^(|something)$/',
	};
    ok(validate($schema, 'something'), "legally undefined pattern");
    ok(validate($schema, undef), "legally undefined pattern");
}

SKIP: {
    skip("Don't bother with warnings on old perls without warnings.pm", 1)
	if $] < 5.006;
    is("@w", "", "No warnings expected");
}

__END__
