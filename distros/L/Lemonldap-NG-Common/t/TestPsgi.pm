package t::TestPsgi;

use base Lemonldap::NG::Common::PSGI;

sub init {
    my ( $self, $args ) = @_;

    $args->{logLevel} = "error";
    my $super = $self->SUPER::init($args);

    no warnings 'redefine';
    eval
'sub Lemonldap::NG::Common::Logger::Std::error {return $_[0]->warn($_[1])}';

    # Return a boolean. If false, then error message has to be stored in
    if ( $args->{error} ) {
        $self->error( $args->{error} );
        return 0;
    }
    return $super;
}

sub handler {
    my ( $self, $req ) = @_;

    # Do something and return a PSGI response
    # NB: $req is a Lemonldap::NG::Common::PSGI::Request object

    return [ 200, [ 'Content-Type' => 'text/plain' ], ['Body lines'] ];
}

1;
