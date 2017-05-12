use Test::More tests=> 20;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $pkg= 'Egg::Plugin::WYSIWYG::FCKeditor';

require_ok $pkg;

ok my $e= Egg::Helper->run
  ( Vtest => { vtest_plugins=> [qw/ WYSIWYG::FCKeditor Tools /] }),
  'Constructor';

isa_ok $e, $pkg;

can_ok $e, 'fck';
  ok my $fck= $e->fck, q{my $fck= $e->fck};
  isa_ok $fck, "${pkg}::handler";

can_ok $fck, 'is_compat';
  ok ! $fck->is_compat, q{! $fck->is_compat};
  delete $fck->{is_compat};
  $ENV{HTTP_USER_AGENT}= 'MSIE 5.5';
  ok $fck->is_compat, q{$fck->is_compat};

can_ok $fck, 'html';
  ok my $html= $fck->html, q{my $html= $fck->html};
  ok my $instance= $fck->param('instance'), q{my $instance= $html->param('instance')};
  like $html, qr{<textarea\s+id=\"$instance\".+}s;
  $fck->{is_compat}= 0;
  ok $html= $fck->html, q{my $html= $fck->html};
  like $html, qr{<input\s+type=\"hidden\"\s+id=\"$instance\"}s,
       qq{qr{<input\\s+type=\\"hidden\\"\\s+id=\\"$instance\\"}};
  like $html, qr{<iframe\s+id=\"${instance}___Frame\"\s+}s,
       qq{qr{<iframe\\s+id=\"\\${instance}___Frame\"\\s+}};

can_ok $fck, 'js';
  ok $html= $fck->js, q{$html= $fck->js};
  like $html, qr{<script\s+.+?fckeditor\.js}s,
     qq{qr{<script\\s+.+?fckeditor\.js}};
  like $html, qr{var\s+oFCKeditor\s*\=\s+new\s+FCKeditor\(\'$instance\'\)}s,
     qq{qr{var\\s+oFCKeditor\\s*\\=\\s+new\\s+FCKeditor\\(\\'$instance\\'\\)}};

