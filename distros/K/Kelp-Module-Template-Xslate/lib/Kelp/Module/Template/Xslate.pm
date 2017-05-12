package Kelp::Module::Template::Xslate;
use Kelp::Base 'Kelp::Module::Template';
use Text::Xslate;

our $VERSION = 0.01;

attr ext => 'tx';

sub build_engine {
    my ( $self, %args ) = @_;
    Text::Xslate->new(%args);
}

sub render {
    my ( $self, $template, $vars ) = @_;
    return
      ref($template) eq 'SCALAR'
      ? $self->engine->render_string( $$template, $vars )
      : $self->engine->render( $template, $vars );
}

1;

__END__

=pod

=head1 NAME

Kelp::Module::Template::Xslate - Template rendering via Text::Xslate for Kelp

=head1 SYNOPSIS

First ...

    # conf/config.pl
    {
        modules => ['Template::Xslate'],
        modules_init => {
            'Template::Xslate' => {
                ...
            }
        }
    }

Then ...

    # lib/MyApp.pm
    sub some_route {
        my $self = shift;
        return $self->template( \'Inline <: $name :>', { name => 'template' } );
    }

    sub another_route {
        my $self = shift;
        return $self->template( 'filename', { bar => 'foo' } );
    }

=head1 SEE ALSO

L<Kelp>, L<Text::Xslate>

=cut
