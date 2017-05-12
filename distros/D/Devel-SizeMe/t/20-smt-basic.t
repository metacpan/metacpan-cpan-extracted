use Test::More;
use lib qw(t/lib);
use SizemeTest;

run_test_group(lines => [<DATA>]);

done_testing;

__DATA__
pushnode,'root node',NPtype_NAME
addsize,'size attr on root',3
addattr,NPattr_LABEL,'label on root',0

pushlink,'l1'
pushnode,'l1/n11',NPtype_NAME

pushlink,'l1/n11/l111'
pushnode,'l1/n11/l111/n1111',NPtype_NAME
addsize,'size on l1/n1/l2/n2',4

popnode
popnode
addattr,NPattr_NOTE,'n',101
addattr,NPattr_NOTE,'i',0

popnode
popnode

addsize,'another size attr on root',10

pushlink,'l2'
pushnode,'l2/n21',NPtype_NAME
addattr,NPattr_NOTE,'n',101

pushlink,'l2/n21/l211'
pushnode,'l2/n21/l211/n2111',NPtype_NAME
addattr,NPattr_NOTE,'i',0
addsize,'size',5

popnode
popnode

pushlink,'l2/n21/l212'
pushnode,'l2/n21/l212/n2121',NPtype_NAME
addattr,NPattr_NOTE,'i',1
addsize,'size',5
