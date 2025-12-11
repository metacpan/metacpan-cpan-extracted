use v5.26.0; # lexical sub
use warnings;

use JMAP::Tester::Sugar '-all';

use Test::Deep ':v1';
use Test::Deep::JType;
use Test::More;

for my $with_call_id (0, 1) {
  my $desc = $with_call_id ? "with method call id" : "without method call id";

  my sub maybe_cid :prototype() { $with_call_id ? 'a1' : () }

  subtest $desc => sub {
    jcmp_deeply(
      jset(
        Email => { create => [ { subject => "Hi" }, { subject => "Bye" } ] },
        maybe_cid
      ),
      [
        'Email/set',
        {
          create => {
            "Email-0" => { subject => "Hi" },
            "Email-1" => { subject => "Bye" },
          }
        },
        maybe_cid
      ],
      "multi-object jset create",
    );

    jcmp_deeply(
      jset(Email => { create => { subject => "Hi" } }, maybe_cid),
      [
        'Email/set', { create => { "Email-0" => { subject => "Hi" } } },
        maybe_cid
      ],
      "single-object jset create",
    );

    jcmp_deeply(
      jcreate(
        Email => [ { subject => "Hi" }, { subject => "Bye" } ],
        maybe_cid
      ),
      [
        'Email/set',
        {
          create => {
            "Email-0" => { subject => "Hi" },
            "Email-1" => { subject => "Bye" },
          }
        },
        maybe_cid
      ],
      "multi-object jcreate",
    );

    jcmp_deeply(
      jcreate(Email => { subject => "Hi" }, maybe_cid),
      [
        'Email/set', { create => { "Email-0" => { subject => "Hi" } } },
        maybe_cid
      ],
      "single-object jcreate",
    );
  };
}

done_testing;
