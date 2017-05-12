package Mason::Plugin::SliceFilter::Filters;
use Mason::PluginRole;

use Mason::Plugin::SliceFilter::Filters::Slice;

method Slice(%args){
  return Mason::Plugin::SliceFilter::Filters::Slice->new(%args);
}

1;
__END__

=head1 NAME

Mason::Plugin::SliceFilter::Filters - Mason Filter plugin Glue

=cut
