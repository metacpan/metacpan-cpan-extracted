package Export::Declare;
use strict;
use warnings;

use Carp qw/croak/;
use Importer;
use Export::Declare::Meta;

sub META() { 'Export::Declare::Meta' }

BEGIN { META->new(__PACKAGE__)->inject_vars }

our $VERSION = '0.002';

my %SIG_TO_TYPE = (
    '&' => 'CODE',
    '%' => 'HASH',
    '@' => 'ARRAY',
    '$' => 'SCALAR',
    '*' => 'GLOB',
);

exports(qw{
    export
    exports
    export_tag
    export_gen
    export_magic
    export_meta
});

export(import => sub { Importer->import_into(shift(@_), 0, @_) });

sub export_meta { META->new(scalar caller) }

sub import {
    my $class = shift;
    return unless @_;

    my $caller = caller;

    my (@subs, %params);
    while(my $arg = shift @_) {
        push @subs => $arg unless substr($arg, 0, 1) eq '-';
        $params{substr($arg, 1)} = 1;
    }

    my $meta = META->new($caller, %params);

    Importer->import_into($class, $caller, @subs) if @subs;
}

sub export {
    my ($sym, $ref) = @_;
    my ($name, $sig, $type) = _parse_sym($sym);

    my $from = caller;
    my $meta = META->new($from, default => 1);

    return push @{$meta->export_ok} => $sym unless $ref;

    croak "Symbol '$sym' is type '$type', but reference '$ref' is not"
        unless ref($ref) eq $type;

    $meta->export_anon->{$sym} = $ref;
    push @{$meta->export_ok} => $sym;
}

sub exports {
    my $from = caller;
    my $meta = META->new($from, default => 1);

    push @{$meta->export_ok} => grep _parse_sym($_), @_;
}

sub export_tag {
    my ($tag, @symbols) = @_;

    my $from = caller;
    my $meta = META->new($from, default => 1);

    my $ref = $meta->export_tags->{$tag} ||= [];
    push @$ref => grep _parse_sym($_), @symbols;
}

sub export_gen {
    my ($sym, $sub) = @_;
    my ($name, $sig, $type) = _parse_sym($sym);
    my $from = caller;

    croak "Second argument to export_gen() must be either a coderef or a valid method on package '$from'"
        unless ref($sub) eq 'CODE' || $from->can($sub);

    my $meta = META->new($from, default => 1);
    $meta->export_gen->{$sym} = $sub;
    push @{$meta->export_tags->{ALL}} => $sym;
}

sub export_magic {
    my ($sym, $sub) = @_;
    my ($name, $sig, $type) = _parse_sym($sym);
    my $from = caller;

    croak "Second argument to export_magic() must be either a coderef or a valid method on package '$from'"
        unless ref($sub) eq 'CODE' || $from->can($sub);

    my $meta = META->new($from, default => 1);
    $meta->export_magic->{$sym} = $sub;
}

