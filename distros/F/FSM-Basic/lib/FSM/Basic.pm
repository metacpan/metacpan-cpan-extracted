package FSM::Basic;

use 5.006;
use strict;
use warnings;

=head1 NAME

FSM::Basic -  Finite state machine using HASH as state definitions

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

A small finite state machine using a HASH data as description of the states
Mainly used to create fake bash or fake telnet server in the purpose to mimic some CLI device interface (like SWITCH or ROUTER interface)
Perhaps a little code snippet.
The HASH is easily using a JSON file

    use FSM::Basic;

    my $fsm = FSM::Basic->new( \%states, 'accept' );
    my $final = 0;
    my $out;
    foreach my $in ( @ins )
    {
        ( $final, $out ) = $fsm->run( $in );
        say $out;
        last if $final;
   }


=head1 SUBROUTINES/METHODS

=head2 new

my $fsm = FSM::Basic->new( \%states, 'accept' );

Create the FSM with the HASH ref as first paramter 
and the initial state as second parameter

The HASH is like this:

 my %states = (
    'accept' => {
        'expect' => {
            'default' => {
                'final'    => 0,
                'matching' => 'prompt'
            }
        },
        'not_matching'           => 'accept',
        'not_matching0'          => 'close',
        'not_matching_info_last' => '% Bad passwords
',
        'output' => 'Password: ',
        'repeat' => 2
    },

    'close'  => {'final' => 1},
    'prompt' => {
        'expect' => {
            'not_matching' => 'prompt',
            'exit'         => {
                'matching'    => 'close',
                'final' => 0
            },
            'meminfo'     => {'do' => 'do { local( @ARGV, $/ ) = "/proc/meminfo" ; <> }'},
            'h(elp)?|\\?' => {
                'output' => 'exit
meminfo
mem_usage
User> '
            },
            'mem_usage' => {'do' => 'my ( $tot,$avail) = (split /\\n/ ,do { local( @ARGV, $/ ) = "/proc/meminfo" ; <> })[0,2];$tot =~ s/\\D*//g; $avail =~ s/\\D*//g; sprintf "%0.2f%%\\n",(100*($tot-$avail)/$tot); '},
        },
        'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
        'output'            => 'User> '
    }
);



The keys are the states name.
"expect" contain a sub HASH where the keys are word or REGEX expected as input

=over 1

=item In this hash, you have :

=over 2

=item executable code ( "do" for perl code, "exec" for system code).

=item "matching" to define the state when the input match the "expect" value

=item "final" to return a flag 

=item "not_matching" the state if the input is not matching the "expect" value (if missing stay in the same state)

=item "repeat" a number of trial before the state goes to "not_matching0"

=item "not_matching0" the state when the number of failled matching number is reached

=item "not_matching_info_last" info returned as second value when the  failled matching number is reached

=item "output" the info  returned as second value

=back

It is perfectly possible to add extra tag not used by FSM::Basic for generic purpose.
Check examples/fake_bash_ssh1.*
Take a look at timout and timer usage
In this example if destination IP from the SSH connection is available, the file IP.json is used as definition 
(with fallback to fake_bash1.pl)

=cut

sub new
{
    my ( $class, $l, $s ) = @_;
    my $self;
    $self->{ states_list } = $l;
    $self->{ state }       = $s;
    bless( $self, $class );
    return $self;
}

=back
=head2 run

my ( $final, $out ) = $fsm->run( $in );

Run the FSM with the input and return the expected output and an extra flag


=cut

