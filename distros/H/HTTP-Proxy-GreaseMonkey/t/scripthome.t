use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Proxy::GreaseMonkey::ScriptHome;
use File::Spec;

my $gm = HTTP::Proxy::GreaseMonkey::ScriptHome->new;
$gm->add_dir( File::Spec->catdir( 't', 'scripts' ) );

my @scripts
  = map { File::Spec->catfile( 't', 'scripts', $_ ) } qw( u1.js u2.js );

my @found = $gm->_walk;
is_deeply \@found, \@scripts, 'found';
is_deeply $gm->{script}, undef, 'empty';
$gm->_reload;
my @scr = @{ $gm->{script} };
is scalar( @scr ), 2, 'loaded 2';
is $scr[0]->file, $scripts[0], 'u1.js';
is $scr[1]->file, $scripts[1], 'u2.js';
