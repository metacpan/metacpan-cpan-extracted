package GuacLite::Util;

use Mojo::Template;
use Mojo::File;

my $template = <<'END';
'use strict';
window.Guacamole = window.Guacamole || {};
window.Guacamole.initialize = function () {(function (Guacamole) {

% for my $file ($_[0]->each) {
/* SOURCE: <%= $file->basename %> */
%= $file->slurp
% }
})(window.Guacamole)};
END

sub pack_js {
  my $dir = Mojo::File->new(shift);
  my $files = $dir->list->grep(qr/\.js$/);
  return Mojo::Template->new->render($template, $files);
}

1;

