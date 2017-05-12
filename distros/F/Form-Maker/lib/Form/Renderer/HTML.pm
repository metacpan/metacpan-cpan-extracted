package Form::Renderer::HTML;
use base 'Form::Renderer';

sub start { "<form>" }
sub end   { "</form>" }

sub fieldset_start { "\n<!-- begin fields -->\n" }
sub fieldset_end   { "\n<!-- end fields -->\n" }

1;
