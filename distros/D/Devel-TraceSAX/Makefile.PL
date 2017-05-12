use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => "Devel::TraceSAX",
    VERSION_FROM  => "lib/Devel/TraceSAX.pm",
    PREREQ_PM     => {
        "Devel::TraceCalls" => 0.03,  ## need emit_trace_message()
        "XML::SAX::EventMethodMaker" => 0,  ## In XML::SAX::Machines
    },
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
