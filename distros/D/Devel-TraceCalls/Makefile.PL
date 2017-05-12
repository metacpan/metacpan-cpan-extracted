use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => "Devel::TraceCalls",
    VERSION_FROM  => "lib/Devel/TraceCalls.pm",
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
