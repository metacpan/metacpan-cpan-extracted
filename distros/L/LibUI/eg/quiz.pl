use v5.40;
use blib;
use LibUI qw[:all];

# Quiz Demo - multiple-choice quiz with navigation, scoring, and results
my $mainwin;
my $lbl_question;
my $lbl_progress;
my $lbl_score;
my $radio;
my $btn_prev;
my $btn_next;
my $lbl_laps;
my @questions = (
    { q => 'What is the capital of France?',        opts => [ 'London', 'Berlin',  'Paris',  'Madrid' ],     ans => 2 },
    { q => 'Which planet is closest to the Sun?',   opts => [ 'Venus',  'Mercury', 'Earth',  'Mars' ],       ans => 1 },
    { q => 'What is 7 x 8?',                        opts => [ '54',     '56',      '64',     '48' ],         ans => 1 },
    { q => 'Which language runs in a web browser?', opts => [ 'C++',    'Java',    'Python', 'JavaScript' ], ans => 3 },
    {   q    => 'What does HTML stand for?',
        opts => [ 'Hyper Text Markup Language', 'High Tech Modern Language', 'Home Tool Management Language', 'Hyper Transfer Markup Language' ],
        ans  => 0,
    },
    { q => 'Which data structure uses FIFO?',             opts => [ 'Stack',          'Queue',      'Tree',             'Graph' ],         ans => 1 },
    { q => 'What is the chemical symbol for water?',      opts => [ 'O2',             'CO2',        'H2O',              'NaCl' ],          ans => 2 },
    { q => 'Who authored the Perl programming language?', opts => [ 'Dennis Ritchie', 'Larry Wall', 'Guido van Rossum', 'James Gosling' ], ans => 1 }
);
my $current = 0;
my @answers;    # -1 = unanswered, else selected index
my $quiz_done = 0;

sub format_question($q) {
    my $text   = $q->{q} . "\n\n";
    my @labels = ( 'A', 'B', 'C', 'D' );
    for my $i ( 0 .. $#{ $q->{opts} } ) {
        $text .= "  $labels[$i].  $q->{opts}[$i]\n";
    }
    return $text;
}

sub load_question() {
    return if $quiz_done;
    my $q = $questions[$current];
    uiLabelSetText( $lbl_question, format_question($q) );
    uiLabelSetText( $lbl_progress, 'Question ' . ( $current + 1 ) . ' of ' . scalar(@questions) );
    my $sel = $answers[$current];
    uiRadioButtonsSetSelected( $radio, $sel >= 0 ? $sel : 0 );
    if   ( $current == 0 ) { uiControlDisable($btn_prev) }
    else                   { uiControlEnable($btn_prev) }
    if   ( $current == $#questions ) { uiButtonSetText( $btn_next, 'Finish' ) }
    else                             { uiButtonSetText( $btn_next, 'Next' ) }
}

sub save_answer() {
    return if $quiz_done;
    $answers[$current] = uiRadioButtonsSelected($radio);
}

sub show_results() {
    $quiz_done = 1;
    my $correct = 0;
    for my $i ( 0 .. $#questions ) {
        $correct++ if defined $answers[$i] && $answers[$i] == $questions[$i]{ans};
    }
    my $total = scalar(@questions);
    my $pct   = int( $correct / $total * 100 );
    uiLabelSetText( $lbl_question, 'Quiz Complete!' );
    uiLabelSetText( $lbl_progress, '' );
    uiLabelSetText( $lbl_score,    "Score: $correct / $total ($pct%)" );
    my $detail = '';
    for my $i ( 0 .. $#questions ) {
        my $q    = $questions[$i];
        my $got  = ( defined $answers[$i] && $answers[$i] >= 0 ) ? $q->{opts}[ $answers[$i] ] : '(no answer)';
        my $want = $q->{opts}[ $q->{ans} ];
        my $mark = ( defined $answers[$i] && $answers[$i] == $q->{ans} ) ? 'Correct' : 'Wrong';
        $detail .= sprintf( "Q%d: %s\n  Your answer: %s (%s)\n\n", $i + 1, $q->{q}, $got, $mark );
    }
    uiMultilineEntrySetText( $lbl_laps, $detail );
    uiControlHide($btn_prev);
    uiButtonSetText( $btn_next, 'Restart' );
}

sub restart() {
    $quiz_done = 0;
    $current   = 0;
    @answers   = (-1) x scalar(@questions);
    uiLabelSetText( $lbl_score, '' );
    uiMultilineEntrySetText( $lbl_laps, '' );
    uiButtonSetText( $btn_next, 'Next' );
    load_question();
}

sub go_next() {
    save_answer();
    if ($quiz_done)                { restart();      return }
    if ( $current == $#questions ) { show_results(); return }
    $current++;
    load_question();
}

sub go_prev() {
    save_answer();
    return if $current == 0;
    $current--;
    load_question();
}

sub on_closing( $w, $data ) {
    uiQuit();
    return 1;
}

sub should_quit($data) {
    uiControlHide($mainwin);
    return 1;
}
#
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Quiz', 500, 500, 0 );
uiWindowSetMargined( $mainwin, 1 );
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, undef );
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );

# Header
$lbl_progress = uiNewLabel('');
uiBoxAppend( $vbox, $lbl_progress, 0 );

# Question with inline options
$lbl_question = uiNewLabel('');
uiBoxAppend( $vbox, $lbl_question, 0 );

# Radio buttons (A/B/C/D - always 4)
$radio = uiNewRadioButtons();
uiRadioButtonsAppend( $radio, 'A' );
uiRadioButtonsAppend( $radio, 'B' );
uiRadioButtonsAppend( $radio, 'C' );
uiRadioButtonsAppend( $radio, 'D' );
uiBoxAppend( $vbox, $radio, 0 );

# Navigation
my $hbox = uiNewHorizontalBox();
uiBoxSetPadded( $hbox, 1 );
uiBoxAppend( $vbox, $hbox, 0 );
$btn_prev = uiNewButton('Previous');
$btn_next = uiNewButton('Next');
uiButtonOnClicked( $btn_prev, sub { go_prev() }, undef );
uiButtonOnClicked( $btn_next, sub { go_next() }, undef );
uiBoxAppend( $hbox, $btn_prev, 1 );
uiBoxAppend( $hbox, $btn_next, 1 );

# Score
$lbl_score = uiNewLabel('');
uiBoxAppend( $vbox, $lbl_score, 0 );

# Separator
uiBoxAppend( $vbox, uiNewHorizontalSeparator(), 0 );

# Results detail
$lbl_laps = uiNewNonWrappingMultilineEntry();
uiMultilineEntrySetReadOnly( $lbl_laps, 1 );
uiBoxAppend( $vbox, $lbl_laps, 1 );

# Initialize
@answers = (-1) x scalar(@questions);
load_question();
uiControlShow($mainwin);
uiMain();
