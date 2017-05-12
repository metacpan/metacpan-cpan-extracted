package Function::Composition;
use strict;
use warnings;
our $VERSION = '0.0.2';

use parent qw(Exporter);
our @EXPORT_OK = qw(compose);

sub compose {
    my @functions = reverse @_;
    return sub {
        my @res = @_;
        for my $f (@functions) {
            @res = $f->(@res);
        }
        @res;
    }
}

1;
__END__

=head1 NAME

Function::Composition - compose functions into one function

=head1 SYNOPSIS

  use Function::Composition 'compose';

  compose(\&function1, \&function2, \&function3 ...)->(@args);
  # the same result as function1(function2(function3(@args)));

=head1 DESCRIPTION

Simulate the concept of Function Composition in Haskell.

SYNOPSIS shows you the similiar work in Haskell

    ( function1 . function2 . function3 ) args

=head1 AUTHOR

shelling E<lt>navyblueshellingford@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

MIT (X11) License

=cut
