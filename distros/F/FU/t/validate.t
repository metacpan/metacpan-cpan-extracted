use v5.36;
use Test::More;
use Storable 'dclone';
use experimental 'builtin';
use builtin qw/true false blessed/;

use FU::Validate;


my %validations = (
    hex => { regex => qr/^[0-9a-f]*$/i },
    prefix => sub { my $p = shift; { func => sub { $_[0] =~ /^$p/ } } },
    mybool => { default => 0, func => sub { $_[0] = $_[0]?1:0; 1 } },
    setundef => { func => sub { $_[0] = undef; 1 } },
    defaultsub1 => { default => sub { 2 } },
    defaultsub2 => { default => sub { defined $_[0] } },
    onerrorsub => { onerror => sub { ref $_[1] } },
    collapsews => { trim => 0, func => sub { $_[0] =~ s/\s+/ /g; 1 } },
    neverfails => { onerror => 'err' },
    revnum => { type => 'array', sort => sub($x,$y) { $y <=> $x } },
    uniquelength => { type => 'array', values => { type => 'array' }, unique => sub { scalar @{$_[0]} } },
    person => {
        type => 'hash',
        unknown => 'pass',
        keys => {
            name => {},
            age => { missing => 'ignore' },
            sex => { missing => 'reject', default => 1 }
        }
    },
);


sub t($schema, $input, $output) {
    my $line = (caller)[2];

    my $schema_copy = dclone([$schema])->[0];
    my $input_copy = dclone([$input])->[0];

    my $res = FU::Validate->compile($schema, \%validations)->validate($input);
    #diag explain FU::Validate->compile($schema, \%validations) if $line == 139;
    is_deeply $schema, $schema_copy, "schema modification $line";
    is_deeply $input,  $input_copy,  "input modification $line";
    is_deeply $res, $output, "data ok $line";
}

sub f($schema, $input, $error, @msg) {
    my $line = (caller)[2];

    my $schema_copy = dclone([$schema])->[0];
    my $input_copy = dclone([$input])->[0];

    ok !eval { FU::Validate->compile($schema, \%validations)->validate($input); 1 }, "eval $line";
    is_deeply $schema, $schema_copy, "schema modification $line";
    is_deeply $input,  $input_copy,  "input modification $line";
    delete $@->{longmess};
    is_deeply { $@->%* }, $error, "err $line";
    is_deeply [$@->errors], \@msg, "errmsg $line";
}


# default
t {}, 0, 0;
f {}, '', { validation => 'required' }, 'required value missing';
f {}, undef, { validation => 'required' }, 'required value missing';
t { default => undef }, undef, undef;
t { default => undef }, '', undef;
t { defaultsub1 => 1 }, undef, 2;
t { defaultsub2 => 1 }, undef, '';
t { defaultsub2 => 1 }, '', 1;
t { onerrorsub => 1 }, undef, 'FU::Validate::err';

# trim
t {}, " Va\rl id \n ", 'Val id';
t { trim => 0 }, " Va\rl id \n ", " Va\rl id \n ";
f {}, '  ', { validation => 'required' }, 'required value missing';
t { trim => 0 }, '  ', '  ';

# arrays
f {}, [], { validation => 'type', expected => 'scalar', got => 'array' }, "invalid type, expected 'scalar' but got 'array'";
f { type => 'array' }, 1, { validation => 'type', expected => 'array', got => 'scalar' }, "invalid type, expected 'array' but got 'scalar'";
t { type => 'array' }, [], [];
t { type => 'array' }, [undef,1,2,{}], [undef,1,2,{}];
t { type => 'array', scalar => 1 }, 1, [1];
f { type => 'array', values => {} }, [undef], { validation => 'values', errors => [{ index => 0, validation => 'required' }] }, "[0]: required value missing";
t { type => 'array', values => {} }, [' a '], ['a'];
t { type => 'array', sort => 'str' }, [qw/20 100 3/], [qw/100 20 3/];
t { type => 'array', sort => 'num' }, [qw/20 100 3/], [qw/3 20 100/];
t { revnum => 1 },                    [qw/20 100 3/], [qw/100 20 3/];
t { type => 'array', sort => 'num', unique => 1 }, [qw/3 2 1/], [qw/1 2 3/];
f { type => 'array', sort => 'num', unique => 1 }, [qw/3 2 3/], { validation => 'unique', index_a => 1, value_a => 3, index_b => 2, value_b => 3 }, q{[2] value '"3"' duplicated};
t { type => 'array', unique => 1 }, [qw/3 1 2/], [qw/3 1 2/];
f { type => 'array', unique => 1 }, [qw/3 1 3/], { validation => 'unique', index_a => 0, value_a => 3, index_b => 2, value_b => 3, key => 3 }, q{[2] value '"3"' duplicated};
t { uniquelength => 1 }, [[],[1],[1,2]], [[],[1],[1,2]];
f { uniquelength => 1 }, [[],[1],[2]], { validation => 'unique', index_a => 1, value_a => [1], index_b => 2, value_b => [2], key => 1 }, q{[2] value '[1]' duplicated};
t { type => 'array', setundef => 1 }, [], undef;
t { type => 'array', values => { type => 'any', setundef => 1 } }, [[]], [undef];

