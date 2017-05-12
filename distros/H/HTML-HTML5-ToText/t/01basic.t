use Test::More tests => 6;
BEGIN { use_ok('HTML::HTML5::ToText') };

my $in  = do { local $/ = <DATA> };
my $out = "Hello\n";

is(HTML::HTML5::ToText->new->process_string($in), $out, 'HTML::HTML5::ToText->new->process_string');
is(HTML::HTML5::ToText->process_string($in), $out, 'HTML::HTML5::ToText->process_string');
is(HTML::HTML5::ToText->new_with_traits(traits => [qw/ShowLinks/])->process_string($in), $out, 'HTML::HTML5::ToText->new_with_traits(traits=>\\@traits)->process_string');
is(HTML::HTML5::ToText->with_traits(qw/ShowLinks/)->new->process_string($in), $out, 'HTML::HTML5::ToText->with_traits(@traits)->new->process_string');
is(HTML::HTML5::ToText->with_traits(qw/ShowLinks/)->process_string($in), $out, 'HTML::HTML5::ToText->with_traits(@traits)->process_string');

__DATA__
<p>Hello</p>