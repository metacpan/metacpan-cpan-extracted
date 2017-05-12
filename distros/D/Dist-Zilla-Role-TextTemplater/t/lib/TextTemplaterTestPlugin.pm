#   ------------------------------------------------------------------------------------------------
#
#   file: t/lib/TextTemplaterTestPlugin.pm
#
#   This file is part of perl-Dist-Zilla-Role-TextTemplater.
#
#   ------------------------------------------------------------------------------------------------

#   This is a trivial plugin which allows test to execute arbitrary code. Test should save
#   reference to code to be executed in $TextTemplaterTestPlugin::Hook variable.

package TextTemplaterTestPlugin;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::TextTemplater';

our $Hook;

has text => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    default     => sub { [] },
);

around mvp_multivalue_args => sub {
    my ( $orig, $self ) = @_;
    return ( $self->$orig(), 'text' );
};


sub BUILD {
    my ( $self ) = @_;
    my $string = join( "\n", @{ $self->text } );
    if ( $Hook ) {
        $string = $Hook->( $self, $string );
    } else {
        $string = $self->fill_in_string( $string );
    };
    $self->text( [ split( "\n", $string ) ] );
};

__PACKAGE__->meta->make_immutable;

1;

# end of file #
