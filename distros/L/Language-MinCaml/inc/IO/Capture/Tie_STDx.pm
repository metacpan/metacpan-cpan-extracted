#line 1
package IO::Capture::Tie_STDx;

sub TIEHANDLE {
    my $class = shift;
    bless [], $class;
}

sub PRINTF {
    my $self   = shift;
    my $format = shift;
    $self->PRINT( sprintf( $format, @_ ) );
}

sub PRINT {
     my $self = shift;
     push @$self, join '',@_;
}

sub READLINE {
    my $self = shift;
    return wantarray ? @$self : shift @$self;
}

sub CLOSE {
    my $self = shift;
    return close $self;
}

#line 47

1;
