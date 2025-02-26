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
    onerrorsub => { onerror => sub { ref $_[0] } },
    collapsews => { rmwhitespace => 0, func => sub { $_[0] =~ s/\s+/ /g; 1 } },
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


sub t {
    my($schema, $input, $output, $error) = @_;
    my $line = (caller)[2];

    my $schema_copy = dclone([$schema])->[0];
    my $input_copy = dclone([$input])->[0];

    my $res = FU::Validate->compile($schema, \%validations)->validate($input);
    #diag explain FU::Validate->compile($schema, \%validations) if $line == 139;
    is !$error, !!$res, "boolean context $line";
    is_deeply $schema, $schema_copy, "schema modification $line";
    is_deeply $input,  $input_copy,  "input modification $line";
    is_deeply $res->unsafe_data(), $output, "unsafe_data $line";
    is_deeply $res->data(), $output, "data ok $line" if !$error;
    ok !eval { $res->data; 1}, "data err $line" if $error;
    is_deeply $res->err(), $error, "err $line";
}


# default
t {}, 0, 0, undef;
t {}, '', '', { validation => 'required' };
t {}, undef, undef, { validation => 'required' };
t { default => undef }, undef, undef, undef;
t { default => undef }, '', undef, undef;
t { defaultsub1 => 1 }, undef, 2, undef;
t { defaultsub2 => 1 }, undef, '', undef;
t { defaultsub2 => 1 }, '', 1, undef;
t { onerrorsub => 1 }, undef, 'FU::Validate::Result', undef;

# rmwhitespace
t {}, " Va\rl id \n ", 'Val id', undef;
t { rmwhitespace => 0 }, " Va\rl id \n ", " Va\rl id \n ", undef;
t {}, '  ', '', { validation => 'required' };
t { rmwhitespace => 0 }, '  ', '  ', undef;

# arrays
t {}, [], [], { validation => 'type', expected => 'scalar', got => 'array' };
t { type => 'array' }, 1, 1, { validation => 'type', expected => 'array', got => 'scalar' };
t { type => 'array' }, [], [], undef;
t { type => 'array' }, [undef,1,2,{}], [undef,1,2,{}], undef;
t { type => 'array', scalar => 1 }, 1, [1], undef;
t { type => 'array', values => {} }, [undef], [undef], { validation => 'values', errors => [{ index => 0, validation => 'required' }] };
t { type => 'array', values => {} }, [' a '], ['a'], undef;
t { type => 'array', sort => 'str' }, [qw/20 100 3/], [qw/100 20 3/], undef;
t { type => 'array', sort => 'num' }, [qw/20 100 3/], [qw/3 20 100/], undef;
t { revnum => 1 },                    [qw/20 100 3/], [qw/100 20 3/], undef;
t { type => 'array', sort => 'num', unique => 1 }, [qw/3 2 1/], [qw/1 2 3/], undef;
t { type => 'array', sort => 'num', unique => 1 }, [qw/3 2 3/], [qw/2 3 3/], { validation => 'unique', index_a => 1, value_a => 3, index_b => 2, value_b => 3 };
t { type => 'array', unique => 1 }, [qw/3 1 2/], [qw/3 1 2/], undef;
t { type => 'array', unique => 1 }, [qw/3 1 3/], [qw/3 1 3/], { validation => 'unique', index_a => 0, value_a => 3, index_b => 2, value_b => 3, key => 3 };
t { uniquelength => 1 }, [[],[1],[1,2]], [[],[1],[1,2]], undef;
t { uniquelength => 1 }, [[],[1],[2]], [[],[1],[2]], { validation => 'unique', index_a => 1, value_a => [1], index_b => 2, value_b => [2], key => 1 };
t { type => 'array', setundef => 1 }, [], undef, undef;
t { type => 'array', values => { type => 'any', setundef => 1 } }, [[]], [undef], undef;

