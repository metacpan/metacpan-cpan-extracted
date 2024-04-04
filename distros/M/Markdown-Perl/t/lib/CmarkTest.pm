# A package to execute the cmark test suite (and those of the specs derived from
# it).
# There is a fast version that we execute ourselves based on a JSON file with
# all the tests and there is the full version using the cmark test tool but
# which is much slower (and has a more aggressive HTML normalization that
# actually hides some bugs).

package CmarkTest;

use strict;
use warnings;
use utf8;
use feature ':5.24';

use Exporter 'import';
use HtmlSanitizer;
use JSON 'from_json';
use Markdown::Perl;
use Test2::V0;

our @EXPORT = qw(test_suite);

sub json_test {
  my ($pmarkdown, %opt) = @_;
  my $test_data;
  {
    local $/ = undef;
    open my $f, '<:encoding(utf-8)', $opt{json_file};
    my $json_data = <$f>;
    close $f;
    $test_data = from_json($json_data);
  }
  my %todo = map { $_ => 1 } @{$opt{todo} // []};
  my %bugs = map { $_ => 1 } @{$opt{bugs} // []};
  my $i = 0;
  for my $t (@{$test_data}) {
    $i++;
    next if exists $opt{test_num} && $opt{test_num} != $i;

    my $out = $pmarkdown->convert($t->{markdown});
    my $val = sanitize_html($out);
    my $expected = sanitize_html($t->{html});

    my $title = sprintf "%s (%d)", $t->{section}, $t->{example};
    my @diag;
    push @diag, sprintf $opt{test_url}, $t->{example} if exists $opt{test_url};
    push @diag, 'Input markdown:', $t->{markdown}, "\n";

    my $test = sub { is($val, $expected, $title, @diag) };
  
    if ($todo{$i}) {
      todo 'Not yet supported' => $test;
    } elsif ($bugs{$i}) {
      todo 'The spec is buggy' => $test;
    } else {
      $test->();
    }
  }
}

sub full_test {
  my (%opt) = @_;

  skip_all('Python3 must be installed.') if system 'python3 -c "exit()" 2>/dev/null';

  skip_all('commonmark-spec must be checked out.') unless -e $opt{spec_tool};
  skip_all("The $opt{spec_name} test suite must be checked out.") unless -e $opt{spec};

  my $root_dir = "${FindBin::Bin}/..";

  my $mode;
  if (exists $opt{test_num}) {
    $mode = "-n ".$opt{test_num};
  } else {
    $mode = "--track ${root_dir}/commonmark.$opt{mode}.tests";
  }

  my $test_suite_output = system "python3 $opt{spec_tool} --spec $opt{spec} ${mode} --program '$^X -I${root_dir}/lib ${root_dir}/script/pmarkdown -m $opt{mode} -o warn_for_unused_input=0'";
  is($test_suite_output, 0, "$opt{spec_name} test suite");
}

sub test_suite {
  my (%opt) = @_;

  if ($opt{use_full_spec}) {
    full_test(%opt);
  } else {
    my $pmarkdown = Markdown::Perl->new(mode => $opt{mode}, warn_for_unused_input => 0);
    json_test($pmarkdown, %opt);
  }
}
