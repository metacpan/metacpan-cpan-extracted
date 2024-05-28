package Dist::Zilla::Util 6.032;
# ABSTRACT: random snippets of code that Dist::Zilla wants

use Dist::Zilla::Pragmas;

use Carp ();
use Encode ();

use namespace::autoclean;

{
  package
    Dist::Zilla::Util::PEA;
  @Dist::Zilla::Util::PEA::ISA = ('Pod::Simple');

  sub _new  {
    my ($class, @args) = @_;
    require Pod::Simple;
    my $parser = $class->new(@args);
    $parser->code_handler(sub {
      my ($line, $line_number, $parser) = @_;
      return if $parser->{abstract};


      return $parser->{abstract} = $1
        if $line =~ /^\s*#+\s*ABSTRACT:[ \t]*(\S.*)$/m;
      return;
    });
    return $parser;
  }

  sub _handle_element_start {
    my ($parser, $ele_name, $attr) = @_;

    if ($ele_name eq 'head1') {
      $parser->{buffer} = "";
    }
    elsif ($ele_name eq 'Para') {
      $parser->{buffer} = "";
    }
    elsif ($ele_name eq 'C') {
      $parser->{in_C} = 1;
    }

    return;
  }

  sub _handle_element_end {
    my ($parser, $ele_name, $attr) = @_;

    return if $parser->{abstract};
    if ($ele_name eq 'head1') {
      $parser->{in_section} = $parser->{buffer};
    }
    elsif ($ele_name eq 'Para' && $parser->{in_section} eq 'NAME' ) {
      if ($parser->{buffer} =~ /^(?:\S+\s+)+?-+\s+(.+)$/s) {
        $parser->{abstract} = $1;
      }
    }
    elsif ($ele_name eq 'C') {
      delete $parser->{in_C};
    }

    return;
  }

  sub _handle_text {
    my ($parser, $text) = @_;

    # The C<...> tags are expected to be preserved. MetaCPAN renders them.
    if ($parser->{in_C}) {
      $parser->{buffer} .= "C<$text>";
    }
    else {
      $parser->{buffer} .= $text;
    }
    return;
  }
}

#pod =method abstract_from_file
#pod
#pod This method, I<which is likely to change or go away>, tries to guess the
#pod abstract of a given file, assuming that it's Perl code.  It looks for a POD
#pod C<=head1> section called "NAME" or a comment beginning with C<ABSTRACT:>.
#pod
#pod =cut

sub abstract_from_file {
  my ($self, $file) = @_;
  my $e = Dist::Zilla::Util::PEA->_new;

  $e->parse_string_document($file->content);

  return $e->{abstract};
}

#pod =method expand_config_package_name
#pod
#pod   my $pkg_name = Dist::Zilla::Util->expand_config_package_name($string);
#pod
#pod This method, I<which is likely to change or go away>, rewrites the given string
#pod into a package name.
#pod
#pod Prefixes are rewritten as follows:
#pod
#pod =for :list
#pod * C<=> becomes nothing
#pod * C<@> becomes C<Dist::Zilla::PluginBundle::>
#pod * C<%> becomes C<Dist::Zilla::Stash::>
#pod * otherwise, C<Dist::Zilla::Plugin::> is prepended
#pod
#pod =cut

use String::RewritePrefix 0.006 rewrite => {
  -as => '_expand_config_package_name',
  prefixes => {
    '=' => '',
    '@' => 'Dist::Zilla::PluginBundle::',
    '%' => 'Dist::Zilla::Stash::',
    ''  => 'Dist::Zilla::Plugin::',
  },
};

sub expand_config_package_name {
  shift; goto &_expand_config_package_name
}

sub homedir {
  $^O eq 'MSWin32' && "$]" < 5.016 ? $ENV{HOME} || $ENV{USERPROFILE} : (glob('~'))[0];
}

sub _global_config_root {
  require Dist::Zilla::Path;
  return Dist::Zilla::Path::path($ENV{DZIL_GLOBAL_CONFIG_ROOT}) if $ENV{DZIL_GLOBAL_CONFIG_ROOT};

  my $homedir = homedir();
  Carp::croak("couldn't determine home directory") if not $homedir;

  return Dist::Zilla::Path::path($homedir)->child('.dzil');
}

sub _assert_loaded_class_version_ok {
  my ($self, $pkg, $version) = @_;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->from_string_hash({
    $pkg => $version,
  });

  my $have_version = $pkg->VERSION;
  unless ($req->accepts_module($pkg => $have_version)) {
    die( sprintf
      "%s version (%s) does not match required version: %s\n",
      $pkg,
      $have_version // 'undef',
      $version,
    );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util - random snippets of code that Dist::Zilla wants

=head1 VERSION

version 6.032

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 abstract_from_file

This method, I<which is likely to change or go away>, tries to guess the
abstract of a given file, assuming that it's Perl code.  It looks for a POD
C<=head1> section called "NAME" or a comment beginning with C<ABSTRACT:>.

=head2 expand_config_package_name

  my $pkg_name = Dist::Zilla::Util->expand_config_package_name($string);

This method, I<which is likely to change or go away>, rewrites the given string
into a package name.

Prefixes are rewritten as follows:

=over 4

=item *

C<=> becomes nothing

=item *

C<@> becomes C<Dist::Zilla::PluginBundle::>

=item *

C<%> becomes C<Dist::Zilla::Stash::>

=item *

otherwise, C<Dist::Zilla::Plugin::> is prepended

=back

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
