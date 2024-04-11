# A package to execute the a test suite based on a Markdown file containing
# alternating code snippets in Markdown and HTML. Where the HTML is supposedly
# what the tool must render given the Markdown input.
#
# This is typically the syntax of our Syntax.md file.
#
# This test looks for successive fenced code spans at the root level of the
# document, one with an `md` info string and then one with an `html` info
# string, that are not separated by any other Markdown construct except
# paragraphs of texts. When found, the content of the two code-spans are used as
# the definition of a test.
#
# The most recently seen header (at any level) is used as the name of the test.

package PmarkdownTest;

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

sub md_blocks_to_tests {
  my (@blocks) = @_;
  my @output;
  my $title;
  my %test;
  my $i = 1;
  for my $bl (@blocks) {
    if ($bl->{type} eq 'heading') {
      undef %test;
      $title = $bl->{content};
    } elsif ($bl->{type} eq 'code') {
      if ($bl->{info} =~ m/^md(?:\s+(?<inline>inline))?\s*$/) {
        %test = (md => $bl->{content}, inline => !!(defined $+{inline}));
      } elsif ($bl->{info} eq 'html' && %test) {
        push @output, { %test, html => $bl->{content}, title => $title, index => $i++ };
        undef %test;
      } else {
        undef %test;
      }
    } elsif ($bl->{type} ne 'paragraph') {
      undef %test;
    }
  }
  return @output;
}

sub test_suite {
  my (%opt) = @_;

  my $test_data;
  {
    local $/ = undef;
    open my $f, '<:encoding(utf-8)', $opt{md_file};
    my $md_data = <$f>;
    close $f;
    # TODO: possibly we want a different object here
    my $parser = Markdown::Perl->new(mode => $opt{file_parse_mode});
    $test_data = $parser->_parse($md_data);
  }

  my @tests = md_blocks_to_tests(@{$test_data});

  my $pmarkdown = Markdown::Perl->new(mode => $opt{mode}, warn_for_unused_input => 0);

  my %todo = map { $_ => 1 } @{$opt{todo} // []};
  my %bugs = map { $_ => 1 } @{$opt{bugs} // []};
  for my $t (@tests) {
    next if exists $opt{test_num} && $opt{test_num} != $t->{index};

    my @opt;
    push @opt, render_naked_paragraphs => $t->{inline};
    my $out = $pmarkdown->convert($t->{md}, @opt);
    my $val = sanitize_html($out);
    my $expected = sanitize_html($t->{html});

    my $title = sprintf "%s (%d)", $t->{title}, $t->{index};
    my $test = sub { is($val, $expected, $title, 'Input markdown:', $t->{md}, "\n") };
  
    if ($todo{$t->{index}}) {
      todo 'Not yet supported' => $test;
    } elsif ($bugs{$t->{index}}) {
      todo 'The spec is buggy' => $test;
    } else {
      $test->();
    }
  }
}
