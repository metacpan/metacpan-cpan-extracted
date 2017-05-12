package Haineko::CLI::Help;
use parent 'Haineko::CLI';
use strict;
use warnings;

sub new {
    my $class = shift;
    my $argvs = { @_ };
    my $thing = __PACKAGE__->SUPER::new( %$argvs );

    $thing->{'params'} = {
        'option' => [],
        'example' => [],
        'subcommand' => [],
    };
    return $thing;
}

sub add {
    my $self = shift;
    my $argv = shift;
    my $type = shift;
    my $data = $self->{'params'};

    return $data unless defined $argv;
    return $data unless ref $argv;
    return $data unless ref $argv eq 'ARRAY';

    if( $type eq 'o' || $type eq 'option' ) {
        # Option
        $data = $self->{'params'}->{'option'};

    } elsif( $type eq 'e' || $type eq 'example' ) {
        # Example
        $data = $self->{'params'}->{'example'};

    } elsif( $type eq 's' || $type eq 'subcommand' ) {
        # Subcommand
        $data = $self->{'params'}->{'subcommand'};

    } else {
        return $data;
    }

    push @$data, @$argv;
    return $data;
}

sub mesg {
    my $self = shift;

    my $messageset = [];
    my $offsetsize = [];
    my $indentsize = 2;
    my $maxlength1 = 0;

    for my $e ( 'subcommand', 'option' ) {
        my @f = @{ $self->{'params'}->{ $e } };
        my $l = 0;

        while( my $r = shift @f ) {
            next unless scalar @f % 2;
            $l = length $r;
            $maxlength1 = $l > $maxlength1 ? $l : $maxlength1;
            push @$offsetsize, $l;
        }
    }

    printf( STDERR "%s SUBCOMMAND [OPTION]\n", $self->command );

    for my $e ( 'subcommand', 'option' ) {
        my @f = @{ $self->{'params'}->{ $e } };
        my $v = q();

        while( my $r = shift @f ) {

            if( scalar @f % 2 ) {
                $v = $r;
                next;
            }
            $v .= '%s : '.$r;
            push @$messageset, $v;
        }

        next unless scalar @$messageset;
        printf( STDERR "  %s:\n", uc $e ) if scalar @$messageset;
        while( my $r = shift @$messageset ) {
            my $o = shift @$offsetsize;
            printf( STDERR "  %s", ' ' x $indentsize );
            printf( STDERR $r, ' ' x ( $maxlength1 - $o + 2 ) );
            printf( STDERR "\n" );
        }
        printf( STDERR "\n" );
    }

    if( scalar @{ $self->{'params'}->{'example'} } ) {
        printf( STDERR "  FOR EXAMPLE:\n" );
        for my $e ( @{ $self->{'params'}->{'example'} } ) {
            printf( STDERR "    %s\n", $e );
        }
    }
}

1;
__END__
=encoding utf8

=head1 NAME

Haineko::CLI::Help - Class for displaying help message

=head1 DESCRIPTION

Haineko::CLI::Help provide methods for displaying help messages of each command
or each class.

=head1 SYNOPSIS

    use Haineko::CLI::Help;
    my $d = Haineko::CLI::Help->new();

    $d->add( Haineko::CLI::Daemon->help('o'), 'option' );
    $d->add( Haineko::CLI::Daemon->help('s'), 'subcommand' );
    $d->add( [ 'Command example' ], 'example' );
    $d->mesg();

=head1 CLASS METHODS

=head2 C<B<new()>>

C<new()> is a constructor of Haineko::CLI::Help.

    use Haineko::CLI::Help;
    my $d = Haineko::CLI::Help->new();

=head1 INSTANCE METHODS

=head2 C<B<mesg()>>

C<mesg()> print help messages to STDERR.

    $d->add( Haineko::CLI::Daemon->help('o'), 'option' );
    $d->add( Haineko::CLI::Daemon->help('s'), 'subcommand' );
    $d->add( [ 'Command example' ], 'example' );
    $d->mesg();

=head2 C<B<add( [I<Messages>], I<type> )>>

C<add()> method add help messages into the object. The first argument should be an
array reference, the second argument should be 'option' or C<subcommand> or 'example'.

=head2 C<B<parseoptions()>>

C<parseoptions()> method parse options given at command line and returns the
value of run-mode.

=head2 C<B<help()>>

C<help()> prints help message of Haineko::CLI::Help for command line.

=head1 SEE ALSO

=over 2

=item *
L<Haineko::CLI> - Base class of Haineko::CLI::Help

=item *
L<bin/haineoctl> - Script of Haineko::CLI::* implementation

=back

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
