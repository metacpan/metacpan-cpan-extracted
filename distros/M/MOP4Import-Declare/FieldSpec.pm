package MOP4Import::FieldSpec; sub FieldSpec () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Exporter qw/import/;

require MOP4Import::Util; # Delay loading

BEGIN {
  our @EXPORT_OK = qw/FieldSpec/;
  our @EXPORT = @EXPORT_OK;
}

use fields
  ('name'
   , 'doc' # documentation
   , 'default'
   , 'no_getter'
   , 'package'
   , 'json_type'
   , 'isa'
   , 'validator'
   , 'zsh_completer'
   , 'extra'
   # file? line? package?
 );

sub new {
  my FieldSpec $self = fields::new(shift);
  %$self = @_;
  $self;
}

sub clone {
  (my FieldSpec $self) = @_;
  my FieldSpec $clone = fields::new(ref $self);
  foreach my $key (keys %$self) {
    my $val = $self->{$key};
    $clone->{$key} = do {
      if (ref $val eq 'CODE') {
        $val
      } else {
        MOP4Import::Util::shallow_copy($val);
      }
    };
  }
  $clone;
}

1;
