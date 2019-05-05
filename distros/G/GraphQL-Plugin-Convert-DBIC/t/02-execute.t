use strict;
use Test::More 0.98;
use File::Spec;
use lib 't/lib-dbicschema';
use Schema;
use GraphQL::Execution qw(execute);
use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use JSON::MaybeXS;

use_ok 'GraphQL::Plugin::Convert::DBIC';

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  is_deeply $got, $expected or diag explain $got;
}

my $dbic_class = 'Schema';
my $dir = tempdir( CLEANUP => 1 );
my ($tfh, $filename) = tempfile( DIR => $dir );
print $tfh do { open my $fh, 't/test.db'; binmode $fh; join '', <$fh> };
close $tfh;
my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql($dbic_class->connect("dbi:SQLite:$filename"));

subtest 'execute pk + deeper query' => sub {
  my $doc = <<'EOF';
{
  blogs(id: [1, 2]) {
    id
    title
    tags {
      name
    }
  }
  photos(id: [4730349774, 4730337840]) {
    id
    description
    photosets {
      id
      title
      siblings: photos {
        id
      }
      photos {
        id
      }
    }
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 3, $converted->{resolver},
    ],
    {
      data => {
        blogs => [
          {
            id => 1,
            tags => [ { name => "personal" }, { name => "test" } ],
            title => "Hello!",
          },
          {
            id => 2,
            tags => [ { name => "tech" } ],
            title => "Tech",
          }
        ],
        photos => [
          {
            description => '',
            id => '4730337840',
            'photosets' => [
              {
                id => '72157624222825789', title => 'Robot Arms',
                photos => [ { id => '4730337840' }, { id => '4656987762' } ],
                siblings => [ { id => '4730337840' }, { id => '4656987762' } ],
              },
            ],
          },
          {
            description => 'Again - receding hairpieces please!',
            id => '4730349774',
            photosets => [
              {
                id => '72157624222820921', title => 'Head Museum',
                photos => [ { id => '4730349774' } ],
                siblings => [ { id => '4730349774' } ],
              },
            ],
          },
        ],
      }
    }
  );
};

subtest 'execute search query' => sub {
  my $doc = <<'EOF';
{
  searchBlogTag(input: { name: "tech" }) {
    id
    name
    blog {
      title
    }
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 3, $converted->{resolver},
    ],
    {
      data => {
        searchBlogTag => [
          {
            blog => { title => 'Tech' },
            id => 3,
            name => 'tech',
          }
        ],
      }
    }
  );
};

subtest 'execute create mutation' => sub {
  my $doc = <<'EOF';
mutation m {
  createBlogTag(input: [{ blog: { id: 1 }, name: "something" }]) {
    id
    name
    blog {
      title
    }
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 3, $converted->{resolver},
    ],
    {
      data => {
        createBlogTag => [ {
          blog => { title => 'Hello!' },
          id => 6,
          name => 'something',
        } ],
      }
    }
  );
};

subtest 'execute update mutation' => sub {
  my $doc = <<'EOF';
query q {
  photos(id: ["4730349774", "4656987762"]) {
    id
    locality
  }
}

mutation m {
  updatePhoto(input: [
    { id: { id: "4656987762" }, payload: { locality: "Else2" } }
    { id: { id: "4730349774" }, payload: { locality: "Else1" } }
    { id: { id: "nonexistent" }, payload: { locality: "Else3" } }
  ]) {
    id
    locality
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 2, 'q', $converted->{resolver},
    ],
    {
      data => {
        photos => [
          { id => '4656987762', locality => 'Chico' },
          { id => '4730349774', locality => 'Fort Lauderdale' },
        ],
      }
    }
  );
  my $expected = [
    { id => '4656987762', locality => 'Else2' },
    { id => '4730349774', locality => 'Else1' },
  ];
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 2, 'm', $converted->{resolver},
    ],
    {
      data => { updatePhoto => [ @$expected, undef ] },
      errors => [
        {
          locations => [ { column => 1, line => 17 } ],
          message => 'Photo not found',
          path => [ 'updatePhoto', 2 ],
        }
      ],
    },
  );
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 2, 'q', $converted->{resolver},
    ],
    { data => { photos => $expected } },
  );
};

subtest 'execute delete mutation' => sub {
  my $doc = <<'EOF';
query q {
  blogTags(id: [6]) {
    id
    name
  }
}

mutation m {
  deleteBlogTag(input: [ { id: 6 } ])
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 2, 'q', $converted->{resolver},
    ],
    {
      data => {
        blogTags => [ {
          id => 6,
          name => 'something',
        } ],
      }
    }
  );
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 2, 'm', $converted->{resolver},
    ],
    {
      data => { deleteBlogTag => [ JSON->true ] },
    },
  );
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 2, 'q', $converted->{resolver},
    ],
    { data => { blogTags => [] } },
  );
};

subtest 'just get one blog' => sub {
  my $doc = <<'EOF';
{
  blog(id: 1) {
    id
    title
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 3, $converted->{resolver},
    ],
    {
      data => {
        blog =>
        {
          id => 1,
          title => "Hello!",
        },
      }
    }
  );
};

done_testing;
