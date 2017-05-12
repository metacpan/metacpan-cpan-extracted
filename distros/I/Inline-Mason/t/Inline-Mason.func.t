use Test::More qw(no_plan);
use Inline::Mason;
ok(1);

$hello = <<'.';
% my $noun = 'World';
Hello <% $noun %>!
How are ya?
.

$nifty = <<'.';
<% $ARGS{lang} %> is nifty!
.


like Inline::Mason::execute( $hello ) => qr'World';

$n = Inline::Mason::compile( $nifty );
like $n->(lang => "Perl") => qr'Perl';

like Inline::Mason::execute_file( 't/external_mason', lang => "Perl" ) => qr'nifty!';
