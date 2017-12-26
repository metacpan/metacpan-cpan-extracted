package ExtUtils::MakeMaker::Attributes;

use strict;
use warnings;
use Carp;
use Exporter 'import';
use Module::CoreList;
use version;

our $VERSION = '0.001';

my @exports = qw(
  known_eumm_attributes is_known_eumm_attribute
  eumm_attribute_requires_version eumm_attribute_fallback
  eumm_version_supported_attributes eumm_version_supports_attribute
  perl_version_supported_attributes perl_version_supports_attribute
);
our @EXPORT_OK = @exports;
our %EXPORT_TAGS = (all => \@exports);

my %attributes = (
  ABSTRACT => {},
  ABSTRACT_FROM => {},
  AUTHOR => {},
  BINARY_LOCATION => {},
  BUILD_REQUIRES => {
    requires => '6.55_03',
    fallback => {method => 'merge_prereqs', merge_target => 'PREREQ_PM'},
  },
  C => {},
  CCFLAGS => {},
  CONFIG => {},
  CONFIGURE => {},
  CONFIGURE_REQUIRES => {requires => '6.52'},
  DEFINE => {},
  DESTDIR => {},
  DIR => {},
  DISTNAME => {},
  DISTVNAME => {},
  DLEXT => {},
  DL_FUNCS => {},
  DL_VARS => {},
  EXCLUDE_EXT => {},
  EXE_FILES => {},
  FIRST_MAKEFILE => {},
  FULLPERL => {},
  FULLPERLRUN => {},
  FULLPERLRUNINST => {},
  FUNCLIST => {},
  H => {},
  IMPORTS => {},
  INC => {},
  INCLUDE_EXT => {},
  INSTALLARCHLIB => {},
  INSTALLBIN => {},
  INSTALLDIRS => {},
  INSTALLMAN1DIR => {},
  INSTALLMAN3DIR => {},
  INSTALLPRIVLIB => {},
  INSTALLSCRIPT => {},
  INSTALLSITEARCH => {},
  INSTALLSITEBIN => {},
  INSTALLSITELIB => {},
  INSTALLSITEMAN1DIR => {},
  INSTALLSITEMAN3DIR => {},
  INSTALLSITESCRIPT => {requires => '6.30_02'},
  INSTALLVENDORARCH => {},
  INSTALLVENDORBIN => {},
  INSTALLVENDORLIB => {},
  INSTALLVENDORMAN1DIR => {},
  INSTALLVENDORMAN3DIR => {},
  INSTALLVENDORSCRIPT => {requires => '6.30_02'},
  INST_ARCHLIB => {},
  INST_BIN => {},
  INST_LIB => {},
  INST_MAN1DIR => {},
  INST_MAN3DIR => {},
  INST_SCRIPT => {},
  LD => {},
  LDDLFLAGS => {},
  LDFROM => {},
  LIB => {},
  LIBPERL_A => {},
  LIBS => {},
  LICENSE => {requires => '6.31'},
  LINKTYPE => {},
  MAGICXS => {requires => '6.8305'},
  MAKE => {requires => '6.30_01'},
  MAKEAPERL => {},
  MAKEFILE_OLD => {},
  MAN1PODS => {},
  MAN3PODS => {},
  MAP_TARGET => {},
  META_ADD => {requires => '6.46'},
  META_MERGE => {requires => '6.46'},
  MIN_PERL_VERSION => {requires => '6.48'},
  MYEXTLIB => {},
  NAME => {},
  NEEDS_LINKING => {},
  NOECHO => {},
  NORECURS => {},
  NO_META => {},
  NO_MYMETA => {requires => '6.57_02'},
  NO_PACKLIST => {requires => '6.7501'},
  NO_PERLLOCAL => {requires => '6.7501'},
  NO_VC => {},
  OBJECT => {},
  OPTIMIZE => {},
  PERL => {},
  PERL_CORE => {},
  PERLMAINCC => {},
  PERL_ARCHLIB => {},
  PERL_LIB => {},
  PERL_MALLOC_OK => {},
  PERLPREFIX => {},
  PERLRUN => {},
  PERLRUNINST => {},
  PERL_SRC => {},
  PERM_DIR => {requires => '6.51_01'},
  PERM_RW => {},
  PERM_RWX => {},
  PL_FILES => {},
  PM => {},
  PMLIBDIRS => {},
  PM_FILTER => {},
  POLLUTE => {},
  PPM_INSTALL_EXEC => {},
  PPM_INSTALL_SCRIPT => {},
  PPM_UNINSTALL_EXEC => {requires => '6.8502'},
  PPM_UNINSTALL_SCRIPT => {requires => '6.8502'},
  PREFIX => {},
  PREREQ_FATAL => {},
  PREREQ_PM => {},
  PREREQ_PRINT => {},
  PRINT_PREREQ => {},
  SITEPREFIX => {},
  SIGN => {requires => '6.18'},
  SKIP => {},
  TEST_REQUIRES => {
    requires => '6.64',
    fallback => {method => 'merge_prereqs', merge_target => 'PREREQ_PM'},
  },
  TYPEMAPS => {},
  VENDORPREFIX => {},
  VERBINST => {},
  VERSION => {},
  VERSION_FROM => {},
  VERSION_SYM => {},
  XS => {},
  XSBUILD => {requires => '7.12'},
  XSMULTI => {requires => '7.12'},
  XSOPT => {},
  XSPROTOARG => {},
  XS_VERSION => {},
  clean => {},
  depend => {},
  dist => {},
  dynamic_lib => {},
  linkext => {},
  macro => {},
  postamble => {},
  realclean => {},
  test => {},
  tool_autosplit => {},
);

