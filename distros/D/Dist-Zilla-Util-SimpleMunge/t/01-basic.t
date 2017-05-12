use strict;
use warnings;

use Test::More;

# FILENAME: 01-basic.t
# CREATED: 08/10/11 07:21:37 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test Basic Functionality of munging.

use Dist::Zilla::Util::SimpleMunge qw( munge_file );
use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::FromCode;

my $in_memory = Dist::Zilla::File::InMemory->new(
  name    => 'in_memory.file',
  content => "Initial Value",
);

my $v = 0;

my $from_code = Dist::Zilla::File::FromCode->new(
  name => 'from_code.file',
  code => sub {
    $v++;
    return "$v";
  }
);

pass("Initial setup is successful");

munge_file(
  $in_memory => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/initial/New/gi;
      return $content;
    },
  }
);

munge_file(
  $from_code => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/(\d+)/munged $1/g;
      return $content;
    },
  }
);

is( $v,                  0,           'from code has not been munged yet' );
is( $in_memory->content, 'New Value', 'static content has been munged properly' );
is( $from_code->content, 'munged 1',  'from code content has been munged properly x1' );
is( $from_code->content, 'munged 2',  'from code content has been munged properly x2' );
is( $v,                  2,           'from codes coderef has been munged twice' );

munge_file(
  $in_memory => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/New/Second/gi;
      return $content;
    },
  }
);

munge_file(
  $from_code => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/munged/munged_level2/g;
      return $content;
    },
  }
);

is( $v,                  2,                 'from code has not been re-munged yet' );
is( $in_memory->content, 'Second Value',    'static content has been re-munged properly' );
is( $from_code->content, 'munged_level2 3', 'from code content has been re-munged properly x1' );
is( $from_code->content, 'munged_level2 4', 'from code content has been re-munged properly x2' );
is( $v,                  4,                 'from codes coderef has been re-munged twice' );

done_testing;

