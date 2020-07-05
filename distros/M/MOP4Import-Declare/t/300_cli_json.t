#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

#use Test::Kantan;
use Test::More;
use Test::Exit;
use Capture::Tiny qw(capture);

use Scalar::Util qw/isweak/;

use rlib qw!../..!;

use MOP4Import::Util::CallTester [as => 'CallTester'];

# use MOP4Import::t::t_lib qw/no_error expect_script_error/;

sub should_compile ($$) {
  my ($title, $script) = @_;
  local $@;
  eval "use strict; use warnings; $script";
  is($@, '', $title);
};

should_compile "package MyApp1 {use ... -as_base;...}", q{
package MyApp1;
use MOP4Import::Base::CLI_JSON -as_base, -inc, [fields => qw/foo/]
, [output_format => ltsv => sub {
  my ($self, $outFH, @tables) = @_;
  foreach my $table (@tables) {
    foreach my $dict (ref $table eq 'ARRAY' ? @$table : $table) {
      print $outFH join("\t", map {
        my $val = $dict->{$_};
        _strip_tab($_).":"._strip_tab(defined $val && ref $val ? $self->cli_encode_json($val) : $val);
      } sort keys %$dict), "\n";
    }
  }
 }
]
;

sub cmd_cmd {
  (my MY $self, my @args) = @_;
  print join(" ", $self->{foo}, @args), "\n";
}

sub as_is {
  (my MY $self, my @args) = @_;
  wantarray ? @args : \@args;
}

sub contextual {
  (my MY $self, my @args) = @_;
  wantarray
   ? (+{result => $self->{foo}}, +{result => \@args})
   : [$self->{foo} => \@args]
}

sub _strip_tab { my ($str) = @_; $str =~ s/\t//g; $str }

1;
};

sub compat_Data_Dumper {
  my ($str) = @_;
  require Data::Dumper;
  if ($Data::Dumper::VERSION ge "2.160") {
    $str =~ s/,X$/,/mg;
  } else {
    $str =~ s/,X$//mg;
  }
  $str;
}

subtest "cli_json", sub {
  plan tests => 1;
  is MyApp1->cli_json, JSON::MaybeXS::JSON(), "cli_json";
};

subtest "cli_encode_json/cli_decode_json", sub {
  plan tests => 2;
  my $app = MyApp1->new;
  is_deeply $app->cli_decode_json($app->cli_encode_json(["foo"])), ["foo"];
  is_deeply $app->cli_encode_json($app->cli_decode_json(q|{"foo":3}|)), q|{"foo":3}|;
};

subtest "cli_array and cli_object", sub {
  plan tests => 2;
  my $test = CallTester->make_tester(MyApp1->new);

  $test->returns_in_list([cli_array => qw(a b 1 2)], [[qw(a b 1 2)]]);
  $test->returns_in_scalar([cli_object => qw(a b 1 2)], +{a => 'b', 1 => '2'});
};

SKIP: {
  skip "requires 5.24", 4 unless $] >= 5.026;

  subtest "exit code", sub {
    plan tests => 4;
    my $test = CallTester->make_tester('MyApp1');

    $test->exits([run => [cli_list => 'foo']], 0);
    $test->exits([run => [cli_list => ()]], 1);

    $test->exits([run => [qw/--scalar cli_identity/,  1]], 0);
    $test->exits([run => [qw/--scalar cli_identity/, '']], 1);
  };
}

my $CT = CallTester->make_tester('MyApp1');

subtest "MyApp1->run([--foo,cmd])", sub {
  plan tests => 1;
  $CT->captures([run => ['--foo','cmd','baz']], "1 baz\n");
};

