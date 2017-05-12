use warnings;
use strict;

use Test::More tests => 7;

use_ok('URI',1.56);
require_ok('JSON::RPC::LWP');

my $rpc = new_ok 'JSON::RPC::LWP';

use FindBin;
use File::Spec;

# file:// transport does't handle POST requests
$rpc->prefer_get(1);

my $error_file = File::Spec->catfile($FindBin::Bin,'error.json');
my $fine_file  = File::Spec->catfile($FindBin::Bin,'fine.json');
my $empty_file = File::Spec->catfile($FindBin::Bin,'empty.json');

my $error_text =
qq[{"jsonrpc":"2.0","error":{"data":null,"message":"error","code":101},"id":1}\n];
my $fine_text = qq[{"jsonrpc":"2.0","id":2,"result":"fine"}\n];

SKIP: {
  note 'Checking ->call with an error response';
  open my $fh, '>', $error_file
    or skip "error creating $error_file", 1;

  print {$fh} $error_text
    or skip "error printing to $error_file", 1;

  close $fh
    or skip "error closing $error_file", 1;

  my $error = $rpc->call("file://${FindBin::Bin}/error.json",'test');
  ok $error->has_error, 'test for returned errors from ->call';
}
SKIP: {
  note 'Checking ->call with a regular response';
  open my $fh, '>', $fine_file
    or skip "error creating $fine_file", 1;

  print {$fh} $fine_text
    or skip "error printing to $fine_file", 1;

  close $fh
    or skip "error closing $fine_file", 1;

  my $fine = $rpc->call("file://${FindBin::Bin}/fine.json",'test');
  ok $fine->has_result, 'test for normal return value from ->call';
}
SKIP: {
  note 'Checking ->notify with a normal response';
  open my $fh, '>', $empty_file
    or skip "error creating $empty_file", 1;

  print {$fh} ''
    or skip "error printing to $empty_file", 1;

  close $fh
    or skip "error closing $empty_file", 1;

  my $blank = $rpc->notify("file://${FindBin::Bin}/empty.json",'test');
  ok $blank->is_success, 'test for normal return value from ->notify';
}
SKIP: {
  note 'Checking ->notify with an error response';

  my $blank = $rpc->notify("file://${FindBin::Bin}/nonexistent",'test');
  ok $blank->is_error, 'test for error return value from ->notify';
}
