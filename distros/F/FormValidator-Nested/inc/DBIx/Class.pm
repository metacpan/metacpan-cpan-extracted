#line 1
package DBIx::Class;

use strict;
use warnings;

use MRO::Compat;

use vars qw($VERSION);
use base qw/DBIx::Class::Componentised Class::Accessor::Grouped/;
use DBIx::Class::StartupCheck;

sub mk_classdata {
  shift->mk_classaccessor(@_);
}

sub mk_classaccessor {
  my $self = shift;
  $self->mk_group_accessors('inherited', $_[0]);
  $self->set_inherited(@_) if @_ > 1;
}

sub component_base_class { 'DBIx::Class' }

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too

$VERSION = '0.08111';

$VERSION = eval $VERSION; # numify for warning-free dev releases

# what version of sqlt do we require if deploy() without a ddl_dir is invoked
# when changing also adjust $sqlt_recommends in Makefile.PL
my $minimum_sqlt_version = '0.11002';

sub MODIFY_CODE_ATTRIBUTES {
  my ($class,$code,@attrs) = @_;
  $class->mk_classdata('__attr_cache' => {})
    unless $class->can('__attr_cache');
  $class->__attr_cache->{$code} = [@attrs];
  return ();
}

sub _attr_cache {
  my $self = shift;
  my $cache = $self->can('__attr_cache') ? $self->__attr_cache : {};
  my $rest = eval { $self->next::method };
  return $@ ? $cache : { %$cache, %$rest };
}

# SQLT version handling
{
  my $_sqlt_version_ok;     # private
  my $_sqlt_version_error;  # private

  sub _sqlt_version_ok {
    if (!defined $_sqlt_version_ok) {
      eval "use SQL::Translator $minimum_sqlt_version";
      if ($@) {
        $_sqlt_version_ok = 0;
        $_sqlt_version_error = $@;
      }
      else {
        $_sqlt_version_ok = 1;
      }
    }
    return $_sqlt_version_ok;
  }

  sub _sqlt_version_error {
    shift->_sqlt_version_ok unless defined $_sqlt_version_ok;
    return $_sqlt_version_error;
  }

  sub _sqlt_minimum_version { $minimum_sqlt_version };
}


1;

#line 397
