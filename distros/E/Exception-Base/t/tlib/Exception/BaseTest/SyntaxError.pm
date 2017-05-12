package BadSuite::SyntaxError;

our $VERSION = 0.01;

our @INC = ('Exception::Base');

BEGIN {
    eval q{
        sub broken_method {
            my $self =
        };
    };
};

1;
