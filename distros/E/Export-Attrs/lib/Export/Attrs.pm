package Export::Attrs;

our $VERSION = 'v0.1.0';

use warnings;
use strict;
use Carp;
use Attribute::Handlers;
use PadWalker qw( var_name peek_my );

my %IMPORT_for;

sub import {
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::import'} = \&_generic_import;
    *{$caller.'::IMPORT'} = sub (&) { $IMPORT_for{$caller} = shift };
    for my $var_type (qw( SCALAR ARRAY HASH CODE )) {
        *{$caller.'::MODIFY_'.$var_type.'_ATTRIBUTES'} = \&_generic_handler;
    }
    return;
}

my %tagsets_for;
my %is_exported_from;
my %named_tagsets_for;
my %decl_loc_for;
my %name_of;

my $IDENT = '[^\W\d]\w*';

sub _generic_handler {
    my ($package, $referent, @attrs) = @_;

    ATTR:
    for my $attr (@attrs) {

        ($attr||=q{}) =~ s/\A Export (?: \( (.*) \) )? \z/$1||q{}/exms
            or next ATTR;

        my @tagsets = grep {length $_} split m/ \s+,?\s* | ,\s* /xms, $attr;

        my (undef, $file, $line) = caller(1);
        $file =~ s{.*/}{}xms;

        if (my @bad_tags = grep {!m/\A :$IDENT \z/xms} @tagsets) {
            die 'Bad tagset',
                (@bad_tags==1?' ':'s '),
                "in :Export attribute at '$file' line $line: [@bad_tags]\n";
        }

        my $tagsets = $tagsets_for{$package} ||= {};

        for my $tagset (@tagsets) {
            push @{ $tagsets->{$tagset} }, $referent;
        }
        push @{ $tagsets->{':ALL'} }, $referent;

        $is_exported_from{$package}{$referent} = 1;
        $decl_loc_for{$referent} = "$file line $line";
        $name_of{$referent} = _get_lexical_name($referent);

        undef $attr;

    }

    return grep {defined $_} @attrs;
}

my %desc_for = (
    SCALAR => 'lexical scalar variable',
    ARRAY  => 'lexical array variable',
    HASH   => 'lexical hash variable',
    CODE   => 'anonymous subroutine',
);

my %hint_for = (
    SCALAR => "(declare the variable with 'our' instead of 'my')",
    ARRAY  => "(declare the variable with 'our' instead of 'my')",
    HASH   => "(declare the variable with 'our' instead of 'my')",
    CODE   => "(specify a name after the 'sub' keyword)",
);

sub _get_lexical_name {
    my ($var_ref) = @_;
    return if ref $var_ref eq 'CODE';

    SEARCH:
    for my $up_level (1..(~0>>1)-1) {
        my $sym_tab_ref = eval { peek_my($up_level) }
            or last SEARCH;

        for my $var_name (keys %{$sym_tab_ref}) {
            return $var_name if $var_ref == $sym_tab_ref->{$var_name};
        }
    }
    return;
}

sub _invert_tagset {
    my ($package, $tagset) = @_;
    my %inverted_tagset;

    for my $tag (keys %{$tagset}) {
        for my $sub_ref (@{$tagset->{$tag}}) {
            my $type = ref $sub_ref;
            my $sym = Attribute::Handlers::findsym($package, $sub_ref, $type)
                   || $name_of{$sub_ref}
                or die "Can't export $desc_for{$type} ",
                       "at $decl_loc_for{$sub_ref}\n$hint_for{$type}\n";
            if (ref $sym) {
                $sym = *{$sym}{NAME};
            }
            $inverted_tagset{$tag}{$sym} = $sub_ref;
        }
    }

    return \%inverted_tagset;
}

my %type_for = qw( $ SCALAR   @ ARRAY   % HASH );

# Reusable import() subroutine for all packages...
sub _generic_import {
    my $package = shift;

    my $tagset
        = $named_tagsets_for{$package}
        ||= _invert_tagset($package, $tagsets_for{$package});

    my $is_exported = $is_exported_from{$package};

    my $errors;

    my %request;
    my $subs_ref;

    my $args_supplied = @_;

    my $argno = 0;
    REQUEST:
    while ($argno < @_) {
        my $request = $_[$argno];
        if (my ($sub_name) = $request =~ m/\A &? ($IDENT) (?:\(\))? \z/xms) {
            if (exists $request{$sub_name}) {
                splice @_, $argno, 1;
                next REQUEST;
            }
            no strict 'refs';
            no warnings 'once';
            if (my $sub_ref = *{$package.'::'.$sub_name}{CODE}) {
                if ($is_exported->{$sub_ref}) {
                    $request{$sub_name} = $sub_ref;
                    splice @_, $argno, 1;
                    next REQUEST;
                }
            }
        }
        elsif (my ($sigil, $name) = $request =~ m/\A ([\$\@%])($IDENT) \z/xms) {
            next REQUEST if exists $request{$sigil.$name};
            no strict 'refs';
            no warnings 'once';
            if (my $var_ref = *{$package.'::'.$name}{$type_for{$sigil}}) {
                if ($is_exported->{$var_ref}) {
                    $request{$sigil.$name} = $var_ref;
                    splice @_, $argno, 1;
                    next REQUEST;
                }
            }
        }
        elsif ($request =~ m/\A :$IDENT \z/xms
               and $subs_ref = $tagset->{$request}) {
            @request{keys %{$subs_ref}} = values %{$subs_ref};
            splice @_, $argno, 1;
            next REQUEST;
        }
        $errors .= " $request";
        $argno++;
    }

    # Report unexportable requests...
    my $real_import = $IMPORT_for{$package};

    croak "$package does not export:$errors\nuse $package failed"
        if $errors && !$real_import;

    if (!$args_supplied) {
        %request = %{$tagset->{':DEFAULT'}||={}}
    }

    my $mandatory = $tagset->{':MANDATORY'} ||= {};
    @request{ keys %{$mandatory} } = values %{$mandatory};

    my $caller = caller;

    for my $sub_name (keys %request) {
        no strict 'refs';
        my ($sym_name) = $sub_name =~ m{\A [\$\@&%]? (.*)}xms;
        *{$caller.'::'.$sym_name} = $request{$sub_name};
    }

    if ($real_import) {
        my $idx=0;
        while ($idx < @_) {
            if (defined $_[$idx]) { $idx++             }
            else                  { splice @_, $idx, 1 }
        }
        goto &{$real_import};
    }
    return;
}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Export::Attrs - The Perl 6 'is export(...)' trait as a Perl 5 attribute


