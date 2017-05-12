use Devel::ModInfo;
use strict;

my $mi = new Devel::ModInfo('WordPress::API');
my @functions = $mi->function_descriptors();
my (@methods, @properties);
if ($mi->is_oo) {
          @methods = $mi->method_descriptors;
      @properties = $mi->property_descriptors();
}