# hashes
t { type => 'hash' }, [], [], { validation => 'type', expected => 'hash', got => 'array' };
t { type => 'hash' }, 'a', 'a', { validation => 'type', expected => 'hash', got => 'scalar' };
t { type => 'hash' }, {a=>[],b=>undef,c=>{}}, {}, undef;
t { type => 'hash', keys => { a=>{} } }, {}, {a=>undef}, { validation => 'keys', errors => [{ key => 'a', validation => 'required' }] }; # XXX: the key doesn't necessarily have to be created
t { type => 'hash', keys => { a=>{missing=>'ignore'} } }, {}, {}, undef;
t { type => 'hash', keys => { a=>{default=>undef} } }, {}, {a=>undef}, undef;
t { type => 'hash', keys => { a=>{missing=>'create',default=>undef} } }, {}, {a=>undef}, undef;
t { type => 'hash', keys => { a=>{missing=>'reject'} } }, {}, {}, {key => 'a', validation => 'missing'};

t { type => 'hash', keys => { a=>{} } }, {a=>' a '}, {a=>'a'}, undef; # Test against in-place modification
t { type => 'hash', keys => { a=>{} }, unknown => 'remove' }, { a=>1,b=>1 }, { a=>1 }, undef;
t { type => 'hash', keys => { a=>{} }, unknown => 'reject' }, { a=>1,b=>1 }, { a=>1,b=>1 }, { validation => 'unknown', keys => ['b'], expected => ['a'] };
t { type => 'hash', keys => { a=>{} }, unknown => 'pass' }, { a=>1,b=>1 }, { a=>1,b=>1 }, undef;
t { type => 'hash', setundef => 1 }, {}, undef, undef;
t { type => 'hash', unknown => 'reject', keys => { a=>{ type => 'any', setundef => 1}} }, {a=>[]}, {a=>undef}, undef;

# default validations
t { minlength => 3 }, 'ab', 'ab', { validation => 'minlength', expected => 3, got => 2 };
t { minlength => 3 }, 'abc', 'abc', undef;
t { maxlength => 3 }, 'abcd', 'abcd', { validation => 'maxlength', expected => 3, got => 4 };
t { maxlength => 3 }, 'abc', 'abc', undef;
t { minlength => 3, maxlength => 3 }, 'abc', 'abc', undef;
t { length => 3 }, 'ab',   'ab',   { validation => 'length', expected => 3, got => 2 };
t { length => 3 }, 'abcd', 'abcd', { validation => 'length', expected => 3, got => 4 };
t { length => 3 }, 'abc',  'abc',  undef;
t { length => [1,3] }, 'abc',  'abc', undef;
t { length => [1,3] }, 'abcd', 'abcd', { validation => 'length', expected => [1,3], got => 4 };;
t { type => 'array', length => 0 }, [], [], undef;
t { type => 'array', length => 1 }, [1,2], [1,2], { validation => 'length', expected => 1, got => 2 };
t { type => 'hash', length => 0 }, {}, {}, undef;
t { type => 'hash', length => 1, unknown => 'pass' }, {qw/1 a 2 b/}, {qw/1 a 2 b/}, { validation => 'length', expected => 1, got => 2 };
t { type => 'hash', length => 1, keys => {a => {missing=>'ignore'}, b => {missing=>'ignore'}} }, {a=>1}, {a=>1}, undef;
t { regex => '^a' }, 'abc', 'abc', undef;  # XXX: Can't use qr// here because t() does dclone(). The 'hex' test covers that case anyway.
t { regex => '^a' }, 'cba', 'cba', { validation => 'regex', regex => '^a', got => 'cba' };
t { enum => [1,2] }, 1, 1, undef;
t { enum => [1,2] }, 2, 2, undef;
t { enum => [1,2] }, 3, 3, { validation => 'enum', expected => [1,2], got => 3 };
t { enum => 1 }, 1, 1, undef;
t { enum => 1 }, 2, 2, { validation => 'enum', expected => [1], got => 2 };
t { enum => {a=>1,b=>2} }, 'a', 'a', undef;
t { enum => {a=>1,b=>2} }, 'c', 'c', { validation => 'enum', expected => ['a','b'], got => 'c' };
t { anybool => 1 }, 1, true, undef;
t { anybool => 1 }, undef, false, undef;
t { anybool => 1 }, '', false, undef;
t { anybool => 1 }, {}, true, undef;
t { anybool => 1 }, [], true, undef;
t { anybool => 1 }, bless({}, 'test'), true, undef;
t { bool => 1 }, 1, 1, { validation => 'bool' };
t { bool => 1 }, \1, true, undef;
my($true, $false) = (1,0);
t { bool => 1 }, bless(\$true, 'boolean'), true, undef;
t { bool => 1 }, bless(\$false, 'boolean'), false, undef;
t { bool => 1 }, bless(\$true, 'test'), bless(\$true, 'test'), { validation => 'bool' };
t { ascii => 1 }, 'ab c', 'ab c', undef;
t { ascii => 1 }, "a\nb", "a\nb", { validation => 'ascii', got => "a\nb" };