subtest "MyApp1->run([--foo={x:3},contextual,{y:8},undef,[a,b,c]])", sub {
  my @opts = ('--no-exit-code', '--foo={"x":3}');
  my @vals = ('{"y":8}', undef, '[1,"foo",2,3]');

  subtest "default (--output=ndjson)", sub {
    my @o = (@opts);

    $CT->captures([run => [@o, contextual => @vals]]
                  , qq|{"result":{"x":3}}\n{"result":[{"y":8},null,[1,"foo",2,3]]}\n|);

    $CT->captures([run => ['--scalar', @o, contextual => @vals]]
                  , qq|{"x":3}\n[{"y":8},null,[1,"foo",2,3]]\n|);

    $CT->captures([run => [@o, cli_array => 2..5]]
                  , qq|[2,3,4,5]\n|);

    $CT->captures([run => [@o, '--flatten', cli_array => 2..5]]
                  , qq|2\n3\n4\n5\n|);

    done_testing();
  };

  subtest "(--output=json)", sub {
    my @o = ('--output=json', @opts);

    $CT->captures([run => [@o, as_is => [1..3], {x => 8}]]
                  , qq|[[1,2,3],{"x":8}]\n|);


    $CT->captures([run => [@o, contextual => @vals]]
                  , qq|[{"result":{"x":3}},{"result":[{"y":8},null,[1,"foo",2,3]]}]\n|);

    subtest "--scalar", sub {
      plan tests => 1;
      $CT->captures([run => ['--scalar', @o, contextual => @vals]]
                    , qq|[{"x":3},[{"y":8},null,[1,"foo",2,3]]]\n|);
    };

    done_testing();
  };

  subtest "--output=dump", sub {
    $CT->captures([run => ['--output=dump', @opts, contextual => @vals]]
                  , compat_Data_Dumper(<<'END'));
{
  'result' => {
    'x' => 3,X
  },X
}
{
  'result' => [
    {
      'y' => 8,X
    },
    undef,
    [
      1,
      'foo',
      2,
      3,X
    ],X
  ],X
}
END

    subtest "--scalar", sub {
      plan tests => 1;
      $CT->captures([run => ['--scalar', '--output=dump', @opts, contextual => @vals]]
                    , compat_Data_Dumper(<<'END'));
{
  'x' => 3,X
}
[
  {
    'y' => 8,X
  },
  undef,
  [
    1,
    'foo',
    2,
    3,X
  ],X
]
END
    };

    done_testing();
  };

  subtest "--output=yaml", sub {
    plan tests => 1;

    $CT->captures([run => ['--output=yaml', @opts, contextual => @vals]], <<'END');
--- 
- 
  result: 
    x: 3
- 
  result: 
    - 
      "y": 8
    - ~
    - 
      - 1
      - foo
      - 2
      - 3
END

  };

  subtest "--output=tsv", sub {
    plan tests => 2;

    $CT->captures([run => ['--output=tsv', @opts, contextual => @vals]]
                  , qq|{"result":{"x":3}}\n{"result":[{"y":8},null,[1,"foo",2,3]]}\n|);

    $CT->captures([run => ['--output=tsv', @opts
                           , cli_list =>
                           , [foo => 'bar']
                           , [1,2]
                           , [3,4]
                           , [undef, "\t\n'\"", {x => 5, y => 6}, [7, 8, 9]]
                         ]]
                  , join(""
                         , "foo\tbar\n"
                         , "1\t2\n"
                         , "3\t4\n"
                         , join("\t", 'null', q{ '"}, '{"x":5,"y":6}', '[7,8,9]')."\n"
                       ));

  };

  subtest 'cli_encode_as($format, @records)', sub {

    is(MyApp1->new
       ->cli_encode_as(tsv => ['a'..'d'], [1..4], {x => 5, y => [6, 7]})
       , join("", "a\tb\tc\td\n"
              , "1\t2\t3\t4\n"
              , '{"x":5,"y":[6,7]}'."\n"
            )
       , 'cli_encode_as(tsv => @tsv)'
     );

    use utf8;
    is(MyApp1->new
       ->cli_encode_as([tsv => ":utf8"]
                       => [N => 'label'], [1, "漢字"], [2, "ひらがな"])
       , Encode::encode_utf8(join("", "N\tlabel\n"
                                   , "1\t漢字\n"
                                   , "2\tひらがな\n"
                                 ))
       , "layer option"
     )
};

  subtest "--output=raw", sub {
    plan tests => 1;
    require Math::BigInt;
    $CT->captures([run => ['--output=raw', '--no-exit-code'
                           , cli_eval => 'Math::BigInt->new(30)']]
                  , 30);
  };

  done_testing();
};

subtest "cli_write_fh_as_... APIs", sub {
  plan tests => 1;

  $CT->captures([run => [qw/--no-exit-code --output=ltsv cli_list/
                         , qq|{"a":{"foo":"bar"},"b":[1,"baz"]}|
                         , qq|{"c":3,"d":8}|
                       ]]
                , qq|a:{"foo":"bar"}\tb:[1,"baz"]\nc:3\td:8\n|);

};

subtest "cli_read_file APIs", sub {
  my $test = CallTester->make_tester(MyApp1->new);

  $test->returns_in_list(
    [cli_read_file => "$FindBin::Bin/cli_json_input.d/input.txt"]
    , ["foo bar baz", "xx yy zz  ", "a b c"]);

  $test->returns_in_scalar(
    [cli_read_file => "$FindBin::Bin/cli_json_input.d/input.txt"]
    , ["foo bar baz", "xx yy zz  ", "a b c"]);

  $test->returns_in_list(
    [cli_read_file => "$FindBin::Bin/cli_json_input.d/no_extension"]
    , ["foo\nbar\nbaz"]);

  $test->returns_in_list(
    [cli_read_file => "$FindBin::Bin/cli_json_input.d/input.yml"]
    , [[{foo => "bar", "baz" => 3}, {x => 8}]]);

  $test->returns_in_list(
    [cli_read_file => "$FindBin::Bin/cli_json_input.d/input.yaml"]
    , [{foo => "bar", "baz" => 3}, {x => 8, y => 3}]);


  $test->returns_in_list(
    [cli_read_file => "$FindBin::Bin/cli_json_input.d/keybindings.json", allow_comments => 1]
    , [[{'when' => 'editorTextFocus','key' => 'ctrl+b','command' => 'cursorLeft'},{'key' => 'ctrl+f','command' => 'cursorRight','when' => 'editorTextFocus'},{'command' => 'cursorDown','key' => 'ctrl+n','when' => 'editorTextFocus'},{'when' => 'editorTextFocus && !inQuickOpen','key' => 'ctrl+p','command' => 'cursorUp'},{'when' => 'editorTextFocus','command' => 'cursorHome','key' => 'ctrl+a'},{'when' => 'editorTextFocus','command' => 'cursorEnd','key' => 'ctrl+e'},{'command' => 'deleteLeft','key' => 'ctrl+h'},{'command' => 'deleteRight','key' => 'ctrl+d','when' => 'editorTextFocus'},{'key' => 'ctrl+q','command' => 'cursorWordLeft','when' => 'editorTextFocus'},{'when' => 'editorTextFocus','key' => 'ctrl+t','command' => 'cursorWordRight'},{'when' => 'editorFocus && !findWidgetVisible && editorLangId == \'fsharp\'','key' => 'ctrl+alt+enter','command' => 'fsi.SendFile'}]]);

    $test->returns_in_list(
      [cli_read_file => "$FindBin::Bin/cli_json_input.d/basic-js.json", allow_comments => 1]
      , [{url => "http://localhost", key2 => [0..4]
          , "key3" => {a => "foo/*bar baz*/", b => 2}}]
    );

  done_testing();
};

done_testing();
