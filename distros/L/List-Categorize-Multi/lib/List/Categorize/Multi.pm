package List::Categorize::Multi;
use Carp                  qw/carp/;
use List::Categorize 0.04 qw/categorize/;
use Exporter qw/import/;

our $VERSION = '0.03';
our @EXPORT_OK = qw/categorize/; # re-export the subroutine from List::Categorize

carp "List::Categorize::Multi is deprecated; use List::Categorize 0.04 instead";

1;

__END__

=head1 NAME

List::Categorize::Multi - deprecated

=head1 DESCRIPTION

This module is B<deprecated>. 
Multi-level categorization is now supported directly within
L<List::Categorize> (since version 0.04).

=cut


