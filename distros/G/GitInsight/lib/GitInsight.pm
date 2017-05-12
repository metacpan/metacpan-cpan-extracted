package GitInsight;

# XXX: Add behavioural change detection, focusing on that period for predictions

BEGIN {
    $|  = 1;
    $^W = 1;
}
our $VERSION = '0.06';

#use Carp::Always;
use GitInsight::Obj -base;
use strict;
use warnings;
use 5.008_005;
use GD::Simple;

use Carp;
use Storable qw(dclone);
use POSIX;
use Time::Local;
use GitInsight::Util
    qw(markov markov_list LABEL_DIM gen_m_mat gen_trans_mat info error warning wday label prob label_step);
use List::Util qw(max);

use LWP::UserAgent;
use POSIX qw(strftime ceil);

has [qw(username contribs calendar)];
has 'verbose'      => sub {0};
has 'no_day_stats' => sub {0};
has 'statistics'   => sub {0};
has 'ca_output'    => sub {1};
has 'accuracy'     => sub {0};
has [qw(left_cutoff cutoff_offset file_output)];

sub contrib_calendar {
    my $self = shift;
    my $username = shift || $self->username;
    $self->username($username) if !$self->username;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $response
        = $ua->get(
        'https://github.com/users/' . $username . '/contributions' );
    info "Getting "
        . 'https://github.com/users/'
        . $username
        . '/contributions'
        if $self->verbose;

    if ( $response->is_success ) {
        $self->decode( $response->decoded_content );
        return $self->contribs;
    }
    else {
        die $response->status_line;
    }
}

