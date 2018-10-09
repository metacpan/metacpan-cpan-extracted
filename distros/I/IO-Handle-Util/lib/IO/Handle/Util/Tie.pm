package IO::Handle::Util::Tie;

use strict;
use warnings;

our $VERSION = '0.02';

sub TIEHANDLE {
    my ( $class, $fh ) = @_;
    bless \$fh, $class;
}

sub WRITE {
    my $self = shift;
    $$self->write(@_);
}

sub PRINT {
    my $self = shift;
    $$self->print(@_);
}

sub PRINTF {
    my $self = shift;
    $$self->printf(@_);
}

sub READ {
    my $self = shift;
    $$self->read(@_);
}

sub READLINE {
    my $self = shift;

    if ( wantarray ) {
        $$self->getlines;
    } else {
        $$self->getline;
    }
}

sub GETC {
    my $self = shift;
    $$self->getc(@_);
}

sub CLOSE {
    my $self = shift;
    $$self->close(@_);
}

sub UNTIE { }

__PACKAGE__

__END__