# hashes
f { type => 'hash' }, [], { validation => 'type', expected => 'hash', got => 'array' }, "invalid type, expected 'hash' but got 'array'";
f { type => 'hash' }, 'a', { validation => 'type', expected => 'hash', got => 'scalar' }, "invalid type, expected 'hash' but got 'scalar'";
t { type => 'hash' }, {a=>[],b=>undef,c=>{}}, {};
f { type => 'hash', keys => { a=>{} } }, {}, { validation => 'keys', errors => [{ key => 'a', validation => 'required' }] }, '.a: required value missing';
t { type => 'hash', keys => { a=>{missing=>'ignore'} } }, {}, {};
t { type => 'hash', keys => { a=>{default=>undef} } }, {}, {a=>undef};
t { type => 'hash', keys => { a=>{missing=>'create',default=>undef} } }, {}, {a=>undef};
f { type => 'hash', keys => { a=>{missing=>'reject'} } }, {}, {key => 'a', validation => 'missing'}, '.a: required key missing';

t { type => 'hash', keys => { a=>{} } }, {a=>' a '}, {a=>'a'}; # Test against in-place modification
t { type => 'hash', keys => { a=>{} }, unknown => 'remove' }, { a=>1,b=>1 }, { a=>1 };
f { type => 'hash', keys => { a=>{} }, unknown => 'reject' }, { a=>1,b=>1 }, { validation => 'unknown', keys => ['b'], expected => ['a'] }, "unknown key 'b'";
t { type => 'hash', keys => { a=>{} }, unknown => 'pass' }, { a=>1,b=>1 }, { a=>1,b=>1 };
t { type => 'hash', setundef => 1 }, {}, undef;
t { type => 'hash', unknown => 'reject', keys => { a=>{ type => 'any', setundef => 1}} }, {a=>[]}, {a=>undef};

# default validations
f { minlength => 3 }, 'ab', { validation => 'minlength', expected => 3, got => 2 }, "failed validation 'minlength'";
t { minlength => 3 }, 'abc', 'abc';
f { maxlength => 3 }, 'abcd', { validation => 'maxlength', expected => 3, got => 4 }, "failed validation 'maxlength'";
t { maxlength => 3 }, 'abc', 'abc';
t { minlength => 3, maxlength => 3 }, 'abc', 'abc';
f { length => 3 }, 'ab',   { validation => 'length', expected => 3, got => 2 }, "failed validation 'length'";
f { length => 3 }, 'abcd', { validation => 'length', expected => 3, got => 4 }, "failed validation 'length'";
t { length => 3 }, 'abc',  'abc';
t { length => [1,3] }, 'abc',  'abc';
f { length => [1,3] }, 'abcd', { validation => 'length', expected => [1,3], got => 4 }, "failed validation 'length'";
t { type => 'array', length => 0 }, [], [];
f { type => 'array', length => 1 }, [1,2], { validation => 'length', expected => 1, got => 2 }, "failed validation 'length'";
t { type => 'hash', length => 0 }, {}, {};
f { type => 'hash', length => 1, unknown => 'pass' }, {qw/1 a 2 b/}, { validation => 'length', expected => 1, got => 2 }, "failed validation 'length'";
t { type => 'hash', length => 1, keys => {a => {missing=>'ignore'}, b => {missing=>'ignore'}} }, {a=>1}, {a=>1};
t { regex => '^a' }, 'abc', 'abc';  # XXX: Can't use qr// here because t() does dclone(). The 'hex' test covers that case anyway.
f { regex => '^a' }, 'cba', { validation => 'regex', regex => '^a', got => 'cba' }, "failed validation 'regex'";
t { enum => [1,2] }, 1, 1;
t { enum => [1,2] }, 2, 2;
f { enum => [1,2] }, 3, { validation => 'enum', expected => [1,2], got => 3 }, "failed validation 'enum'";
t { enum => 1 }, 1, 1;
f { enum => 1 }, 2, { validation => 'enum', expected => [1], got => 2 }, "failed validation 'enum'";
t { enum => {a=>1,b=>2} }, 'a', 'a';
f { enum => {a=>1,b=>2} }, 'c', { validation => 'enum', expected => ['a','b'], got => 'c' }, "failed validation 'enum'";
t { anybool => 1 }, 1, true;
t { anybool => 1 }, undef, false;
t { anybool => 1 }, '', false;
t { anybool => 1 }, {}, true;
t { anybool => 1 }, [], true;
t { anybool => 1 }, bless({}, 'test'), true;
f { bool => 1 }, 1, { validation => 'bool' }, "failed validation 'bool'";
t { bool => 1 }, \1, true;
my($true, $false) = (1,0);
t { bool => 1 }, bless(\$true, 'boolean'), true;
t { bool => 1 }, bless(\$false, 'boolean'), false;
f { bool => 1 }, bless(\$true, 'test'), { validation => 'bool' }, "failed validation 'bool'";
t { ascii => 1 }, 'ab c', 'ab c';
f { ascii => 1 }, "a\nb", { validation => 'ascii', got => "a\nb" }, "failed validation 'ascii'";