# custom validations
t { hex => 1 }, 'DeadBeef', 'DeadBeef', undef;
t { hex => 1 }, 'x', 'x', { validation => 'hex', error => { validation => 'regex', regex => "$validations{hex}{regex}", got => 'x' } };
t { prefix => 'a' }, 'abc', 'abc', undef;
t { prefix => 'a' }, 'cba', 'cba', { validation => 'prefix', error => { validation => 'func', result => '' } };
t { mybool => 1 }, 'abc', 1, undef;
t { mybool => 1 }, undef, 0, undef;
t { mybool => 1 }, '', 0, undef;
t { collapsews => 1 }, " \t\n ", ' ', undef;
t { collapsews => 1 }, '   x  ', ' x ', undef;
t { collapsews => 1, rmwhitespace => 1 }, '   x  ', 'x', undef;
t { person => 1 }, 1, 1, { validation => 'type', expected => 'hash', got => 'scalar' };
t { person => 1, default => 1 }, undef, 1, undef;
t { person => 1 }, { sex => 1 }, { sex => 1, name => undef }, { validation => 'person', error => { validation => 'keys', errors => [{ key => 'name', validation => 'required' }] } };
t { person => 1 }, { sex => undef, name => 'y' }, { sex => 1, name => 'y' }, undef;
t { person => 1, keys => {age => {default => \'required'}} }, {name => 'x', sex => 'y'}, { name => 'x', sex => 'y', age => undef }, { validation => 'keys', errors => [{ key => 'age', validation => 'required' }] };
t { person => 1, keys => {extra => {}} }, {name => 'x', sex => 'y', extra => 1},  { name => 'x', sex => 'y', extra => 1 }, undef;
t { person => 1, keys => {extra => {}} }, {name => 'x', sex => 'y', extra => ''}, { name => 'x', sex => 'y', extra => '' }, { validation => 'keys', errors => [{ key => 'extra', validation => 'required' }] };
t { person => 1 }, {name => 'x', sex => 'y', extra => 1}, {name => 'x', sex => 'y', extra => 1}, undef;
t { person => 1, unknown => 'remove' }, {name => 'x', sex => 'y', extra => 1}, {name => 'x', sex => 'y'}, undef;
t { neverfails => 1, int => 1 }, undef, 'err', undef;
t { neverfails => 1, int => 1 }, 'x', 'err', undef;
t { neverfails => 1, int => 1, onerror => undef }, 'x', undef, undef; # XXX: no way to 'unset' an inherited onerror clause, hmm.

