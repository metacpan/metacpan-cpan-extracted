package Export::Lexical;

use 5.010;
use strict;
use warnings;
use B;
use Carp;

our $VERSION = '0.0.6';

my %exports_for  = ();
my %modifier_for = ();  # e.g., $modifier_for{$pkg} = 'silent'

sub MODIFY_CODE_ATTRIBUTES {
    my ( $package, $coderef, @attrs ) = @_;

    my @unused_attrs = ();

    while ( my $attr = shift @attrs ) {
        if ( $attr =~ /^Export_?Lexical$/i ) {
            push @{ $exports_for{$package} }, $coderef;
        }
        else {
            push @unused_attrs, $attr;
        }
    }

    return @unused_attrs;
}

sub import {
    my ($class) = @_;

    my $caller = caller;
    my $key    = _get_key($caller);
    my @params = ();

    {
        # Export our subroutines, if necessary.
        no strict 'refs';   ## no critic (ProhibitNoStrict)

        if ( !exists &{ $caller . '::MODIFY_CODE_ATTRIBUTES' } ) {
            *{ $caller . '::MODIFY_CODE_ATTRIBUTES' } = \&MODIFY_CODE_ATTRIBUTES;
        }

        if ( !exists &{ $caller . '::import' } ) {
            *{ $caller . '::import' } = sub {
                my ( $class, @args ) = @_;

                _export_all_to( $caller, scalar caller );

                $^H{$key} = @args ? ( join ',', @args ) : 1;   ## no critic (ProhibitPunctuationVars, RequireLocalizedPunctuationVars)
            };
        }

        if ( !exists &{ $caller . '::unimport' } ) {
            *{ $caller . '::unimport' } = sub {
                my ( $class, @args ) = @_;

                if ( @args ) {
                    # Leave the '1' on the front of the list from a previous 'use
                    # $module', as well as any subs previously imported.
                    $^H{$key} = join ',', $^H{$key}, map { "!$_" } @args;  ## no critic (ProhibitPunctuationVars, RequireLocalizedPunctuationVars)
                }
                else {
                    $^H{$key} = '';    ## no critic (ProhibitPunctuationVars, RequireLocalizedPunctuationVars)
                }
            };
        }
    }

    while ( my $modifier = shift ) {
        if ( $modifier =~ /^:(silent|warn)$/ ) {
            croak qq('$modifier' requested when '$modifier_for{$caller}' already in use)
                if $modifier_for{$caller};

            $modifier_for{$caller} = $modifier;
            next;
        }

        push @params, $modifier;
    }
}

sub _export_all_to {
    my ( $from, $caller ) = @_;

    return if !exists $exports_for{$from};

    for my $ref ( @{ $exports_for{$from} } ) {
        my $obj = B::svref_2object($ref);
        my $pkg = $obj->GV->STASH->NAME;
        my $sub = $obj->GV->NAME;
        my $key = _get_key($pkg);

        no strict 'refs';       ## no critic (ProhibitNoStrict)
        no warnings 'redefine'; ## no critic (ProhibitNoWarnings)

        next if exists &{ $caller . '::' . $sub };

        *{ $caller . '::' . $sub } = sub {
            my $hints = ( caller 0 )[10];

            return _fail( $pkg, $sub ) if $hints->{$key} =~ /(?:^$)|(?:!$sub\b)/; # no $module
                                                                                  # no $module '$sub'

            goto $ref if $hints->{$key} =~ /(?:^1\b)|(?:\b$sub\b)/;               # use $module
                                                                                  # use $module '$sub'
        };
    }
}

sub _fail {
    my ( $pkg, $sub ) = @_;

    if ( defined $modifier_for{$pkg} ) {
        if ( $modifier_for{$pkg} eq ':silent' ) {
            return;
        }

        if ( $modifier_for{$pkg} eq ':warn' ) {
            carp "$pkg\::$sub not allowed here";
            return;
        }
    }

    croak "$pkg\::$sub not allowed here";
}

sub _get_key {
    my ( $pkg ) = @_;

    return __PACKAGE__ . '/' . $pkg;
}

1;

__END__

=head1 NAME

Export::Lexical - Lexically scoped subroutine imports

=head1 SYNOPSIS

    package Foo;

    use Export::Lexical;

    sub foo :ExportLexical {
        # do something
    }

    sub bar :ExportLexical {
        # do something else
    }

    # In a nearby piece of code...

    use Foo;

    foo();    # calls foo()
    bar();    # calls bar()

    {
        no Foo 'bar';    # disables bar()

        foo();           # calls foo()
        bar();           # throws an exception
    }

=head1 DESCRIPTION

The Export::Lexical module provides a simple interface to the custom user
pragma interface in Perl 5.10. Simply by marking subroutines of a module with
the C<:ExportLexical> attribute, they will automatically be flagged for
lexically scoped import.

=head1 INTERFACE 

=head2 Import Modifiers

By default, subroutines not currently exported to the lexical scope will raise
exceptions when called. This behavior can be modified in two ways.

=over

=item C<< :silent >>

    use Export::Lexical ':silent';

Causes subroutines not imported into the current lexical scope to be no-ops.

=item C<< :warn >>

    use Export::Lexical ':warn';

Causes subroutines not imported into the current lexical scope to warn with
carp() instead of dying with croak().

=back

=head2 Subroutine Attributes

=over

=item C<< :ExportLexical >>

    package Foo;

    sub foo :ExportLexical {
        # do something
    }

This marks the foo() subroutine for lexically scoped import. When the Foo
module in this example is used, the foo() subroutine is available only in the
scope of the C<use> statement. The foo() subroutine can be made into a no-op
with the C<no> statement.

=back

=head1 DIAGNOSTICS

No diagnostics exist in this version of Export::Lexical.

=head1 CONFIGURATION AND ENVIRONMENT

Export::Lexical requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item *

Perl 5.10.0+

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Do not define C<import()> or C<unimport()> subroutines when using
Export::Lexical. These will redefine the subroutines created by the
Export::Lexical module, disabling the special properties of the attributes. In
practice, this probably isn't a big deal.

Please report any bugs or feature requests to
L<https://github.com/sirhc/perl-Export-Lexical/issues/>.

=head1 AUTHOR

L<Christopher D. Grau|mailto:cgrau@cpan.org>

This module is an expansion of an idea presented by Damian Conway.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015, Christopher D. Grau.

This is free software, licensed under the MIT (X11) License.

=head1 SEE ALSO

L<Exporter::Lexical> is another exporter module which provides for lexically
scoped imports.

L<Lexical::Import> lets you import functions and variables from another
package into the importing lexical namespace.

L<Exporter::LexicalVars> has a similar name, but it lets you export lexical (my)
variables from your module.

L<perlpragma>

=cut
