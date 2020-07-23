package ExtUtils::MakeMaker::PPPort;

use strict;
use warnings;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:ATOOMIC';

# ABSTRACT: ExtUtils::MakeMaker when using Devel-PPPort

use ExtUtils::MakeMaker ();

=head1 SYNOPSIS

  # Makefile.PL
  use ExtUtils::MakeMaker::PPPort;

  WriteMakefile(
    NAME           => 'Foo::Bar',
    ...
    MIN_PPPORT_VERSION => 3.58, # optional
  );

=head1 DESCRIPTION

This module allows you to use an up to date version of ppport.h
when using Devel-PPPort.

You do not need to ship an old version of `ppport.h` with your codebase.


=head1 Migration to ExtUtils::MakeMaker::PPPort

You want to remove `ppport.h` from your directory and ignore it in your version control.

  rm -f ppport.h
  echo 'ppport.h' >> .gitignore

Then you can start using `ExtUtils::MakeMaker::PPPort` instead of `ExtUtils::MakeMaker`.

=cut

use constant LAST_KNOWN_PPPORT_VERSION => 3.58;

our $MIN_PPPORT_VERSION = LAST_KNOWN_PPPORT_VERSION;    # last known version

sub import {
    my ( $class, @import_opts ) = @_;
    my $orig = 'ExtUtils::MakeMaker'->can('WriteMakefile') or die;
    ExtUtils::MakeMaker->export_to_level( 1, $class, @import_opts );

    my $writer = sub {
        my %params = @_;

        # Do nothing if not called from Makefile.PL
        #my ($caller, $file, $line) = caller;
        #(my $root = rel2abs($file)) =~ s/Makefile\.PL$//i or return;

        $MIN_PPPORT_VERSION = delete $params{MIN_PPPORT_VERSION};
        $MIN_PPPORT_VERSION = LAST_KNOWN_PPPORT_VERSION unless defined $MIN_PPPORT_VERSION;

        # Build requires => BUILD_REQUIRES / PREREQ_PM
        _merge(
            \%params,
            { 'Devel-PPPort' => $MIN_PPPORT_VERSION },
            _eumm('6.56') ? 'BUILD_REQUIRES' : 'PREREQ_PM',
        );

        $orig->(%params);
    };

    # redefine the WriteMakefile sub
    {
        no warnings 'redefine';
        *main::WriteMakefile = *ExtUtils::MakeMaker::WriteMakefile = $writer;
    }
}

sub _eumm {
    my $version = shift;
    eval { ExtUtils::MakeMaker->VERSION($version) } ? 1 : 0;
}

sub _merge {
    my ( $params, $requires, $key ) = @_;

    return unless $key;

    for ( keys %{ $requires || {} } ) {
        my $version = _normalize_version( $requires->{$_} );
        next unless defined $version;

        $params->{$key}{$_} = $version;
    }
}

sub _normalize_version {
    my $version = shift;

    # shortcuts
    return unless defined $version;
    return $version unless $version =~ /\s/;

    # TODO: better range handling
    $version =~ s/(?:>=|==)\s*//;
    $version =~ s/,.+$//;

    return $version unless $version =~ /\s/;
    return;
}

{
    package    # hide from PAUSE
      MY;

    sub top_targets {

        my $content = shift->SUPER::top_targets(@_);

        $content =~ s{^(pure_all\s*::\s*)}{${1}ppport }m;
        return $content;
    }

    sub clean {
        my $content = shift->SUPER::clean(@_);
        $content =~ s{^(clean\s*::\s*)}{${1}ppport_clean }m;
        return $content;
    }

    sub postamble {
        my ( $self, %extra ) = @_;

        my $post        = $self->SUPER::postamble(%extra);
        my $min_version = $extra{MIN_DEVEL_PPPORT} || 0;

        $post .= <<'POSTAMBLE';

# ppport targets

.PHONY: ppport ppport_version ppport_clean

ppport: ppport_version ppport.h
~TAB~$(NOECHO) $(NOOP)

ppport_version:
~TAB~@$(PERL) -I$(INST_LIB) -MDevel::PPPort -e 'die qq[Needs Devel-PPPort version >= ~MIN_DEVEL_PPPORT~ # got $$Devel::PPPort::VERSION] unless $$Devel::PPPort::VERSION >= ~MIN_DEVEL_PPPORT~'

ppport_clean:
~TAB~- $(RM_F) ppport.h

ppport.h :
~TAB~@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MDevel::PPPort -e'Devel::PPPort::WriteFile'

POSTAMBLE

        $post =~ s{~MIN_DEVEL_PPPORT~}{$MIN_PPPORT_VERSION}g;
        $post =~ s{~TAB~}{\t}g;

        return $post;
    }


  sub dynamic
  {
    my $content = shift->SUPER::dynamic(@_);

    $content =~ s{^(dynamic\s*::\s*)}{${1}ppport }m;

    return $content;
  }

}

1;

__END__

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/atoomic/ExtUtils-MakeMaker-PPPort/issues>.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

L<Devel::PPPort>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc ExtUtils::MakeMaker::PPPort

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/ExtUtils-MakeMaker-PPPort>

=item * Github

L<https://github.com/atoomic/ExtUtils-MakeMaker-PPPort>

=item * Issues

L<https://github.com/atoomic/ExtUtils-MakeMaker-PPPort/issues>

=back

=cut