sub run
{
    my ( $self, $in ) = @_;

    my $output = '';
    if ( exists $self->{ states_list } )
    {
        if (   exists $self->{ states_list }{ $self->{ state } }
            && exists $self->{ states_list }{ $self->{ state } }{ repeat }
            && $self->{ states_list }{ $self->{ state } }{ repeat } <= 0 )
        {
            $self->{ previous_state } = $self->{ state };
            $self->{ state } = $self->{ states_list }{ $self->{ state } }{ expect }{ not_matching0 } // $self->{ states_list }{ $self->{ state } }{ not_matching0 };
            if ( exists $self->{ states_list }{ $self->{ previous_state } }{ not_matching_info_last } )
            {
                $output = $self->{ states_list }{ $self->{ previous_state } }{ not_matching_info_last };
            }
            $output .= $self->{ states_list }{ $self->{ state } }{ output } // '';
            return ( $self->{ states_list }{ $self->{ state } }{ final } // 0, $output );
        }
        if ( exists $self->{ states_list }{ $self->{ state } }{ expect } )
        {
            if ( exists $self->{ states_list }{ $self->{ state } }{ info } )
            {
                $output = $self->{ states_list }{ $self->{ state } }{ info } . $output;
            }
            if ( exists $self->{ states_list }{ $self->{ state } }{ info_once } )
            {
                $output = delete( $self->{ states_list }{ $self->{ state } }{ info_once } ) . $output;
            }
            my $state;
            if (   exists $self->{ previous_output }
                && $in eq ''
                && $self->{ previous_output } =~ /\[(.+)\]/ )
            {
                $in = $1;
            }
            if ( exists $self->{ states_list }{ $self->{ state } }{ expect }{ $in } )
            {
                $state = $self->{ states_list }{ $self->{ state } }{ expect }{ $in };
            }
            else
            {
                foreach my $key ( keys %{ $self->{ states_list }{ $self->{ state } }{ expect } } )
                {
                    if ( $in =~ /$key/ )
                    {
                        $state = $self->{ states_list }{ $self->{ state } }{ expect }{ $key };
                    }
                }
            }
            if ( ref $state eq 'HASH' )
            {
                $self->{ previous_state }  = $self->{ state };
                $self->{ previous_output } = $state->{ output } // $self->{ states_list }{ $self->{ state } }{ output } // '';
                $self->{ state }           = $state->{ matching } // $self->{ state };
                $output .= $state->{ output } // $self->{ states_list }{ $self->{ state } }{ output } // '';
                if ( exists $state->{ cmd } )
                {
                    my $cmd_state = delete $state->{ cmd };
                    $cmd_state =~ s/\$in/$in/g;
                    push( @{ $self->{ cmd_stack } }, $cmd_state );
                }
                if ( exists $state->{ cmd_exec } )
                {
                    my $cmd_exec = join ' ', @{ $self->{ cmd_stack } };
                    $output = `$cmd_exec` . $output;
                    $self->{ cmd_exec } = [];
                }
                if ( exists $state->{ exec } )
                {
                    my $old_exec = $state->{ exec };
                    $state->{ exec } =~ s/__IN__/$in/g;
                    $output = `$state->{exec}` . $output;
                    $state->{ exec } = $old_exec;
                }
                if ( exists $state->{ do } )
                {
                    my $old_do = $state->{ do };
                    $state->{ do } =~ s/__IN__/$in/g;
                    $output = ( eval $state->{ do } ) . $output;
                    $state->{ do } = $old_do;
                }
            }
            else
            {
                $self->{ previous_state } = $self->{ state };
                $self->{ state } = $self->{ states_list }{ $self->{ state } }{ not_matching } // $self->{ state };
                $self->{ states_list }{ $self->{ state } }{ repeat }--
                  if exists $self->{ states_list }{ $self->{ state } }{ repeat };
                $output .= $self->{ states_list }{ $self->{ state } }{ output } // '';
                if ( exists $self->{ states_list }{ $self->{ state } }{ not_matching_info } )
                {
                    $output = $self->{ states_list }{ $self->{ state } }{ not_matching_info } . "\n" . $output;
                }
                return ( $self->{ states_list }{ $self->{ state } }{ $in }{ final } // $self->{ states_list }{ $self->{ state } }{ final } // 0, $output );
            }
            return ( $self->{ states_list }{ $self->{ state } }{ $in }{ final } // $self->{ states_list }{ $self->{ state } }{ final } // 0, $output );
        }
    }
}

sub set
{
    my ( $self, $in ) = @_;
    $self->{ previous_state }  = $self->{ state };
    $self->{ previous_output } = $self->{ states_list }{ $self->{ state } }{ output } // '';
    $self->{ state }           = $in
      if exists $self->{ states_list }{ $in };
}

#sub edit
#{
#    my ( $self, $in ) = @_;
#
#    return $self;
#}
#
#sub crawl_states
#{
#    my ( $self, $in ) = @_;
#}

=head1 EXAMPLE


    use strict;
    use feature qw( say );
    use FSM::Basic;
    use JSON;
    use Term::ReadLine;
    
        my %states = (
        'accept' => {
            'expect' => {
                'default' => {
                    'final'    => 0,
                    'matching' => 'prompt'
                }
            },
            'not_matching'           => 'accept',
            'not_matching0'          => 'close',
            'not_matching_info_last' => '% Bad passwords
    ',
            'output' => 'Password: ',
            'repeat' => 2
        },
    
        'close'  => {'final' => 1},
        'prompt' => {
            'expect' => {
                'not_matching' => 'prompt',
                'exit'         => {
                    'matching' => 'close',
                    'final'    => 0
                },
                'meminfo'     => {'do' => 'do { local( @ARGV, $/ ) = "/proc/meminfo" ; <> }'},
                'h(elp)?|\\?' => {
                    'output' => 'exit
    meminfo
    mem_usage
    User> '
                },
                'mem_usage' => {'do' => 'my ( $tot,$avail) = (split /\\n/ ,do { local( @ARGV, $/ ) = "/proc/meminfo" ; <> })[0,2];$tot =~ s/\\D*//g; $avail =~ s/\\D*//g; sprintf "%0.2f%%\\n",(100*($tot-$avail)/$tot); '},
            },
            'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
            'output'            => 'User> '
        }
    );
    my $history_file = glob( '/tmp/fsm.history' );
    my $prompt       = '> ';
    my $line;
    my $final   = 0;
    my $term    = new Term::ReadLine 'bash';
    my $attribs = $term->Attribs->ornaments( 0 );
    $term->using_history();
    $term->read_history( $history_file );
    $term->clear_signals();
    
    my $fsm = FSM::Basic->new( \%states, 'accept' );
    my $out = "Password> ";
    while ( defined( $line = $term->readline( $out ) ) )
    {
        ( $final, $out ) = $fsm->run( $line );
        $term->write_history( $history_file );
        last if $final;
    }
    
    print $out if $final;


More sample code in the examples folder.


=head1 TODO

add "edit" to allow on the fly modification of the states definition

add "verify_states" to check all states are reachable from a original state



=head1 AUTHOR

DULAUNOY Fabrice, C<< <fabrice at dulaunoy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-FSM-basic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FSM-Basic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FSM::Basic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FSM-Basic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FSM-Basic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FSM-Basic>

=item * Search CPAN

L<http://search.cpan.org/dist/FSM-Basic/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 DULAUNOY Fabrice.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of FSM::Basic