# custom validations
t { hex => 1 }, 'DeadBeef', 'DeadBeef';
f { hex => 1 }, 'x', { validation => 'hex', error => { validation => 'regex', regex => "$validations{hex}{regex}", got => 'x' } }, "validation 'hex': failed validation 'regex'";
t { prefix => 'a' }, 'abc', 'abc';
f { prefix => 'a' }, 'cba', { validation => 'prefix', error => { validation => 'func', result => '' } }, "validation 'prefix': failed validation 'func'";
t { mybool => 1 }, 'abc', 1;
t { mybool => 1 }, undef, 0;
t { mybool => 1 }, '', 0;
t { collapsews => 1 }, " \t\n ", ' ';
t { collapsews => 1 }, '   x  ', ' x ';
t { collapsews => 1, trim => 1 }, '   x  ', 'x';
f { person => 1 }, 1, { validation => 'type', expected => 'hash', got => 'scalar' }, "invalid type, expected 'hash' but got 'scalar'";
t { person => 1, default => 1 }, undef, 1;
f { person => 1 }, { sex => 1 }, { validation => 'person', error => { validation => 'keys', errors => [{ key => 'name', validation => 'required' }] } }, "validation 'person'.name: required value missing";
t { person => 1 }, { sex => undef, name => 'y' }, { sex => 1, name => 'y' };
f { person => 1, keys => {age => {default => \'required'}} }, {name => 'x', sex => 'y'}, { validation => 'keys', errors => [{ key => 'age', validation => 'required' }] }, '.age: required value missing';
t { person => 1, keys => {extra => {}} }, {name => 'x', sex => 'y', extra => 1},  { name => 'x', sex => 'y', extra => 1 };
f { person => 1, keys => {extra => {}} }, {name => 'x', sex => 'y', extra => ''}, { validation => 'keys', errors => [{ key => 'extra', validation => 'required' }] }, '.extra: required value missing';
t { person => 1 }, {name => 'x', sex => 'y', extra => 1}, {name => 'x', sex => 'y', extra => 1};
t { person => 1, unknown => 'remove' }, {name => 'x', sex => 'y', extra => 1}, {name => 'x', sex => 'y'};
t { neverfails => 1, int => 1 }, undef, 'err';
t { neverfails => 1, int => 1 }, 'x', 'err';
t { neverfails => 1, int => 1, onerror => undef }, 'x', undef; # XXX: no way to 'unset' an inherited onerror clause, hmm.

