package Log::Dispatch::Base;

use strict;
use warnings;

use Carp ();
use Log::Dispatch::Vars
    qw( %CanonicalLevelNames %LevelNamesToNumbers @OrderedLevels );
use Scalar::Util qw( refaddr );

our $VERSION = '2.70';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _level_as_number {
    my $self  = shift;
    my $level = shift;

    my $level_name = $self->level_is_valid($level);
    return unless $level_name;

    return $LevelNamesToNumbers{$level_name};
}
## use critic

sub level_is_valid {
    shift;
    my $level = shift;

    if ( !defined $level ) {
        Carp::croak('Logging level was not provided');
    }

    if ( $level =~ /\A[0-9]+\z/ && $level <= $#OrderedLevels ) {
        return $OrderedLevels[$level];
    }

    return $CanonicalLevelNames{$level};
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _apply_callbacks {
    my $self = shift;
    my %p    = @_;

    my $msg = delete $p{message};
    for my $cb ( @{ $self->{callbacks} } ) {
        $msg = $cb->( message => $msg, %p );
    }

    return $msg;
}

sub add_callback {
    my $self  = shift;
    my $value = shift;

    Carp::carp("given value $value is not a valid callback")
        unless ref $value eq 'CODE';

    $self->{callbacks} ||= [];
    push @{ $self->{callbacks} }, $value;

    return;
}

sub remove_callback {
    my $self = shift;
    my $cb   = shift;

    Carp::carp("given value $cb is not a valid callback")
        unless ref $cb eq 'CODE';

    my $cb_id = refaddr $cb;
    $self->{callbacks}
        = [ grep { refaddr $_ ne $cb_id } @{ $self->{callbacks} } ];

    return;
}

1;

# ABSTRACT: Code shared by dispatch and output objects.

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Base - Code shared by dispatch and output objects.

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch::Base;

  ...

  @ISA = qw(Log::Dispatch::Base);

=head1 DESCRIPTION

Unless you are me, you probably don't need to know what this class
does.

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
