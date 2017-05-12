use strict;
use Test::More 'no_plan';

use MSIE::MenuExt;

my $action = MSIE::MenuExt::Action->new();
$action->title('Blog It!');
$action->accesskey('B');
$action->action('javascript:external.menuArguments.blahblah()');
$action->context(MENUEXT_DEFAULT + MENUEXT_TEXT_SELECTIONS);

my $reg = MSIE::MenuExt->new();
$reg->add_action($action);

is($reg->content(), catfile("t/01.reg"));

sub catfile {
    my $file = shift;
    open FILE, $file;
    binmode FILE; # for Win32
    my $content = do { local $/; <FILE>; };
    close FILE;
    return $content;
}
