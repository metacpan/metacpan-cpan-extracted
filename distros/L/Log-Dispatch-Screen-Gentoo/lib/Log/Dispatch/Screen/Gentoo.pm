package Log::Dispatch::Screen::Gentoo;
# ABSTRACT: Gentoo-colored screen logging output
$Log::Dispatch::Screen::Gentoo::VERSION = '0.002';
use strict;
use warnings;
use parent 'Log::Dispatch::Screen';
use Encode ();
use Module::Runtime qw< require_module >;
use Term::GentooFunctions ':all';

## no critic qw(Modules::RequireExplicitInclusion)
my $encode
    = eval { require Unicode::UTF8; 1; }
    ? sub { Unicode::UTF8::encode_utf8( $_[0] ) }
    : sub { Encode::encode_utf8( $_[0] ) };

# einfo
# ewarn
# eerror
# equiet
# ebegin
# eend

our %FUNCTION_MAP = (
    ''          => sub { einfo( $_[0] )  },
    'debug'     => sub { einfo( $_[0] )  },
    'info'      => sub { einfo( $_[0] )  },
    'notice'    => sub { einfo( $_[0] )  },
    'warning'   => sub { ewarn( $_[0] )  },
    'error'     => sub { eerror( $_[0] ) },
    'critical'  => sub { eerror( $_[0] ) },
    'alert'     => sub { eerror( $_[0] ) },
    'emergency' => sub { eerror( $_[0] ) },
);

sub log_message {
    my ( $self, %p ) = @_;

    my $level = $p{'level'};

    my $message
        = $self->{'utf8'}
        ? $encode->( $p{'message'} )
        : $encode->( $p{'message'} );

    my $print_func = $FUNCTION_MAP{$level} //= $FUNCTION_MAP{''};

    if ( $self->{'stderr'} ) {
        # Should be STDERR
        $print_func->($message);
    } else {
        # Should be STDOUT
        $print_func->($message);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Screen::Gentoo - Gentoo-colored screen logging output

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
        'outputs' => [
            [
                'Screen::Gentoo',
                'min_level' => 'debug',
                'stderr'    => 1,
                'newline'   => 1,
            ],
        ],
    );

    $log->info('Information');
    $log->warning('Uh oh!');
    $log->critical('No oh!');

=head1 DESCRIPTION

This implements a colorful output that uses L<Term::GentooFunctions> to
print out the output.

It also works with indentation when using C<eindent> and C<eoutdent> from
L<Term::GentooFunctions>.

If you have L<Unicode::UTF8> available, it will use that to support UTF-8
character encodings. (This is much faster than L<Encode>.)

One limitation this has is that there are only three colors, which means
that you cannot see a difference between levels C<debug>, C<notice>, and
C<info> which all have a green color, or between C<error>, C<critical>,
C<alert>, and C<emergency> which all have a red color.

At least for now.

=head1 SEE ALSO

=over 4

=item * L<Log::Dispatch::Screen::Color>

Colors entire lines, not just the beginning. Try it out.

=item * L<Unicode::UTF8>

=back

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
