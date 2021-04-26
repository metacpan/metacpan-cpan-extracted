package Fork::Utils;

use 5.012;
use warnings;
use base qw/ Exporter /;
use Config ();
use POSIX ();
use Carp qw/ croak /;

our $VERSION = '0.01';
our @EXPORT_OK = qw/ safe_exec /;

sub safe_exec  {

    my ( %options ) = @_;
    my ( $code, $args, $sigset, $replace_mask ) = @options{ qw/code args sigset replace_mask/ };

    croak( 'Argument $code must be a CODE reference.' ) if ( ref( $code ) ne 'CODE' );
    croak( 'Argument $args must be an ARRAY reference.' ) if ( $args && ref( $args ) ne 'ARRAY' );
    croak( 'Argument $sigset must be an ARRAY reference.' ) if ( $sigset && ref( $sigset ) ne 'ARRAY' );

    state $sig_nums  = [ split( /\s+/, $Config::Config{'sig_num'} ) ];
    state $sig_names = [ split( /\s+/, $Config::Config{'sig_name'} ) ];
    my %signame2signum = ();

    for my $i ( 0 .. $#{$sig_nums} ) {
        $signame2signum{ $sig_names->[ $i ] } = $sig_nums->[ $i ];
    }

    my $new_sig_set = new POSIX::SigSet ();
    my $old_sig_set = new POSIX::SigSet ();

    $new_sig_set->emptyset();
    $old_sig_set->emptyset();

    $sigset = [] if ( ! $sigset ); # let's use empty mask by default

    foreach my $sig_name ( grep { $_ } @{ $sigset } ) {
        $new_sig_set->addset( $signame2signum{ $sig_name } ) if ( $signame2signum{ $sig_name } );
    }

    if ( ! $replace_mask ) { # add signals into the current mask
        POSIX::sigprocmask( POSIX::SIG_BLOCK, $new_sig_set, $old_sig_set );
    } else { # replace the current signla mask
        POSIX::sigprocmask( POSIX::SIG_SETMASK, $new_sig_set, $old_sig_set );
    }

    my $result = eval{ $code->( @{ $args || [] } ); };
    my $error = $@;

    # we don't use POSIX::SIG_UNBLOCK because we can occasionally unblock some signals that were blocked previously
    POSIX::sigprocmask( POSIX::SIG_SETMASK, $old_sig_set );

    $@ = $error; # restore the error if it was replaced by POSIX::sigprocmask

    return( $result );
}

1;
__END__

=head1 NAME

Fork::Utils - set of usefull methods to work with processes and signals

=head1 SYNOPSIS

    use Fork::Utils qw/ safe_exec /;

    my $result = safe_exec(
      'code'   => sub { my_super_sub( @_ ); },
      'args'   => [ @params ],
      'sigset' => [ qw/ CHLD TERM INT QUIT ALRM / ]
    );

=head1 DESCRIPTION

This package provides some methods that can be helpfull while working with sub-processes and signals.

=head2 safe_exec

Gets a hash with arguments, one of them is code reference is required to be executed in safe context.
"Safe context" means context which can't be accidently interrupted by some signals.

This method receives list of signals required to be blocked while code execution.
Once code is executed the original signal mask will be restored.

Any signal (except KILL, STOP) can be blocked.

The signal names can be taken from C<$Config{'sig_names'}>.

Returns a result of mentioned code reference as "$code->( @$args )".
Be aware that in current implementation this methods can't return the list.
The return value looks like the one shown below:

    my $result = $code->( @$args );

In case of any error in the executed code reference tha standard C<$@> variable will be set.

=over

=item code

  it's a code reference to be executed in safe context

=item args

  it's an array reference of arguments required to be passed into C<code> (see above)

=item sigset

  it's an array reference of signal names to be blocked while executing the C<code> (see above)

=item replace_mask

  It's a flag, by default it's turned off.
  
  If it's off than passed signals will be added to the current signal mask,
  otherwise mask will be replaced with new one built with mentioned signals

=back

=head1 AUTHOR

Chernenko Dmitiry cdn@cpan.org

=cut
