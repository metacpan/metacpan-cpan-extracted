use strict;
use warnings;

use Test::More;

# FILENAME: 01-basic.t
# CREATED: 08/10/11 07:21:37 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test Basic Functionality of munging.

use Dist::Zilla::Util::SimpleMunge qw( munge_file );
use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::FromCode;
use Dist::Zilla::File::OnDisk;

my $in_memory = Dist::Zilla::File::InMemory->new(
  name     => 'in_memory.file',
  content  => "Initial Value",
  added_by => "Hand",
);

my $v = 0;

my $from_code = Dist::Zilla::File::FromCode->new(
  name => 'from_code.file',
  code => sub {
    $v++;
    return "$v";
  },
  code_return_type => 'text',
  added_by         => "Hand",
);

pass("Initial setup is successful");

munge_file(
  $in_memory => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/initial/New/gi;
      return $content;
    },
    lazy => 1,
  },
);

munge_file(
  $from_code => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/(\d+)/munged $1/g;
      return $content;
    },
    lazy => 0,
  }
);

is( $v,                  1,           'from_code has been munged to a scalar already' );
is( $in_memory->content, 'New Value', 'in_memory content has been munged properly' );
is( $from_code->content, 'munged 1',  'from_code content has been munged to a scalar which doesn\'t change x1' );
is( $from_code->content, 'munged 1',  'from_code content has been munged to a scalar which doesn\'t change x2' );
is( $v,                  1,           'from_code doesnt call the coderef to generate anymore' );

my $x = 0;

munge_file(
  $in_memory => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/New/Second/gi;
      return $content;
    },
    lazy => 0,
  },
);

munge_file(
  $from_code => {
    via => sub {
      my ( $file, $content ) = @_;
      $content =~ s/munged/munged_level2 $x/g;
      $x++;
      return $content;
    },
    lazy => 1,
  },
);

is( $v, 1, 'from_code->static->code doesnt generate from source' );
is( $x, 0, 'from_code->static->code doesnt do last munge untill evaluated' );

is( $in_memory->content, 'Second Value',      'static->code->static content has been re-munged properly' );
is( $from_code->content, 'munged_level2 0 1', 'code->static->code has been re-munged properly x1' );
is( $from_code->content, 'munged_level2 1 1', 'code->static->code has been re-munged properly x2' );
is( $v,                  1,                   'code->static->code doesnt remunge old munges' );
is( $x,                  2,                   'code->static->code remunges new munges' );

my $on_disk = Dist::Zilla::File::OnDisk->new( name => $0 );

munge_file(
  $on_disk => {
    via => sub {
      my ( $file, $content ) = @_;
      $content = "^_^ $content";
      return $content;
    },
    lazy => undef,
  }
);

my $expect = '^_^ use strict';
is( ( substr $on_disk->content, 0, length $expect ), $expect, 'on_disk file munges correctly' );

done_testing;