# numbers
sub nerr { +{ validation => 'num', got => $_[0] } }
t { num => 1 }, 0, 0, undef;
t { num => 1 }, '-', '-', nerr '-';
t { num => 1 }, '00', '00', nerr '00';
t { num => 1 }, '1', '1', undef;
t { num => 1 }, '1.1.', '1.1.', nerr '1.1.';
t { num => 1 }, '1.-1', '1.-1', nerr '1.-1';
t { num => 1 }, '.1', '.1', nerr '.1';
t { num => 1 }, '0.1e5', '0.1e5', undef;
t { num => 1 }, '0.1e+5', '0.1e+5', undef;
t { num => 1 }, '0.1e5.1', '0.1e5.1', nerr '0.1e5.1';
t { int => 1 }, 0, 0, undef;
t { int => 1 }, -123, -123, undef;
t { int => 1 }, -123.1, -123.1, { validation => 'int', got => -123.1 };
t { uint => 1 }, 0, 0, undef;
t { uint => 1 }, 123, 123, undef;
t { uint => 1 }, -123, -123, { validation => 'uint', got => -123 };
t { min => 1 }, 1, 1, undef;
t { min => 1 }, 0.9, 0.9, { validation => 'min', expected => 1, got => 0.9 };
t { min => 1 }, 'a', 'a', { validation => 'min', error => nerr 'a' };
t { max => 1 }, 1, 1, undef;
t { max => 1 }, 1.1, 1.1, { validation => 'max', expected => 1, got => 1.1 };
t { max => 1 }, 'a', 'a', { validation => 'max', error => nerr 'a' };
t { range => [1,2] }, 1, 1, undef;
t { range => [1,2] }, 2, 2, undef;
t { range => [1,2] }, 0.9, 0.9, { validation => 'range', error => { validation => 'min', expected => 1, got => 0.9 } };
t { range => [1,2] }, 2.1, 2.1, { validation => 'range', error => { validation => 'max', expected => 2, got => 2.1 } };
#t { range => [1,2] }, 'a', 'a', { validation => 'range', error => { validation => 'max', error => nerr 'a' } }; # XXX: Error validation type depends on evaluation order

# email template
use utf8;
t { email => 1 }, $_->[1], $_->[1], $_->[0] ? undef : { validation => 'email', got => $_->[1] } for (
  [ 0, 'abc.com' ],
  [ 0, 'abc@localhost' ],
  [ 0, 'abc@10.0.0.' ],
  [ 0, 'abc@256.0.0.1' ],
  [ 0, '<whoami>@blicky.net' ],
  [ 0, 'a @a.com' ],
  [ 0, 'a"@a.com' ],
  [ 0, 'a@[:]' ],
  [ 0, 'a@127.0.0.1' ],
  [ 0, 'a@[::1]' ],
  [ 1, 'a@a.com' ],
  [ 1, 'a@a.com.' ],
  [ 1, 'é@yörhel.nl' ],
  [ 1, 'a+_0-c@yorhel.nl' ],
  [ 1, 'é@x-y_z.example' ],
  [ 1, 'abc@x-y_z.example' ],
);
my $long = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxx';
t { email => 1 }, $long, $long, { validation => 'email', error => { validation => 'maxlength', got => 255, expected => 254 } };

# weburl template
t { weburl => 1 }, $_->[1], $_->[1], $_->[0] ? undef : { validation => 'weburl', got => $_->[1] } for (
  [ 0, 'http' ],
  [ 0, 'http://' ],
  [ 0, 'http:///' ],
  [ 0, 'http://x/' ],
  [ 0, 'http://x/' ],
  [ 0, 'http://256.0.0.1/' ],
  [ 0, 'http://blicky.net:050/' ],
  [ 0, 'ftp//blicky.net/' ],
  [ 1, 'http://blicky.net/' ],
  [ 1, 'http://blicky.net:50/' ],
  [ 1, 'https://blicky.net/' ],
  [ 1, 'https://[::1]:80/' ],
  [ 1, 'https://l-n.x_.example.com/' ],
  [ 1, 'https://blicky.net/?#Who\'d%20ever%22makeaurl_like-this/!idont.know' ],
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

