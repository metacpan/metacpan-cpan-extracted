use Test::More tests => 4;
use HTML::Template::Expr;

HTML::Template::Expr->register_function(directory_exists => sub {
					  my $dir = shift;
					  return -d $dir;
					});
HTML::Template::Expr->register_function(commify => sub {
					  local $_ = shift;
					  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
					  return $_;
					});
HTML::Template::Expr->register_function(nada => sub { return });

my $template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'register.tmpl',
                                     );
my $output = $template->output;
like $output, qr/^OK/, 'directory_exists()';
like $output, qr/2,000/, 'comify';
like $output, qr/nada worked/, 'nada worked';

eval {
  HTML::Template::Expr->register_function('foo', 'bar');
};
like $@, qr/must be subroutine ref/, 'type check';