sub _parse_sym {
    my ($sym) = @_;
    my ($sig, $name) = ($sym =~ m/^(\W?)(.+)$/);
    croak "'$sym' is not a valid symbol name" unless $name;
    $sig ||= '&';

    my $type = $SIG_TO_TYPE{$sig} or croak "'$sym' is not a supported symbol";

    return ($name, $sig, $type);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Export::Declare - Declarative Exporting, successor of Exporter-Declare.

=head1 DESCRIPTION

Declare exports instead of using package vars. Successor to
L<Exporter::Declare> which was over complicated. Fully compatible with
L<Importer> and L<Exporter>.

=head1 SYNOPSYS

=head2 DECLARING EXPORTS

    package My::Exporter;
    use Importer 'Export::Declare' => (qw/export exports export_tag export_meta/);

    # You should do one of these, if you do not then 'vars' will be selected
    # automatically.
    export_meta->inject_menu; # Define IMPORTER_MENU
    # and/or
    export_meta->inject_vars; # Define @EXPORT and friends

    # Export an anonymous sub
    export foo => sub { 'foo' };

    # Export package subs
    exports qw/bar baz/;

    # Default export
    export_tag DEFAULT => qw/bat/;

    # Define the subs you are exporting
    sub bar { 'bar' }
    sub baz { 'baz' }
    sub bat { 'bat' }

=head2 CONSUMING EXPORTS

    use Importer 'My::Exporter' => qw/foo bar baz bat/;

if the exporter imported C<import()> from Export::Declare then you can use it
directly, but this is discouraged.

    use My::Exporter qw/foo bar baz bat/;

=head2 USE + IMPORT

You can use Export::Declare directly to bring in the tools. You can specify
C<-menu> and/or C<-vars> to inject C<IMPORTER_MENU()> and/or C<@EXPORT> and
friends.

    use Export::Declare => qw/-vars -menu export exports/;

=head1 EXPORTS

All exports are optinal, none are exported by default.

=over 4

=item my $meta = export_meta()

Get the meta-object for the current package.

This is litterally:

    sub export_meta { Export::Declare::Meta->new(scalar caller) }

=item export $NAME

=item export $NAME => $REF

Export the specified symbol. if C<$REF> is specified then it will be used as
the export. If C<$REF> is not specified then the ref will be pulled from the
symbol table for the current package.

C<$NAME> can be a function name, or a symbol name such as C<'$FOO'>. C<$REF> if
provided must be the same type as the sigil in C<$NAME>. if C<$NAME> has no
sigil then C<&> is assumed.

=item exports @NAMES

C<@NAMES> is a list of symbol names. A symbol name can be a function name
without a sigil, or it can be any type of veriable with a sigil.

=item export_tag $TAG => @NAMES

C<$TAG> can be any valid tag name (same as any variable name, must start with a
word character, and contain only word characters and numbers.

C<@NAMES> is a list of symbol names. A symbol name can be a function name
without a sigil, or it can be any type of veriable with a sigil.

The C<:DEFAULT> tag is linked to C<@EXPORT> when the meta-data is linked with
package vars.

The C<:FAIL> tag is linked to C<@EXPORT_FAIL> when the meta-data is linked with
package vars.

The C<:ALL> tag is linked to C<@EXPORT_OK> when the meta-data is linked with
package vars. All exports are added to this tag automatically.

=item export_gen $NAME => \&GENERATOR

=item export_gen $NAME => $GENERATOR

Specify that C<$NAME> should be exported, and that the C<$REF> should be
generated dynamically using the specified sub. This sub will be used every time
something imports C<$NAME>.

C<$NAME> can be a function name, or a symbol name such as C<'$FOO'>. C<$REF> if
provided must be the same type as the sigil in C<$NAME>. if C<$NAME> has no
sigil then C<&> is assumed.

The second argument can be a reference to a subroutine, or it can be the name
of a sub to call on the current package.

The sub gets several arguments:

    export_gen foo => sub {
        my ($from_package, $into_package, $symbol_name) = @_;
        ...
        return $REF;
    };

    export_gen bar => '_gen_bar''
    sub _gen_bar {
        my ($from_package, $into_package, $symbol_name) = @_;
        ...
        return $REF;
    }

=item export_magic $NAME => sub { ... }

This allows you to define custom actions to run AFTER an export has been
injected into the consumers namespace. This is a good place to enable parser
hooks like with L<Devel::Declare>.

    export_magic foo => sub {
        my $from = shift;    # Should be the package doing the exporting
        my %args = @_;

        my $into      = $args{into};         # Package symbol was exported into
        my $orig_name = $args{orig_name};    # Original name of the export (in the exporter)
        my $new_name  = $args{new_name};     # Name the symbol was imported as
        my $ref       = $args{ref};          # The reference to the symbol

        ...;                                 # whatever you want, return is ignored.
    };

=item $CLASS->import(@NAMES)

This is an optinal C<import()> method you can pull into your exporter so that
people can consume your exports by directly using your module.

    package My::Exporter;

    use Importer 'Export::Declare' => qw/export import/;

    export foo => sub { 'foo' };

...

    package My::Consumer;

    use My::Exporter qw/foo/;

B<This is discouraged!> it is better if you omit C<import()> and have people do
this to get your exports:

    package My::Consumer;

    use Importer 'My::Exporter' => qw/foo/;

=back

=head1 DETAILS

This package tracks exports in a meta class. The meta-class is
L<Export::Declare::Meta>. All the exports act on the meta-object for the
package that calls them. Having this meta-data on its own does not actually
make your module an exporter, for that to happen you need to expose the
meta-data in a way that L<Exporter> or L<Importer> know how to find it.

    export_meta->inject_vars;
    export_meta->inject_menu;

C<inject_vars> will inject C<@EXPORT>, C<@EXPORT_OK> and other related vars.
These vars will be directly linked to the meta-object.

C<inject_menu> injects the C<IMPORTER_MENU()> function that exposes the
meta-data.

If you do not specify one, then C<vars> will be selected for you automatically
the first time you use an export function.

=head1 SOURCE

The source code repository for Export-Declare can be found at
F<http://github.com/exodist/Export-Declare/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
