package ExtUtils::ModuleMaker::Alt_block_new_method;
use strict;
local $^W = 1;
use File::Path;
use Carp;


=head3 C<block_new_method()>

  Usage     : $self->block_new_method() within text_pm_file()
  Purpose   : Build 'new()' method as part of a pm file
  Returns   : String holding sub new.
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass,
              e.g., pass a single hash-ref to new() instead of a list of
              parameters.

=cut

sub block_new_method {
    my $self = shift;
    return <<'EOFBLOCK';

sub new {
    my $class = shift;
    my $self = bless ({}, $class);
    return $self;
}

EOFBLOCK
}


1;

