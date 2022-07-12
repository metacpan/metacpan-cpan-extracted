use strict;
use warnings;
use Test::More;

sub qmre {
  my $text = shift;
  $text =~ s{([^ !"#%&',/0-9:;<=>`A-Z~^_a-z-])}{\\$1}g;
  return $text;
}
sub tags_re ($) {
  my $tags = shift;
  my @tags = split /\n/, $tags;
  s{\A\s+}{}, s{\s+\z}{} for @tags;
  my ($re) = map qr{$_}, join '', map qmre($_), @tags;
  return $re;
}

{
  BEGIN {
    package ParserWithExtraTargets;
    use Moo;
    extends 'Pod::Simple::XHTML';
    with 'Pod::Simple::Role::XHTML::WithExtraTargets';
  }

  my $parser = ParserWithExtraTargets->new;

  $parser->html_footer('');
  $parser->html_header('');
  $parser->anchor_items(1);

  $parser->output_string( \(my $output = '') );
  my $pod = <<'END_POD';
    =head1 NAME

    Pod::Document - With an abstract

    =head1 SYNOPSIS

      welp();

    =head1 METHODS

    =head2 $self->some_method( \%options );

    =head2 options ( $options )

    =head1 options

    There are options.

    =over 4

    =item another_method & B<has extra gunk>

    =back

    =head1 yet_another_method & B<has extra gunk>

    =cut
END_POD
  $pod =~ s/^    //mg;
  $parser->parse_string_document($pod);

  like $output, qr/Pod::Document/;

  like $output, tags_re q{
    <h2 id="self-some_method-options">
    <a id="$self-&gt;some_method(-\%options-);"></a>
    <a id="some_method"></a>
  };
}

{
  BEGIN {
    package ParserWithAccurateAndExtraTargets;
    use Moo;
    extends 'Pod::Simple::XHTML';
    with 'Pod::Simple::Role::XHTML::WithExtraTargets';
    with 'Pod::Simple::Role::XHTML::WithAccurateTargets';
  }

  my $parser = ParserWithAccurateAndExtraTargets->new;

  $parser->html_footer('');
  $parser->html_header('');
  $parser->anchor_items(1);

  $parser->output_string( \(my $output = '') );
  my $pod = <<'END_POD';
    =head1 NAME

    Pod::Document - With an abstract

    =head1 SYNOPSIS

      welp();

    =head1 METHODS

    =head2 $self->some_method( \%options );

    =head2 options ( $options )

    =head1 options

    There are options.

    =over 4

    =item another_method & B<has extra gunk>

    =back

    =head1 yet_another_method & B<has extra gunk>

    =cut
END_POD
  $pod =~ s/^    //mg;
  $parser->parse_string_document($pod);

  like $output, qr/Pod::Document/;
  like $output, tags_re q{
    <h2 id="$self-&gt;some_method(-\%options-);">
    <a id="some_method"></a>
    <a id="self-some_method-options"></a>
  };
  like $output, tags_re q{
    <h1 id="options">
  };
  like $output, tags_re q{
    <h2 id="options-(-$options-)"><a id="options1"></a><a id="options-options"></a>
  };
  like $output, tags_re q{
    <dt id="another_method-&amp;-has-extra-gunk">
    <a id="another_method"></a>
    <a id="another_method-has-extra-gunk"></a>
  };
  like $output, tags_re q{
    <h1 id="yet_another_method-&amp;-has-extra-gunk">
    <a id="yet_another_method"></a>
    <a id="yet_another_method-has-extra-gunk"></a>
  };
}

done_testing;