=head1 VERSION

This document describes Export::Attrs version v0.1.0

=head1 SYNOPSIS

    package Some::Module;
    use Export::Attrs;

    # Export &foo by default, when explicitly requested,
    # or when the ':ALL' export set is requested...

    sub foo :Export(:DEFAULT) {
        print "phooo!";
    }


    # Export &var by default, when explicitly requested,
    # or when the ':bees', ':pubs', or ':ALL' export set is requested...
    # the parens after 'is export' are like the parens of a qw(...)

    sub bar :Export(:DEFAULT :bees :pubs) {
        print "baaa!";
    }


    # Export &baz when explicitly requested
    # or when the ':bees' or ':ALL' export set is requested...

    sub baz :Export(:bees) {
        print "baassss!";
    }


    # Always export &qux
    # (no matter what else is explicitly or implicitly requested)

    sub qux :Export(:MANDATORY) {
        print "quuuuuuuuux!";
    }


    # Allow the constant $PI to be exported when requested...

    use Readonly;
    Readonly our $PI :Export => 355/113;


    # Allow the variable $EPSILON to be always exported...

    our $EPSILON :Export( :MANDATORY ) = 0.00001;


    sub IMPORT {
        # This subroutine is called when the module is used (as usual),
        # but it is called after any export requests have been handled.
    };


=head1 DESCRIPTION

B<NOTE:> This module is a fork of L<Perl6::Export::Attrs> created to
restore compatibility with Perl6::Export::Attrs version 0.0.3.

Implements a Perl 5 native version of what the Perl 6 symbol export mechanism
will look like (with some unavoidable restrictions).

It's very straightforward:

=over

=item *

If you want a subroutine or package variable to be capable of being exported
(when explicitly requested in the C<use> arguments), you mark it with
the C<:Export> attribute.

=item *

If you want a subroutine or package variable to be automatically exported when
the module is used (without specific overriding arguments), you mark it
with the C<:Export(:DEFAULT)> attribute.

=item *

If you want a subroutine or package variable to be automatically exported when
the module is used (even if the user specifies overriding arguments),
you mark it with the C<:Export(:MANDATORY)> attribute.

=item *

If the subroutine or package variable should also be exported when particular
export groups are requested, you add the names of those export groups to
the attribute's argument list.

=back

That's it.

=head2 C<IMPORT> blocks

Perl 6 replaces the C<import> subroutine with an C<IMPORT> block. It's
analogous to a C<BEGIN> or C<END> block, except that it's executed every
time the corresponding module is C<use>'d.

The C<IMPORT> block is passed the argument list that was specified on
the C<use> line that loaded the corresponding module, minus the
arguments that were used to specify exports.

Note that, due to limitations in Perl 5, the C<IMPORT> block provided by this
module must be terminated by a semi-colon, unless it is the last statement in
the file.

=head1 DIAGNOSTICS

=over

=item %s does not export: %s\nuse %s failed

You tried to import the specified subroutine or package variable, but
the module didn't export it. Often caused by a misspelling, or
forgetting to add an C<:Export> attribute to the definition of the
subroutine or variable in question.

=item Bad tagset in :Export attribute at %s line %s: [%s]

You tried to import a collection of items via a tagset, but the module
didn't export any subroutines under that tagset. Is the tagset name
misspelled (maybe you forgot the colon?).

=item Can't export lexical %s variable at %s

The module can only export package variables. You applied the C<:Export>
marker to a non-package variable (almost certainly to a lexical). Change
the variable's C<my> declarator to an C<our>.

=item Can't export anonymous subroutine at %s

Although you I<can> apply the C<:Export> marker to an anonymous subroutine,
it rarely makes any sense to do so, since that subroutine can't be
exported without a name to export it as. Either give the subroutine a
name, or make sure it's aliased to a named typeglob at compile-time (or,
at least, before it's exported).

=back


=head1 CONFIGURATION AND ENVIRONMENT

Export::Attrs requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires the Attribute::Handlers module to handle the attributes.


=head1 INCOMPATIBILITIES

This module cannot be used with the Memoize CPAN module,
because memoization replaces the original subroutine
with a wrapper. Because the C<:Export> attribute is
applied to the original (not the wrapper), the memoized
wrapper is not found by the exporter mechanism.


=head1 LIMITATIONS

Note that the module does not support exporting lexical variables,
since there is no way for the exporter mechanism to determine the name
of a lexical and hence to export it.

Nor does this module support the numerous addition export modes that
Perl 6 offers, such as export-as-lexical or export-as-state.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Export-Attrs/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Export-Attrs>

    git clone https://github.com/powerman/perl-Export-Attrs.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Export-Attrs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Export-Attrs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Export-Attrs>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Export-Attrs>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Export-Attrs>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>

Damian Conway E<lt>DCONWAY@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

Copyright (c) 2005,2015 Damian Conway E<lt>DCONWAY@cpan.orgE<gt>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut
