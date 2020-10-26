package FSM::Basic;

use 5.010;
use strict;
use warnings;

=head1 NAME

FSM::Basic - Finite state machine using HASH as state definitions

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

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

=back 

=over 2

=item executable code:

"do" for perl code


"exec" for system code,


and 4 dedicated commands:

"cat" just reading the file content provided in parameter).

"catRAND" chose randomly one of the files provided in parameter space separated

"catWRAND" chose randomly (weighted) one of the files provided in parameter space separatedwith a : to separate the weight

e.g. 'catWRAND' => './t/test_cat.txt:1 ./t/test_cat1.txt:50',   in this case the file ./t/test_cat1.txt get 50 more chance to be selected than file ./t/test_cat.txt

"catSEQ" read sequentialy the next files provided in parameter space separated
        if "catSEQ_idx" is defined, that file is used to keep the state. Otherwise , the state file is named used
        all the files name from "catSEQ" concatenated with a final '.tate'. All spaces are replaced by an underscore

=back

=over 3

=item * It is possible to use a regex to allow optional commands


e.g.
"h(elp)?|\\?": {
        "output": "default\nexit\ntimeoutA\n__PROMPT__"
      }

This json section match for 'h' 'help' or '?'



In the regex, the group capture could be used in the command parameter as a substitution

1st group is substituted by __1__

2nd group is substituted by __2__

...

e.g. for a ping

"ping (.*)"      => {"exec" => "ping -c 3 __1__"},

The __1__ is substitued by the first parameter in the expected command

If you run the command "ping 127.0.0.1" the exec run the command "ping -c 3 127.0.0.1" 

Other example:


      "cat /tmp/test/((\\w)(\\d))": {
        "cat": "/tmp/test/__3__"
      }
      
If you call with "cat /tmp/test/a1 the cat read the file /tmp/test/1" (without the 'a' because the group 3 is matching a single digit after a single character    



=item * If you need to match all possible partial match for a word ( like "h, "he", "hel", "help" to match the "help" state)
Use the extra tag "swapregex": "1"

In case of "swapregex": "1" we use this

  $key =~ /^$in/  
  
e.g.
        
        'expect' => {
            'not_matching' => 'prompt',
            'help'       => {
                'swapregex' => 1,
                'output'  => 'in enable',
                'final'     => 0
            }
        }

    In this example me match "h, "he", "hel", "help"


This reverse the REGEX test
In normal case (no "swapregex" )
The state is check with 

  $in =~ /^$key$/

Where $in is the input from the run() function
and $key is the state defined in the HASH  



=item * If you need to match all possible abbreviation starting from a fixed header you use the tag 'alternation'=>1 and the variable part between sqare bracket.


e.g.

            'ot[her]'       => {
                'alternation'     => 1,
                'output'          => 'in enable',
                'final'           => 0
            }

This match 'oth', 'othe' and 'other'

In fact the system create the REGEX /^o(t|th|the|ther)$/

For a more complex example: 

'c[onfiguration] t[erminal]' 

create the REGEX  

/^c(o|on|onf|onfi|onfig|onfigu|onfigur|onfigura|onfigurat|onfigurati|onfiguratio|onfiguration) t(e|er|erm|ermi|ermin|ermina|erminal)$/


It is possible to add the tag 'caseinsensitive' => 1, to allow also the case insentitive matching


=over 4

=item * It is possible to do a case insensitive matching with the special tag  "caseinsensitive": "1"

=over 4

e.g.

            'other' => {
                'output'          => 'in other',
                'caseinsensitive' => 1,
                'final'           => 0
            }
            
in this example "other", "OTHER", "Other", "otheR" (and all other case alternate set) match the state "other"

=back

=over 4

"matching"
to define the state when the input match the "expect" value

=back

=over 4

=item "final"
to return a flag

=back

=over 4 

=item "not_matching"
the state if the input is not matching the "expect" value (if missing stay in the same state)
 
=back

=over 4

=item "repeat"
a number of trial before the state goes to "not_matching0"

=back

=over 4

=item "not_matching0"
the state when the number of failled matching number is reached


=back

=over 4

=item "not_matching_info_last"
info returned as second value when the  failled matching number is reached

=back

=over 4

=item "output"
the info  returned as second value


=back

It is perfectly possible to add extra tag not used by FSM::Basic for generic purpose.
Check examples/fake_bash_ssh1.*
Take a look at timout and timer usage
In this example if destination IP from the SSH connection is available, the file IP.json is used as definition
(with fallback to fake_bash1.pl)

=cut

sub new {
    my ($class, $l, $s) = @_;
    my $self;
    $self->{states_list} = $l;
    $self->{state}       = $s;
    foreach my $k1 ( keys %{ $self->{states_list} }) {
        if (  exists  $self->{states_list}{ $k1 }{expect} ) {
            foreach my $k2 ( keys %{ $self->{states_list}{ $k1 }{expect} }) {
                if (ref $self->{states_list}{ $k1 }{expect}{$k2} eq 'HASH' && exists  $self->{states_list}{ $k1 }{expect}{$k2}{alternation}) {
                    if (defined $self->{states_list}{ $k1 }{expect}{$k2}{caseinsensitive} ) {
                        $self->{states_list}{ $k1 }{expect}{alter($k2,1)} = delete $self->{states_list}{ $k1 }{expect}{$k2};
                    }else{
                        $self->{states_list}{ $k1 }{expect}{alter($k2)} = delete $self->{states_list}{ $k1 }{expect}{$k2};
                    }
                }
            }
        }
    }
    bless($self, $class);
    return $self;
}

=back

B<run>

my ( $final, $out ) = $fsm->run( $in );

Run the FSM with the input and return the expected output and an extra flag


=cut

sub run {
    my ($self, $in) = @_;
    my $in_lc = lc($in);
    my $rev;
    my $alternation;
    foreach my $IN (grep { /$in/i } keys %{ $self->{states_list}{ $self->{state} }{expect} }) {
        if (ref $self->{states_list}{ $self->{state} }{expect}{$IN} eq 'HASH' && defined $self->{states_list}{ $self->{state} }{expect}{$IN}{swapregex}) {
            $rev //= $IN;
        }
    }
    my $output = '';
    if (exists $self->{states_list}) {
        if (   exists $self->{states_list}{ $self->{state} }
            && exists $self->{states_list}{ $self->{state} }{repeat}
            && $self->{states_list}{ $self->{state} }{repeat} <= 0)
        {
            $self->{previous_state} = $self->{state};
            $self->{state}          = $self->{states_list}{ $self->{state} }{expect}{not_matching0} // $self->{states_list}{ $self->{state} }{not_matching0};
            if (exists $self->{states_list}{ $self->{previous_state} }{not_matching_info_last}) {
                $output = $self->{states_list}{ $self->{previous_state} }{not_matching_info_last};
            }
            $output .= $self->{states_list}{ $self->{state} }{output} // '';
            return ($self->{states_list}{ $self->{state} }{final} // 0, $output);
        }
        if (exists $self->{states_list}{ $self->{state} }{expect}) {
            if (exists $self->{states_list}{ $self->{state} }{info}) {
                $output = $self->{states_list}{ $self->{state} }{info} . $output;
            }
            if (exists $self->{states_list}{ $self->{state} }{info_once}) {
                $output = delete($self->{states_list}{ $self->{state} }{info_once}) . $output;
            }
            my $state;
            if (   exists $self->{previous_output}
                && $in eq ''
                && $self->{previous_output} =~ /\[(.+)\]/)
            {
                $in = $1;
            }
            if (defined $rev) {
                my $key = $rev;
                my $r   = $in;
                $r = '(?i:' . $r . ')' if defined $self->{states_list}{ $self->{state} }{expect}{$rev}{caseinsensitive};
                if ($key =~ /^$r/) {
                    if (@+) {
                        for my $nbr (1 .. (scalar(@+) - 1)) {
                            if (defined $-[$nbr]) {
                                my $match = substr($key, $-[$nbr], $+[$nbr] - $-[$nbr]);
                                if (defined($+[$nbr])) {
                                    $self->{cmd_regex}{$nbr} = substr($key, $-[$nbr], $+[$nbr] - $-[$nbr]);
                                }
                            }
                        }
                    }
                    $state = $self->{states_list}{ $self->{state} }{expect}{$key};
                }
            } elsif (exists $self->{states_list}{ $self->{state} }{expect}{$in_lc} && defined $self->{states_list}{ $self->{state} }{expect}{$in_lc}{caseinsensitive}) {
                $state = $self->{states_list}{ $self->{state} }{expect}{$in_lc};
            } elsif (exists $self->{states_list}{ $self->{state} }{expect}{$in}) {
                $state = $self->{states_list}{ $self->{state} }{expect}{$in};
            } else {
                foreach my $key (keys %{ $self->{states_list}{ $self->{state} }{expect} }) {
                    if ($in =~ /^$key$/) {                        
                        if (@+) {
                            for my $nbr (1 .. (scalar(@+) - 1)) {
                                if (defined $-[$nbr]) {
                                    my $match = substr($in, $-[$nbr], $+[$nbr] - $-[$nbr]);
                                    if (defined($+[$nbr])) {
                                        $self->{cmd_regex}{$nbr} = substr($in, $-[$nbr], $+[$nbr] - $-[$nbr]);
                                    }
                                }
                            }
                        }
                        $state = $self->{states_list}{ $self->{state} }{expect}{$key};
                    }
                }
            }
            if (ref $state eq 'HASH') {
                $self->{previous_state}  = $self->{state};
                $self->{previous_output} = $state->{output} // $self->{states_list}{ $self->{state} }{output} // '';
                $self->{state}           = $state->{matching} // $self->{state};
                $output .= $state->{output} // $self->{states_list}{ $self->{state} }{output} // '';
                if (exists $state->{cmd}) {
                    my $cmd_state = delete $state->{cmd};
                    $cmd_state =~ s/\$in/$in/g;
                    push(@{ $self->{cmd_stack} }, $cmd_state);
                }
                if (exists $state->{cmd_exec}) {
                    my $cmd_exec = join ' ', @{ $self->{cmd_stack} };
                    my $string = `$cmd_exec`;
                    $output = sprintf("%s", $string) . $output;
                    $self->{cmd_exec} = [];
                }
                if (exists $state->{exec}) {
                    my $old_exec = $state->{exec};
                    $state->{exec} =~ s/__IN__/$in/g;
                    foreach my $k (keys %{ $self->{cmd_regex} }) {
                        my $v = $self->{cmd_regex}{$k};
                        my $K = '__' . $k . '__';
                        $state->{exec} =~ s/$K/$v/g;
                    }
                    my $string = `$state->{exec}`;
                    $output = sprintf("%s", $string) . $output;
                    $state->{exec} = $old_exec;
                }
                if (exists $state->{do}) {
                    my $old_do = $state->{do};
                    $state->{do} =~ s/__IN__/$in/g;
                    foreach my $k (keys %{ $self->{cmd_regex} }) {
                        my $v = $self->{cmd_regex}{$k};
                        my $K = '__' . $k . '__';
                        $state->{do} =~ s/$K/$v/g;
                    }
                    $output = (eval { $state->{do} }) . $output;
                    $state->{do} = $old_do;
                }
                if (exists $state->{cat}) {
                    my $old_cat = $state->{cat};
                    $state->{cat} =~ s/__IN__/$in/g;
                    foreach my $k (keys %{ $self->{cmd_regex} }) {
                        my $v = $self->{cmd_regex}{$k};
                        my $K = '__' . $k . '__';
                        $state->{cat} =~ s/$K/$v/g;
                    }
                    my $string = do { local (@ARGV, $/) = $state->{cat}; <> };
                    $output = sprintf("%s", $string) . $output;
                    $state->{cat} = $old_cat;
                }
                if (exists $state->{catRAND}) {
                    my $old_cat = $state->{catRAND};
                    $state->{catRAND} =~ s/__IN__/$in/g;
                    foreach my $k (keys %{ $self->{cmd_regex} }) {
                        my $v = $self->{cmd_regex}{$k};
                        my $K = '__' . $k . '__';
                        $state->{catRAND} =~ s/$K/$v/g;
                    }
                    my @files  = split /\s+/, $state->{catRAND};
                    my $file   = $files[ rand @files ];
                    my $string = do { local (@ARGV, $/) = $file; <> };
                    $output = sprintf("%s", $string) . $output;
                    $state->{catRAND} = $old_cat;
                }
                if (exists $state->{catWRAND}) {
                    my $old_cat = $state->{catWRAND};
                    $state->{catWRAND} =~ s/__IN__/$in/g;
                    foreach my $k (keys %{ $self->{cmd_regex} }) {
                        my $v = $self->{cmd_regex}{$k};
                        my $K = '__' . $k . '__';
                        $state->{catWRAND} =~ s/$K/$v/g;
                    }
                    my %files = map { split /:/ } split /\s+/, $state->{catWRAND};
                    my $file;
                    my $weight;
                    while (my ($p, $w) = each %files) {
                        $w //= 1;
                        $weight += $w // 1;
                        $file = $p if rand($weight) < $w;
                    }
                    my $string = do { local (@ARGV, $/) = $file; <> };
                    $output = sprintf("%s", $string) . $output;
                    $state->{catWRAND} = $old_cat;
                }
                if (exists $state->{catSEQ}) {
                    my $old_cat = $state->{catSEQ};
                    my $state_file;
                    if (exists $state->{catSEQ_idx}) {
                        $state_file = $state->{catSEQ_idx};
                    } else {
                        $state_file = $old_cat . '.state';
                        $state_file =~ s/\s/_/g;

                    }
                    $state->{catSEQ} =~ s/__IN__/$in/g;
                    foreach my $k (keys %{ $self->{cmd_regex} }) {
                        my $v = $self->{cmd_regex}{$k};
                        my $K = '__' . $k . '__';
                        $state->{catSEQ} =~ s/$K/$v/g;
                    }
                    my @files = split /\s+/, $state->{catSEQ};
                    tie my $nbr => 'FSM::Basic::Modulo', scalar @files, 0;
                    if (-f $state_file) {
                        $nbr = do {
                            local (@ARGV, $/) = $state_file;
                            <>;
                        };
                    }
                    my $file = $files[ $nbr++ ];
                    my $string = do { local (@ARGV, $/) = $file; <> };
                    $output = sprintf("%s", $string) . $output;
                    $state->{catSEQ} = $old_cat;
                    write_file($state_file, $nbr);
                }
            } else {
                $self->{previous_state} = $self->{state};
                $self->{state}          = $self->{states_list}{ $self->{state} }{not_matching} // $self->{state};
                $self->{states_list}{ $self->{state} }{repeat}--
                  if exists $self->{states_list}{ $self->{state} }{repeat};
                $output .= $self->{states_list}{ $self->{state} }{output} // '';
                if (exists $self->{states_list}{ $self->{state} }{not_matching_info}) {
                    $output = $self->{states_list}{ $self->{state} }{not_matching_info} . "\n" . $output;
                }
                return ($self->{states_list}{ $self->{state} }{$in}{final} // $self->{states_list}{ $self->{state} }{final} // 0, $output);
            }
            return ($self->{states_list}{ $self->{state} }{$in}{final} // $self->{states_list}{ $self->{state} }{final} // 0, $output);
        }
    }
}

sub set {
    my ($self, $in) = @_;
    $self->{previous_state}  = $self->{state};
    $self->{previous_output} = $self->{states_list}{ $self->{state} }{output} // '';
    $self->{state}           = $in if exists $self->{states_list}{$in};
}

sub write_file {
    my ($file, $content) = @_;
    open my $fh, '>', $file or die "Error opening file for write $file: $!\n";
    print $fh $content;
    close $fh or die "Error closing file $file: $!\n";
}

sub alter {
    my $r = shift;
    my $c = shift // 0;
    $r =~ /([^[]*)\[([^\]]+)\](.*)/;
    my $pre_r   = $1;
    my $match_r = $2;
    my $post_r  = $3;
    my $out     = $pre_r.'(';
    for (my $i = 1 ; $i <= length $match_r ; $i++) {
        $out .=  substr($match_r, 0, $i) . '|';
    }
    chop $out;
    $post_r = alter($post_r) if $post_r=~ /\[([^\]]+)\]/ ;
    $out = $out. ')' . $post_r;
    $out = '(?i:' . $out. ')' if $c ;
    return $out;
}

package FSM::Basic::Modulo;
sub TIESCALAR { bless [ $_[2] || 0, $_[1] ] => $_[0] }
sub FETCH { ${ $_[0] }[0] }
sub STORE { ${ $_[0] }[0] = $_[1] % ${ $_[0] }[1] }
1;

=back

B<EXAMPLE>


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
                "read"         => {'cat' => 'file.txt'},
                "read_random"  => {'catRAND' => 'file1.txt file2.txt file3.txt'},
                "read_seq"     => {'catSEQ' => 'file1.txt file2.txt file3.txt', 'catSEQ_idx' => 'catSEQ_status'},
                'meminfo'      => {'do' => 'do { local( @ARGV, $/ ) = "/proc/meminfo" ; <> }'},
                'mem'          => {
				   'do' => "my ( $tot,$avail) = (split /\n/ ,do { local( @ARGV, $/ ) = \"/proc/meminfo\" ; <> })[0,2];$tot =~ s/\\D*//g; $avail =~ s/\\D*//g; sprintf \"%0.2f%%\\n\",(100*($tot-$avail)/$tot);"
			          },
                'h(elp)?|\\?'  => {
                    'output' => 'exit
    read
    read_random
    read_seq
    meminfo
    mem_usage
    mem
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


TODO

add "edit" to allow on the fly modification of the states definition

add "verify_states" to check all states are reachable from a original state

B<SEE ALSO>

FSA::Rules

https://metacpan.org/pod/FSA::Rules


B<AUTHOR>

DULAUNOY Fabrice, C<< <fabrice at dulaunoy.com> >>

B<BUGS>

Please report any bugs or feature requests to C<bug-FSM-basic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FSM-Basic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

B<SUPPORT>

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


B<ACKNOWLEDGEMENTS>


B<LICENSE AND COPYRIGHT>

Copyright 2008 - 2020 DULAUNOY Fabrice.

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
