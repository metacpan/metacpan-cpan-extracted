use 5.014;
use strict;
use warnings;
use Test::More;

use Test::Fatal;

use Dist::PolicyFiles;

use File::Basename;
use File::Spec::Functions;
use File::Temp;
use Cwd;

my $Test_Data_Dir = Cwd::abs_path(catfile(dirname(__FILE__), '01-data'));

subtest 'without reading from HOME/.ssh/config' => sub {
  local $ENV{HOME} = File::Temp->newdir();  # Makes sure that no .ssh/config can be found.
  my %data =(module       => 'Foo::Bar',
             login        => 'fooooo',
             email        => 'this@that',
             full_name    => 'Perry Mason',
             dir          => 'some/dir',
             prefix       => 'blah',
             uncapitalize => !0
            );
  my $dp_obj = new_ok('Dist::PolicyFiles', [%data], 'dp_obj');
  foreach my $member (sort(keys(%data))) {
    is($dp_obj->$member, $data{$member}, "Accessor $member");
  }
};


subtest 'reading from HOME/.ssh/config' => sub {
  local $ENV{HOME} = $Test_Data_Dir;
  subtest 'email and full_name from config' => sub {
    my $dp_obj = new_ok('Dist::PolicyFiles',
                        [module => 'Foo::Bar', login => 'klaus-rindfrey'], 'dp_obj');
    is($dp_obj->email, 'klausrin@cpan.org', 'email from config');
    is($dp_obj->full_name, 'Klaus Rindfrey', 'full_name from config');
    is($dp_obj->dir, '.', 'dir: default');
    is($dp_obj->prefix, q{}, 'prefix: default');
    ok(!$dp_obj->uncapitalize, 'uncapitalize: default (bool)');
    is($dp_obj->uncapitalize, !1, 'uncapitalize: default (exact value)');
  };
  subtest 'only full_name from config' => sub {
    my $dp_obj = new_ok('Dist::PolicyFiles',
                        [module => 'Foo::Bar', login => 'klaus-rindfrey',
                         email => 'e@mail'], 'dp_obj');
    is($dp_obj->email, 'e@mail', 'email from config');
    is($dp_obj->full_name, 'Klaus Rindfrey', 'full_name from config');
  };
  subtest 'only email from config' => sub {
    my $dp_obj = new_ok('Dist::PolicyFiles',
                        [module => 'Foo::Bar', login => 'klaus-rindfrey',
                         full_name => 'Full Name'], 'dp_obj');
    is($dp_obj->email, 'klausrin@cpan.org', 'email from config');
    is($dp_obj->full_name, 'Full Name', 'full_name from config');
  };
  subtest 'no second email in config' => sub {
    my $dp_obj = new_ok('Dist::PolicyFiles',
                        [module => 'Foo::Bar', login => 'jd',
                         full_name => 'Full Name'], 'dp_obj');
    is($dp_obj->email, 'johndoe@mymail.de', 'email from config');
    is($dp_obj->full_name, 'Full Name', 'full_name from config');
  };
};


subtest 'error cases' => sub {
  subtest "new: missing mandatory argument" => sub {
    like(exception { Dist::PolicyFiles->new() }, qr/\bmissing mandatory argument\b/,
         "missing mandatory argument");

    like(exception { Dist::PolicyFiles->new(module => 'Foo::Bar') },
         qr/\blogin: missing mandatory argument\b/,
         "login: missing mandatory argument");

    like(exception { Dist::PolicyFiles->new(login => 'klaus-rindfrey') },
         qr/\bmodule: missing mandatory argument\b/,
         "module: missing mandatory argument");
  };

  subtest 'new: unsupported argument' => sub {
    like(exception { Dist::PolicyFiles->new(module => 'Foo::Bar', login => 'kr', foo => 0) },
         qr/\bfoo: unsupported argument\b/,
         "foo: unsupported argument");
  };

  subtest 'new: value is not a scalar' => sub {
    like(exception { Dist::PolicyFiles->new(module => 'Foo::Bar', login => \ 'klaus-rindfrey') },
         qr/\blogin: value is not a scalar\b/,
         "login: value is not a scalar");
    like(exception { Dist::PolicyFiles->new(module => 'Foo::Bar', login => 'klaus-rindfrey',
                                            email => []) },
         qr/\bemail: value is not a scalar\b/,
         "email: value is not a scalar");
  };

  subtest 'other error cases' => sub {
    local $ENV{HOME} = $Test_Data_Dir;
    ok(defined(exception { Dist::PolicyFiles->new(module => 'Foo::Bar', login => 'jc')}),
       "no mail addr: exception");
    #diag(exception { Dist::PolicyFiles->new(module => 'Foo::Bar', login => 'jc')});
    ok(defined(exception { Dist::PolicyFiles->new(module => 'Foo::Bar', login => 'no-found')}),
       "no login name: exception");
  };
};

#==================================================================================================
done_testing();

