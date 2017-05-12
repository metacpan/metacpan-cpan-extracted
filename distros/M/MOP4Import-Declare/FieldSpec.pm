package MOP4Import::FieldSpec; sub FieldSpec () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Exporter qw/import/;

our @EXPORT_OK = qw/FieldSpec/;
our @EXPORT = @EXPORT_OK;

use fields
  ('name'
   , 'doc' # documentation
   , 'default'
   , 'no_getter'
   # file? line? package?
 );

sub new {
  my FieldSpec $self = fields::new(shift);
  %$self = @_;
  $self;
}

1;
