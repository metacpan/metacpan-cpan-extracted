use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'interp-mcr',
                                                      description => 'In-depth testing of multiple component roots' );

    $group->add_test( name           => 'no_dynamic_comp_root',
                      description    => 'change comp root without dynamic_comp_root',
                      pre_code       => sub {
                          my ($interp) = @_;
                          $interp->comp_root($group->data_dir);
                      },
                      skip_component => 1,
                      call_path      => '/',
                      expect_error   => qr/cannot assign new comp_root/,
                      );

    $group->add_test( name           => 'change_single_comp_root',
                      description    => 'change single root',
                      interp_params  => {comp_root => '/usr/local/foo',
                                         dynamic_comp_root => 1},
                      pre_code       => sub {
                          my ($interp) = @_;
                          $interp->comp_root('/usr/local/bar');
                      },
                      skip_component => 1,
                      call_path      => '/',
                      expect_error   => qr/was originally associated with .*, cannot change/,
                      );

    $group->add_test( name           => 'reuse_comp_root_key',
                      description    => 'change comp root key mapping',
                      interp_params  => {comp_root => [['foo' => '/usr/local/foo'],
                                                       ['bar' => '/usr/local/bar']],
                                         dynamic_comp_root => 1},
                      pre_code       => sub {
                          my ($interp) = @_;
                          $interp->comp_root([['foo' => '/usr/local/foo'],
                                              ['bar' => '/usr/local/baz']]),
                      },
                      skip_component => 1,
                      call_path      => '/',
                      expect_error   => qr/was originally associated with .*, cannot change/,
                      );

    # For each test below, change the interpreter's component root on
    # the fly, then make sure the right versions of /foo and /bar/ are
    # being loaded.  Also occasionally remove a component to make sure
    # that the next one gets loaded. Run with both static_source=0 and
    # static_source=1.
    #

    foreach my $static_source (0, 1) {
        my $interp = $group->_make_interp ( comp_root         => $group->comp_root,
                                            data_dir          => $group->data_dir,
                                            static_source     => $static_source,
                                            dynamic_comp_root => 1,
                                          );
        
        foreach my $root (1..4) {
            $group->add_support( path => "/$root/interp-mcr/$static_source/foo",
                                 component => "I am $root/foo, <& bar &>",
                               );
        }
        foreach my $root (7..8) {
            $group->add_support( path => "/$root/interp-mcr/$static_source/bar",
                                 component => "I am $root/bar",
                               );
        }

        my $make_test_for_roots = sub
        {
            my ($keys, %params) = @_;
            my $test_name = "test" . join('', @$keys) . "-" . $static_source;

            $group->add_test( name => $test_name,
                              description => "test roots assigned to " . join(", ", @$keys) . ", static_source=$static_source",
                              skip_component => 1,
                              interp => $interp,
                              pre_code => sub {
                                  $interp->comp_root([map { [$_, $group->comp_root . "/interp-mcr/$_"] } @$keys]);
                                  if ($params{remove}) {
                                      foreach my $comp (qw(foo bar)) {
                                          unlink("mason_tests/$$/comps/interp-mcr/$params{remove}/interp-mcr/$static_source/$comp");
                                      }
                                  }
                              },
                              call_path => "/$static_source/foo",
                              %params
                            );
        };

        $make_test_for_roots->([1, 7],           expect=>'I am 1/foo, I am 7/bar');
        $make_test_for_roots->([1, 2, 3, 4, 8],  expect=>'I am 1/foo, I am 8/bar');
        if ($static_source) {
            $make_test_for_roots->([1, 2, 3, 7], remove=>'1', expect=>'I am 1/foo, I am 7/bar');
        } else {
            $make_test_for_roots->([1, 2, 3, 7], remove=>'1', expect=>'I am 2/foo, I am 7/bar');
        }
        $make_test_for_roots->([2, 3, 4, 7],     expect=>'I am 2/foo, I am 7/bar');
        $make_test_for_roots->([5, 4, 2, 3, 8],  expect=>'I am 4/foo, I am 8/bar');
        $make_test_for_roots->([5, 6],           expect_error => qr/could not find component/);
        $make_test_for_roots->([1, 2, 3, 4],     expect_error => qr/could not find component/);
    }

    return $group;
}
