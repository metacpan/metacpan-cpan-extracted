use 5.20.0;

use strict;
use warnings;

use Test2::V0;

use File::Serialize::Serializer::Markdown;
use File::Serialize;

subtest 'serialize' => sub {
    is deserialize_file(
        \<<"END_MD", { format => 'md' } ), { slug => 'goo', _content => "\nHi there\n" }, "basic";
---
slug: goo
---

Hi there
END_MD

    is deserialize_file(
        \<<"END_MD", { format => 'md' } ), { slug => 'goo', _content => "\nHi there\n" }, "no leading dashes";
slug: goo
---

Hi there
END_MD

    is deserialize_file(
        \<<"END_MD", { format => 'md' } ), { _content => "\nHi there\n" }, "empty frontmatter";
---
---

Hi there
END_MD

    is deserialize_file(
        \<<"END_MD", { format => 'md' } ), { _content => "Hi there\n" }, "no frontmatter";
Hi there
END_MD
};

subtest 'serialize' => sub {
    my $output = "";

    serialize_file \$output =>
      { b      => 'bar', a => 'foo', _content => "blah\n" },
      { format => 'md' };

    is $output => <<END_MD, 'serialize basic';
---
a: foo
b: bar
---
blah
END_MD

    serialize_file \$output => { _content => "blah\n" },
      { format => 'md' };

    is $output => <<END_MD, 'serialize no frontmatter';
blah
END_MD
};

done_testing;
