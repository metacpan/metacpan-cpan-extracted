package JSPL::Script;
use strict;
use warnings;

our @ISA = qw(JSPL::Boxed);

sub new {
    my $pkg = shift;
    jss_compile(@_);
}

sub exec {
    my($self, $gobj) = @_;
    
    jss_execute($self->__context, $gobj, $self->__content);
}

sub _prolog {
    my($self) = @_;
    my $pp = jss_prolog($self->__context, $self->__content);
    $$pp;
}

sub _main {
    my($self) = @_;
    my $pp = jss_main($self->__context,  $self->__content);
    $$pp;
}

sub _getatom {
    my($self, $index) = @_;
    jss_getatom($self->__context, $self->__content, $index);
}

sub _getobject {
    my($self, $index) = @_;
    jss_getobject($self->__context, $self->__content, $index);
}
    
$JSPL::ClassMap{Script} = __PACKAGE__;
JSPL::_boot_(__PACKAGE__);

1;
__END__

=head1 NAME

JSPL::Script - Encapsulates pre-compiled JavaScript code.

=head1 DESCRIPTION

If you have a big script that has to be executed over and over again
compilation time may be significant.  The method C<compile> in
C<JSPL::Context> provides a mean of returning a pre-compiled script which
is an instance of this class which can be executed without the need of
compilation.

=head1 PERL INTERFACE

=head2 INSTANCE METHODS

=over 4

=item exec

Executes the script and returns the result of the last statement.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item new ( $context, $gobj, $source, $name )

Creates a new script in context.

=item jss_compile ( PJS_Context *pcx, SV *gobj, SV *source, const char *name = "" )

Compiles a script and returns a C<JSPL::Script>

=item jss_execute ( PJS_Context *pcx, SV *gobj, JSObject *obj)

Executes the script wrapped in obj in the context pcx in the scope of gobj

=item jss_prolog ( JSPL::Context pcx, JSPL::RawObj, name,  sps)

Returns the prolog bytecode of the script wrapped in obj

=item jss_main ( JSPL::Context pcx,  JSPL::RawObj)

Returns the main bytecode of the script wrapped in obj

=item jss_getatom ( JSPL::Context pcx,  JSPL::RawOb obj, int index)

Returns the atom at index in script

=item jss_getobject ( JSPL::Context pcx,  JSPL::RawOb obj, int index)

Returns the object at index in script

=back

=end PRIVATE

=cut

