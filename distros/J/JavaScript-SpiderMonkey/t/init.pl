
use JavaScript::SpiderMonkey;

my $docloc = "http://wurks";
$js = JavaScript::SpiderMonkey->new();
$js->init();

$js->property_by_path("navigator.appName");
$js->property_by_path("navigator.userAgent");
$js->property_by_path("navigator.appVersion");
$js->property_by_path("document.cookie");
$js->property_by_path("parent.location");
$js->property_by_path("document.location.href");

my $doc = $js->object_by_path("document");
$js->function_set("write", sub { $buffer .= join('', @_) }, $doc);
$buffer = "";

$init = <<EOT;
  navigator.appName      = "Netscape";
  navigator.appVersion   = "3";
  navigator.userAgent    = "Grugenheimer";
  document.cookie        = "";
  parent.location        = "";
  document.location.href = "$docloc";
  document.form = new Array(100);
EOT