sub draw_ca {
    my $self = shift;
    my @CA   = @_;
    my $cols = ceil( $#CA / 7 ) + 1;
    my $rows = 7;

    my $cell_width  = 50;
    my $cell_height = 50;
    my $border      = 3;
    my $width       = $cols * $cell_width;
    my $height      = $rows * $cell_height;

    my $img = GD::Simple->new( $width, $height );

    $img->font(gdSmallFont);    #i'll need that later
    for ( my $c = 0; $c < $cols; $c++ ) {
        for ( my $r = 0; $r < $rows; $r++ ) {
            my $color = $CA[ $c * $rows + $r ]
                or
                next; #infering ca from sequences of colours generated earlier
            my @topleft = ( $c * $cell_width, $r * $cell_height );
            my @botright = (
                $topleft[0] + $cell_width - $border,
                $topleft[1] + $cell_height - $border
            );
            eval {
                $img->bgcolor( @{$color} );
                $img->fgcolor( @{$color} );
            };
            $img->rectangle( @topleft, @botright );
            $img->moveTo( $topleft[0] + 2, $botright[1] + 2 );
            $img->fgcolor( 255, 0, 0 )
                and $img->rectangle( @topleft, @botright )
                if ( $c * $rows + $r >= ( scalar(@CA) - 7 ) );
            $img->fgcolor( 0, 0, 0 )
                and $img->string( $GitInsight::Util::wday[$r] )
                if ( $c == 0 );
        }
    }
    if ( defined $self->file_output ) {
        my $filename = $self->file_output . ".png";

        #. "/"
        #. join( "_", $self->start_day, $self->last_day ) . "_"
        #. $self->username . "_"
        #. scalar(@CA) .
        open my $PNG, ">" . $filename;
        binmode($PNG);
        print $PNG $img->png;
        close $PNG;
        info "File written in : " . $filename if $self->verbose;
        return $filename;
    }
    else {
        return $img->png;
    }

}

# useful when interrogating the object
sub start_day            { shift->{first_day}->{data} }
sub last_day             { @{ shift->{result} }[-1]->[2] }
sub prediction_start_day { @{ shift->{result} }[0]->[2] }

sub _accuracy {
    my $self = shift;
    my ( @chunks, @commits );
    push @chunks, [ splice @{ $self->calendar }, 0, 7 ]
        while @{ $self->calendar };

    #@chunks contain a list of arrays of 7 days each

    my $total_days = 0;
    my $accuracy   = 0;
    for (@chunks) {

        # next if @{$_} < 4;
        push( @commits, @{$_} );
        my $Insight = GitInsight->new(
            no_day_stats => $self->no_day_stats,
            ca_output    => 0,
            username     => $self->username
        );    #disable png generation
        $Insight->decode( [@commits] )
            ;    #using $_ for small contributors is better
        $Insight->process;
        foreach my $res ( @{ $Insight->{result} } ) {
            next if ( !exists $self->contribs->{ $res->[2] }->{l} );
            $accuracy++
                if ( $self->contribs->{ $res->[2] }->{l} == $res->[1] );
            $total_days++;
        }
    }
    my $accuracy_prob = prob( $total_days, $accuracy );
    $self->{accuracy} = $accuracy_prob;
    info "Accuracy is $accuracy / $total_days" if $self->verbose;
    info sprintf( "%.5f", $accuracy_prob * 100 ) . " \%" if $self->verbose;
    return $self;
}

sub _decode_calendar {
    shift;
    my $content = shift;
    my @out;
    push( @out, [ $2, $1 ] )
        while ( $content =~ m/data\-count="(.*?)" data\-date="(.*?)"/g );

    return \@out;
}

# first argument is the data:
# it should be a string in the form [ [2013-01-20, 9], ....    ] a stringified form of arrayref. each element must be an array ref containing in the first position the date, and in the second the commits .
sub decode {
    my $self = shift;

    #my $response = ref $_[0] ne "ARRAY" ? eval(shift) : shift;
    my $response
        = ref $_[0] ne "ARRAY" ? $self->_decode_calendar(shift) : shift;
    $self->calendar( dclone($response) );
    my %commits_count;
    my $min = $self->left_cutoff || 0;
    $self->{result} = [];    #empty the result
    $min = 0 if ( $min < 0 );    # avoid negative numbers
    my $max
        = $self->cutoff_offset || ( scalar( @{$response} ) - 1 );
    $max = scalar( @{$response} )
        if $max > scalar( @{$response} )
        ;    # maximum cutoff boundary it's array element number
    info "$min -> $max portion" if $self->verbose;
    my $max_commit
        = max( map { $_->[1] } @{$response} );    #Calculating label steps
    label_step( 0 .. $max_commit );   #calculating quartiles over commit count
    info( "Max commit is: " . $max_commit ) if $self->verbose;
    $self->{first_day}->{day} = wday( $response->[0]->[0] )
        ; #getting the first day of the commit calendar, it's where the ca will start
    my ($index)
        = grep { $GitInsight::Util::wday[$_] eq $self->{first_day}->{day} }
        0 .. $#GitInsight::Util::wday;
    $self->{first_day}->{index} = $index;
    $self->{first_day}->{data}  = $response->[$min]->[0];
    push( @{ $self->{ca} }, [ 255, 255, 255 ] )
        for (
        0 .. scalar(@GitInsight::Util::wday)    #white fill for labels
        + ( $index - 1 )
        );                                      #white fill for no contribs

    $self->{transition} = gen_trans_mat( $self->no_day_stats );
    my $last;
    $self->{last_week}
        = [ map { [ $_->[0], label( $_->[1] ) ] }
            ( @{$response} )[ ( ( $max + $min ) - 6 ) .. ( $max + $min ) ] ]
        ; # cutting the last week from the answer and substituting the label instead of the commit number
          #print( $self->{transition}->{$_} ) for (last_week keys $self->{transition} );
          # $self->{max_commit} =0;
    $self->contribs(
        $self->no_day_stats
        ? { map {
                my $l = label( $_->[1] );
                push( @{ $self->{ca} }, $GitInsight::Util::CA_COLOURS{$l} )
                    ;    #building the ca
                $last = $l if ( !$last );

                #    $commits_count{ $_->[1] } = 1;
                $self->{stats}->{$l}++
                    if $self->statistics == 1;    #filling stats hashref
                $self->{transition_hash}->{$last}->{$l}++
                    ; #filling transition_hash hashref from $last (last seen label) to current label
                $self->{transition}
                    ->slice("$last,$l")++;    #filling transition matrix
                 #$self->{max_commit} = $_->[1] if ($_->[1]>$self->{max_commit});
                $last = $l;
                $_->[0] => {
                    c => $_->[1],    #commits
                    l => $l          #label
                    }

            } splice( @{$response}, $min, ( $max + 1 ) )
            }
        : { map {
                my $w = wday( $_->[0] );
                my $l = label( $_->[1] );
                push( @{ $self->{ca} }, $GitInsight::Util::CA_COLOURS{$l} );
                $last = $l if ( !$last );

                #   $commits_count{ $_->[1] } = 1;
                $self->{stats}->{$w}->{$l}++
                    if $self->statistics == 1;    #filling stats hashref
                $self->{transition_hash}->{$w}->{$last}
                    ->{$l}++;                     #filling stats hashref
                $self->{transition}->{$w}
                    ->slice("$last,$l")++;        #filling transition matrix
                $last = $l;
                $_->[0] => {
                    c => $_->[1],                 #commits
                    d => $w,                      #day in the week
                    l => $l                       #label
                    }

            } splice( @{$response}, $min, ( $max + 1 ) )
        }
    );

    return $self->contribs;
}

sub process {
    my $self = shift;
    croak "process() called while you have not specified an username"
        if !$self->username;
    $self->contrib_calendar( $self->username )
        if !$self->contribs and $self->username;
    $self->_transition_matrix;
    $self->_markov;
    $self->_gen_stats if ( $self->statistics );
    $self->{png} = $self->draw_ca( @{ $self->{ca} } )
        if ( $self->ca_output == 1 );
    $self->{steps} = \%GitInsight::Util::LABEL_STEPS;
    $self->_accuracy if $self->accuracy and $self->accuracy == 1;
    return $self;
}

sub _gen_stats {
    my $self = shift;
    my $sum  = 0;
    if ( $self->no_day_stats ) {
        $sum += $_ for values %{ $self->{stats} };
        foreach my $k ( keys %{ $self->{stats} } ) {
            info "Calculating probability for label $k  $sum /  "
                . $self->{stats}->{$k}
                if $self->verbose;
            my $prob = prob( $sum, $self->{stats}->{$k} );
            info "Is: $prob" if $self->verbose;
            $self->{stats}->{$k} = sprintf "%.5f", $prob;
        }
    }
    else {
        foreach my $k ( keys %{ $self->{stats} } ) {
            $sum = 0;
            $sum += $_ for values %{ $self->{stats}->{$k} };
            map {
                info "Calculating probability for $k -> label $_  $sum /  "
                    . $self->{stats}->{$k}->{$_}
                    if $self->verbose;
                my $prob = prob( $sum, $self->{stats}->{$k}->{$_} );
                info "Is: $prob" if $self->verbose;
                $self->{stats}->{$k}->{$_} = sprintf "%.5f", $prob;
            } ( keys %{ $self->{stats}->{$k} } );
        }
    }
}

sub _markov {
    my $self = shift;
    info "Markov chain phase" if $self->verbose;
    my $dayn = 1;
    info "Calculating predictions for "
        . ( scalar( @{ $self->{last_week} } ) ) . " days"
        if $self->verbose;

    foreach my $day ( @{ $self->{last_week} } ) {    #cycling the last week
        my $wd = wday( $day->[0] );                  #computing the weekday
        my $ld = $day->[1];                          #getting the label
        my $M  = markov_list(
            gen_m_mat($ld),
            $self->no_day_stats
            ? $self->{transition}
            : $self->{transition}->{$wd},
            $dayn
        );    #Computing the markov for the state

        my $label = 0;
        $M->[$label] > $M->[$_] or $label = $_ for 1 .. scalar(@$M) - 1;
        push( @{ $self->{ca} }, $GitInsight::Util::CA_COLOURS{$label} )
            ;    #adding the predictions to ca

        my ( $mday, $mon, $year )
            = reverse( split( /-/, $day->[0] ) );    #splitting date

        push(
            @{ $self->{result} },
            [   $wd, $label,
                $day->[0] = strftime(
                    '%Y-%m-%d',
                    localtime(
                        timelocal( 0, 0, 0, $mday, $mon - 1, $year )
                            + 7 * 86_400
                    )
                    ) #adding 7 days to the date, and adding the result to $self->{result}
                ,
                $M
            ]
        );

        if ( $self->verbose ) {
            info "$wd: "
                . $label . " has "
                . ( sprintf "%.2f", $M->[$label] * 100 )
                . "% of probability to happen";
            info "\t"
                . $_
                . " ---- "
                . ( sprintf "%.2f", $M->[$_] * 100 ) . "%"
                for 0 .. scalar(@$M) - 1;
        }

        ############# TREEMAP GENERATION #############
        $self->{'treemap'}->{'name'} = "day";
        my $hwd = { name => $day->[0], children => [] };
        push(
            @{ $hwd->{children} },
            { name => $_, size => $M->[$_] * 10000 }
        ) for 0 .. scalar(@$M) - 1;
        push( @{ $self->{'treemap'}->{"children"} }, $hwd );
        ################################################

        $dayn++ if $self->no_day_stats;
    }

    return $self->{result};

}

sub _transition_matrix {

#transition matrix, sum all the transitions occourred in each day,  and do prob(sumtransitionrow ,current transation occurrance )
    my $self = shift;
    info "Going to build transation matrix probabilities" if $self->verbose;
    if ( $self->no_day_stats ) {
        my $sum = $self->{transition}->sumover();
        map {
            foreach my $c ( 0 .. LABEL_DIM ) {
                $self->{transition}->slice("$_,$c")
                    .= prob( # slice of the single element of the matrix , calculating bayesian inference
                    $sum->at($c),    #contains the transition sum of the row
                    $self->{transition}->at( $_, $c )
                    );    # all the transation occurred, current transation
            }
        } ( 0 .. LABEL_DIM );
    }
    else {
        foreach my $k ( keys %{ $self->{transition} } ) {
            my $sum = $self->{transition}->{$k}->sumover();
            map {
                foreach my $c ( 0 .. LABEL_DIM ) {
                    $self->{transition}->{$k}->slice("$_,$c")
                        .= prob( # slice of the single element of the matrix , calculating bayesian inference
                        $sum->at($c)
                        , #contains the transition sum of the row over the day
                        $self->{transition}->{$k}->at( $_, $c )
                        )
                        ; # all the transation occurred in those days, current transation
                }
            } ( 0 .. LABEL_DIM );
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

GitInsight - Predict your github contributions using Bayesian inference and Markov chain

=head1 SYNOPSIS

    gitinsight --username [githubusername] (--nodaystats) (--accuracy) #using the shipped bin

    #or using the module

    my $Insight= GitInsight->new(no_day_stats => 0, username => "markov", accuracy=> 1);
    my $Result= $Insight->process;
    my $accuracy = $Insight->{accuracy};
    $Result = $Insight->{result};
    # $Result contains the next week predictions and is an arrayref of arrayrefs    [  [ 'Sat', 1, '2014-07-1', [ 0 ,  '0.151515151515152', '0.0606060606060606', '0.0404040404040404',  0  ]  ],   ..   [            'DayofWeek',      'winner_label',  'day' ,  [             probability_label_0,  probability_label_1,              probability_label_2,          probability_label_3,              probability_label_4            ]          ]]


=head1 DESCRIPTION

GitInsight is module that allow you to predict your github contributions in the "calendar contribution" style of github (the table of contribution that you see on your profile page).

=head1 HOW DOES IT WORK?

GitInsight generates a transation probrability matrix from your github contrib_calendar to compute the possibles states for the following days. Given that GitHub split the states thru 5 states (or here also called label), the probability can be inferenced by using Bayesian methods to update the beliefs of the possible state transition, while markov chain is used to predict the states. The output of the submitted data is then plotted using Cellular Automata.

=head2 THEORY

We trace the transitions states in a matrix and increasing the count as far as we observe a transition (L<https://en.wikipedia.org/wiki/Transition_matrix>), then we inference the probabilities using Bayesan method L<https://en.wikipedia.org/wiki/Bayesian_inference> L<https://en.wikipedia.org/wiki/Examples_of_Markov_chains>.

=head1 INSTALLATION

GitInsight requires the installation of gsl (GNU scientific library), gd(http://libgd.org/), PDL and PDL::Stats  (to be installed after the gsl library set).

on Debian:

        apt-get install gsl-bin libgs10-devt
        apt-get install pdl libpdl-stats-perl libgd2-xpm-dev

It's reccomended to use cpanm to install all the required deps, install it thru your package manager or just do:

    cpan App::cpanminus

After the installation of gsl, clone the repository and install all the dependencies with cpanm:

    cpanm --installdeps .

Then install it as usual:

    perl Build.PL
    ./Build
    ./Build test #ensure that the module works correctly
    ./Build install

=head1 OPTIONS

=head2 username

required, it's the GitHub username used to calculate the prediction

=head2 ca_output

you can enable/disable the cellular autmata output using this option (1/0)

=head2 no_day_stats

setting this option to 1, will slightly change the prediction: it will be calculated a unique transition matrix instead one for each day

=head2 left_cutoff

used to cut the days from the start (e.g. if you want to delete the first 20 days from the prediction, just set this to 20)

=head2 cutoff_offset

used to select a range where the prediction happens (e.g. if you want to calculate the prediction of a portion of your year of contribution)

=head2 file_output

here you can choose the file output name for ca.

=head2 accuracy

Enable/disable accuracy calculation (1/0)

=head2 verbose

Enable/disable verbosity (1/0)

=head1 METHODS

=head2 contrib_calendar($username)

Fetches the github contrib_calendar of the specified user

=head2 process

Calculate the predictions and generate the CA

=head2 start_day

Returns the first day of the contrib_calendar

=head2 last_day

Returns the last day of the contrib calendar (prediction included)

=head2 prediction_start_day

Returns the first day of the prediction (7 days of predictions)

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<GitInsight::Util>, L<PDL>, L<PDL::Stats>

=cut