# numbers
sub nerr { ({ validation => 'num', got => $_[0] }, "failed validation 'num'") }
t { num => 1 }, 0, 0;
f { num => 1 }, '-', nerr '-';
f { num => 1 }, '00', nerr '00';
t { num => 1 }, '1', '1';
f { num => 1 }, '1.1.', nerr '1.1.';
f { num => 1 }, '1.-1', nerr '1.-1';
f { num => 1 }, '.1', nerr '.1';
t { num => 1 }, '0.1e5', '0.1e5';
t { num => 1 }, '0.1e+5', '0.1e+5';
f { num => 1 }, '0.1e5.1', nerr '0.1e5.1';
t { int => 1 }, 0, 0;
t { int => 1 }, -123, -123;
f { int => 1 }, -123.1, { validation => 'int', got => -123.1 }, "failed validation 'int'";
t { uint => 1 }, 0, 0;
t { uint => 1 }, 123, 123;
f { uint => 1 }, -123, { validation => 'uint', got => -123 }, "failed validation 'uint'";
t { min => 1 }, 1, 1;
f { min => 1 }, 0.9, { validation => 'min', expected => 1, got => 0.9 }, "failed validation 'min'";
f { min => 1 }, 'a', { validation => 'min', error => (nerr 'a')[0] }, "validation 'min': failed validation 'num'";
t { max => 1 }, 1, 1;
f { max => 1 }, 1.1, { validation => 'max', expected => 1, got => 1.1 }, "failed validation 'max'";
f { max => 1 }, 'a', { validation => 'max', error => (nerr 'a')[0] }, "validation 'max': failed validation 'num'";
t { range => [1,2] }, 1, 1;
t { range => [1,2] }, 2, 2;
f { range => [1,2] }, 0.9, { validation => 'range', error => { validation => 'min', expected => 1, got => 0.9 } }, "validation 'range': failed validation 'min'";
f { range => [1,2] }, 2.1, { validation => 'range', error => { validation => 'max', expected => 2, got => 2.1 } }, "validation 'range': failed validation 'max'";
#t { range => [1,2] }, 'a', 'a', { validation => 'range', error => { validation => 'max', error => nerr 'a' } }; # XXX: Error validation type depends on evaluation order

# email template
use utf8;
f { email => 1 }, $_, { validation => 'email', got => $_ }, "failed validation 'email'" for (
  'abc.com',
  'abc@localhost',
  'abc@10.0.0.',
  'abc@256.0.0.1',
  '<whoami>@blicky.net',
  'a @a.com',
  'a"@a.com',
  'a@[:]',
  'a@127.0.0.1',
  'a@[::1]',
);
t { email => 1 }, $_, $_ for (
  'a@a.com',
  'a@a.com.',
  'é@yörhel.nl',
  'a+_0-c@yorhel.nl',
  'é@x-y_z.example',
  'abc@x-y_z.example',
);
my $long = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxx';
f { email => 1 }, $long, { validation => 'email', error => { validation => 'maxlength', got => 255, expected => 254 } }, "validation 'email': failed validation 'maxlength'";

# weburl template
f { weburl => 1 }, $_, { validation => 'weburl', got => $_ }, "failed validation 'weburl'" for (
  'http',
  'http://',
  'http:///',
  'http://x/',
  'http://x/',
  'http://256.0.0.1/',
  'http://blicky.net:050/',
  'ftp//blicky.net/',
);
t { weburl => 1}, $_, $_ for (
  'http://blicky.net/',
  'http://blicky.net:50/',
  'https://blicky.net/',
  'https://[::1]:80/',
  'https://l-n.x_.example.com/',
  'https://blicky.net/?#Who\'d%20ever%22makeaurl_like-this/!idont.know',
);


# Things that should fail
ok !eval { FU::Validate->compile({ recursive => 1 }, { recursive => { recursive => 1 } }); 1 }, 'recursive';
ok !eval { FU::Validate->compile({ a => 1 }, { a => { b => 1 }, b => { a => 1 } }); 1 }, 'mutually recursive';
ok !eval { FU::Validate->compile({ wtfisthis => 1 }); 1 }, 'unknown validation';
ok !eval { FU::Validate->compile({ type => 'scalar', a => 1 }, { a => { type => 'array' } }); 1 }, 'incompatible types';
ok !eval { FU::Validate->compile({ type => 'x' }); 1 }, 'unknown type';
ok !eval { FU::Validate->compile({ type => 'array', regex => qr// }); 1 }, 'incompatible type for regex';
ok !eval { FU::Validate->compile({ type => 'hash', keys => {a => {wtfisthis => 1}} }); 1 }, 'unknown type in hash key';

done_testing;

