package Devel::Spy::TieArray;
use strict;
use warnings;
use constant SELF  => 0;
use constant IX    => 1;
use constant COUNT => 1;
use constant VALUE => 2;

use constant PAYLOAD => 0;
use constant CODE    => 1;

sub TIEARRAY {
    my ( undef, @array ) = @_;
    return bless \ @array, $_[SELF];
}

sub FETCH {
    my $followup = $_[SELF][CODE]->(' ->['.(defined $_[IX] ? $_[IX] : 'undef').']');
    my $ix = defined $_[IX] ? $_[IX] : 0;
    my $value    = $_[SELF][PAYLOAD][$ix];
    $followup = $followup->(' ->'.(defined $value ? $value : 'undef'));
    return Devel::Spy->new( $value, $followup );
}

sub STORE {
    my $followup = $_[SELF][CODE]->(' ->['.(defined $_[IX] ? $_[IX] : 'undef').'] = '.(defined $_[VALUE] ? $_[VALUE] : 'undef'));
    my $ix = defined $_[IX] ? $_[IX] : 0;
    $_[SELF][PAYLOAD]->[$ix] = $_[VALUE];
    return Devel::Spy->new( $_[VALUE], $followup );
}

sub FETCHSIZE {
    my $followup = $_[SELF][CODE]->(' scalar(@...)');
    my $value    = @{ $_[SELF][PAYLOAD] };
    $followup = $_[SELF][CODE]->(' ->'.(defined $value ? $value : 'undef'));
    return Devel::Spy->new( $value, $followup );
}

sub STORESIZE {
    $_[SELF][CODE]->(' $#... = ' . (defined $_[COUNT] ? $_[COUNT] : 'undef' ));
    $#{ $_[SELF][PAYLOAD] } = defined $_[COUNT] ? 1 + $_[COUNT] : 0;
    return;
}

# sub EXTEND {
#     my ( $self, $count ) = @_;
#
# }
#
# sub EXISTS {
#
# }
#
# sub DELETE { }
#
# sub CLEAR { }
#
# sub PUSH { }
#
# sub POP { }
#
# sub SHIFT   { }
# sub UNSHIFT { }
# sub SPLICE  { }

sub UNTIE {}
sub DESTROY {}

1;

__END__

=head1 NAME

Devel::Spy::TieArray - Tied logging wrapper for arrays

=head1 SYNOPSIS

  tie my @pretend_guts, 'Devel::Spy::TieArray', \ @real_guts, $logging_function
    or croak;

  # Passed operation through to @real_guts and tattled about the
  # operation to $logging_function.
  $pretend_guts[0] = 42;

=head1 CAVEATS

This has not been implemented. Feel free to add more and send me
patches. I'll also grant you permission to upload into the Devel::Spy
namespace if you're a clueful developer.

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::Util>,
L<Devel::Spy::TieHash>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>.