sub known_eumm_attributes {
  no locale;
  return sort keys %attributes;
}

sub is_known_eumm_attribute {
  my ($attribute) = @_;
  return !!(defined $attribute && exists $attributes{$attribute});
}

sub eumm_attribute_requires_version {
  my ($attribute) = @_;
  croak "Unknown ExtUtils::MakeMaker attribute $attribute"
    unless is_known_eumm_attribute($attribute);
  return $attributes{$attribute}{requires} || 0;
}

sub eumm_attribute_fallback {
  my ($attribute) = @_;
  croak "Unknown ExtUtils::MakeMaker attribute $attribute"
    unless is_known_eumm_attribute($attribute);
  if (defined(my $fallback = $attributes{$attribute}{fallback})) {
    return +{%$fallback};
  }
  return undef;
}

sub eumm_version_supports_attribute {
  my ($attribute, $eumm_version) = @_;
  return 0 unless is_known_eumm_attribute($attribute);
  my $required_version = eumm_attribute_requires_version($attribute) || return 1;
  return version->parse($eumm_version || 0) >= version->parse($required_version) ? 1 : 0;
}

sub perl_version_supports_attribute {
  my ($attribute, $perl_version) = @_;
  return eumm_version_supports_attribute($attribute, _eumm_version_for_perl($perl_version));
}

sub eumm_version_supported_attributes {
  my ($eumm_version) = @_;
  $eumm_version = version->parse($eumm_version || 0);
  my @supported;
  foreach my $attribute (known_eumm_attributes()) {
    if (my $required_version = eumm_attribute_requires_version($attribute)) {
      push @supported, $attribute if $eumm_version >= version->parse($required_version);
    } else {
      push @supported, $attribute;
    }
  }
  return @supported;
}

sub perl_version_supported_attributes {
  return eumm_version_supported_attributes(_eumm_version_for_perl(@_));
}

sub _eumm_version_for_perl {
  my ($perl_version) = @_;
  my $module_versions = Module::CoreList::find_version($perl_version) || return 0;
  return $module_versions->{'ExtUtils::MakeMaker'} || 0;
}

1;

=head1 NAME

ExtUtils::MakeMaker::Attributes - Determine when ExtUtils::MakeMaker attributes
are available

=head1 SYNOPSIS

  use ExtUtils::MakeMaker::Attributes ':all';
  
  my @eumm_available = eumm_version_supported_attributes(ExtUtils::MakeMaker->VERSION);
  my @core_available = perl_version_supported_attributes($]);
  
  unless (perl_version_supports_attribute('v5.10.1', 'TEST_REQUIRES')) {
    ...
  }
  
  my $fallback = eumm_attribute_fallback('TEST_REQUIRES');
  my $required_eumm = eumm_attribute_requires_version('TEST_REQUIRES');
  unless (eval { ExtUtils::MakeMaker->VERSION($required_eumm); 1 }) {
    ...
  }

=head1 DESCRIPTION

This module provides an API to determine what attributes are available to a
particular version of L<ExtUtils::MakeMaker>, and conversely, what version of
L<ExtUtils::MakeMaker> is required for a particular attribute. See
L<ExtUtils::MakeMaker/"Using Attributes and Parameters"> for more details on
the available attributes.

=head1 FUNCTIONS

All functions are exported on demand, and can be exported individually or via
the C<:all> tag.

=head2 known_eumm_attributes

  my @attributes = known_eumm_attributes;

Returns a list of attributes known to be accepted by the latest version of
L<ExtUtils::MakeMaker>.

=head2 is_known_eumm_attribute

  my $boolean = is_known_eumm_attribute($attribute);

Returns a boolean whether the attribute is known to be accepted by the latest
version of L<ExtUtils::MakeMaker>.

=head2 eumm_attribute_requires_version

  my $version = eumm_attribute_requires_version($attribute);

Returns the minimum version of L<ExtUtils::MakeMaker> that accepts the
attribute.

=head2 eumm_attribute_fallback

  my $hashref = eumm_attribute_fallback($attribute);

In cases where the active version of L<ExtUtils::MakeMaker> does not support an
attribute, the attribute should be deleted from the options passed to
C<WriteMakefile>. However, some attributes may still be useful in other ways,
as indicated by this function. If the attribute has an associated fallback
method, it returns a hashref containing a C<method> and possibly other related
keys. Otherwise, it returns C<undef>. Currently it may return these methods:

=over 2

=item merge_prereqs

The key's contents (as a hashref of prerequisites) should be merged into the
C<merge_target> (returned in the fallback hashref), ideally using
L<CPAN::Meta::Requirements/"add_requirements">.

=back

=head2 eumm_version_supports_attribute

  my $boolean = eumm_version_supports_attribute($attribute, $eumm_version);

Returns a boolean whether the L<ExtUtils::MakeMaker> supports the attribute at
the specified version.

=head2 perl_version_supports_attribute

  my $boolean = perl_version_supports_attribute($attribute, $perl_version);

Returns a boolean whether the version of L<ExtUtils::MakeMaker> shipped in the
specified version of Perl supports the attribute.

=head2 eumm_version_supported_attributes

  my @attributes = eumm_version_supported_attributes($eumm_version);

Returns a list of all attributes supported by the specified version of
L<ExtUtils::MakeMaker>.

=head2 perl_version_supported_attributes

  my @attributes = perl_version_supported_attributes($perl_version);

Returns a list of all attributes supported by the version of
L<ExtUtils::MakeMaker> shipped in the specified version of Perl.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<ExtUtils::MakeMaker>
