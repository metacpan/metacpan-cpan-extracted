use v5.12;
use warnings;

package Kephra::App::Editor::Position;

package Kephra::App::Editor;


sub line_start {
    my ($self, $pos) = @_;
    my $line = $self->LineFromPosition( $pos );
    return $line if $line == -1;
    $self->GetLineIndentPosition( $line );
}

sub word_edges {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    ($self->WordStartPosition( $pos, 1 ), $self->WordEndPosition( $pos, 1 ) );
}

sub block_edges_expand {
    my ($self, $sel_start, $sel_end) = @_;
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $line_nr = $self->LineFromPosition( $sel_start );
    return unless $self->GetLine( $line_nr ) =~ /\S/;
    $line_nr-- while $line_nr > 0 and $self->GetLine( $line_nr ) =~ /\S/;
    $line_nr++ unless $self->GetLine( $line_nr ) =~ /\S/;
    my $block_start = $self->PositionFromLine( $line_nr );
    my $last_line_nr = $self->GetLineCount - 1;
    $line_nr = $self->LineFromPosition( $sel_start );
    $line_nr++ while $line_nr < $last_line_nr and $self->GetLine( $line_nr ) =~ /\S/;
    $line_nr-- unless $self->GetLine( $line_nr ) =~ /\S/;
    my $block_end = $self->GetLineEndPosition( $line_nr );
    return if $block_end < $sel_end;
    return if $sel_start == $block_start and $sel_end == $block_end;
    ($block_start, $block_end);
}

sub style_edges {
    my ($self, $sel_start, $sel_end) = @_;
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start;
    my ($style_start, $style_end) = ($sel_start, $sel_start);
    my $style = $self->GetStyleAt( $sel_start );
    $style_start-- while $style_start and $self->GetStyleAt( $style_start ) == $style;
    $style_start++ if $self->GetStyleAt( $style_start ) != $style;
    my $last_pos = $self->GetTextLength - 1;
    $style_end++ while $style_end < $last_pos and $self->GetStyleAt( $style_end ) == $style;
    # $style_end-- if $self->GetStyleAt( $style_end ) != $style;
    return if $style_start == $sel_start and $style_end == $sel_end;
    return ($style_start, $style_end) if $style_end >= $sel_end;
}

sub brace_edges_expand {
    my ($self, $sel_start, $sel_end, $line) = @_; # look only in $line if defined
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start;
    $self->GotoPos( $sel_start);
    $self->SearchAnchor;
    my $npos = $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '[([{]');
    return if defined $line and $line != $self->LineFromPosition( $npos );
    my $match = $self->BraceMatch( $npos );
    return if $match < 0;
    return if defined $line and $line != $self->LineFromPosition( $match );
    return if $npos > $sel_end or $match <= $sel_start;
    ($npos, $match+1);
}

sub brace_edges_shrink {
    my ($self, $sel_start, $sel_end) = @_;
    return () unless defined $sel_end;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    $self->GotoPos( $sel_start + 1 );
    $self->SearchAnchor;
    my $npos = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '[([{]');
    return () if $npos < 0 or $npos >= $sel_end;
    my $match = $self->BraceMatch( $npos );
    return if $match < 0 or $match >= $sel_end;
    ($npos, $match+1);
}

sub loop_edges_expand {
    my ($self, $sel_start, $sel_end) = @_;
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start; # $self->GetStyleAt( $pos); 5
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $search_start = $sel_start;
    my $line_start = $self->line_start( $sel_start );
    $search_start = $line_start if $line_start > $search_start;
    my $loop_start = -1;
    my $npos;
    $self->GotoPos( $search_start + 5 );
    $self->SearchAnchor;
    $npos = $self->SearchPrev( 0, 'for');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchPrev( 0, 'until');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchPrev( 0, 'while');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    return if $loop_start == -1;
    my @edges = $self->loop_edges( $loop_start );
    return unless @edges and $edges[1] >= $sel_end;
    return @edges if $edges[0] < $sel_start or $edges[1] > $sel_end;
    $self->GotoPos(  $loop_start );
    $self->SearchAnchor;
    $loop_start = -1;
    $npos = $self->SearchPrev( 0, 'for');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchPrev( 0, 'until');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchPrev( 0, 'while');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    return unless $loop_start > -1;
    $self->loop_edges( $loop_start );
}
sub loop_edges_shrink {
    my ($self, $sel_start, $sel_end) = @_;
    return () unless defined $sel_end;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $search_start = $sel_start;
    my $line_start = $self->line_start( $sel_start );
    $search_start = $line_start if $line_start > $search_start;
    my $loop_start = -1;
    my $npos;
    $self->GotoPos( $sel_start - 5);
    $self->SearchAnchor;
    $npos = $self->SearchNext( 0, 'for');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchNext( 0, 'until');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchNext( 0, 'while');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    return if $loop_start == -1;
    my @edges = $self->loop_edges( $loop_start );
    return unless @edges and $edges[1] <= $sel_end;
    return @edges if $edges[0] > $sel_start or $edges[1] < $sel_end;
    $search_start = $loop_start;
    $self->GotoPos(  $search_start );
    $self->SearchAnchor;
    $loop_start = -1;
    $npos = $self->SearchNext( 0, 'for');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchNext( 0, 'until');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    $npos = $self->SearchNext( 0, 'while');
    $loop_start = $npos if $npos > $loop_start and $self->GetStyleAt( $npos ) == 5;
    return if  $loop_start == $search_start;
    @edges = $self->loop_edges( $loop_start );
    return $edges[1] > $sel_end;
    @edges;
}

sub loop_edges {
    my ($self, $start) = @_;
    $self->GotoPos( $start );
    $self->SearchAnchor;
    my $npos = $self->SearchNext( 0, '(');
    return if $npos == -1;
    my $match = $self->BraceMatch( $npos );
    return if $match == -1;
    $self->SearchAnchor;
    $npos = $self->SearchNext( 0, '{');
    return if $npos == -1;
    $match = $self->BraceMatch( $npos );
    return if $match == -1;
    ($self->PositionFromLine( $self->LineFromPosition( $start )), $match+1);
}


sub sub_edges_expand {
    my ($self, $sel_start, $sel_end) = @_;
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $start_line = $self->prev_sub( $sel_start + 5 );
    return if $start_line == -1;
    my $sub_start = $self->PositionFromLine( $self->LineFromPosition( $start_line ) );
    $self->GotoPos( $sub_start );
    $self->SearchAnchor;
    my $bpos = $self->SearchNext( 0, '{');
    return if $bpos == -1;
    my $sub_end = $self->BraceMatch( $bpos );
    return if $sub_end == -1 or $sub_end < $sel_end;
    return if $sub_start == $sel_start and  $sub_end == $sel_end;
    ($sub_start, $sub_end+1);
}
sub sub_edges_shrink {
    my ($self, $sel_start, $sel_end) = @_;
    return () unless defined $sel_end;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $start_line = $self->next_sub( $sel_start);
    return if $start_line < 0;
    my $sub_start = $self->PositionFromLine( $self->LineFromPosition( $start_line ) );
    $self->GotoPos( $sub_start );
    $self->SearchAnchor;
    my $bpos = $self->SearchNext( 0, '{');
    return if $bpos == -1;
    my $sub_end = $self->BraceMatch( $bpos );
    return if $sub_end == -1 or $sub_end > $sel_end;
    return if $sub_start == $sel_start and  $sub_end == $sel_end;
    ($sub_start, $sub_end+1);
}

sub get_prev_block_start {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    return 0 if $line_nr == 0;
    unless ( $self->GetLine( --$line_nr ) =~ /\S/ ){
         while ($line_nr > 0){
             last if $self->GetLine( $line_nr ) =~ /\S/;
             $line_nr--;
    } }
    while ($line_nr > 0){
        last unless $self->GetLine( $line_nr - 1 ) =~ /\S/;
        $line_nr--;
    }
    $line_nr;
}
sub get_next_block_start {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    my $last_line_nr = $self->GetLineCount - 1;
    return $line_nr if $line_nr == $last_line_nr;
    if ( $self->GetLine( ++$line_nr ) =~ /\S/ ){
         while ($line_nr < $last_line_nr){
             last unless $self->GetLine( ++$line_nr ) =~ /\S/;
    } }
    while ($line_nr < $last_line_nr){
        last if $self->GetLine( ++$line_nr ) =~ /\S/;
    }
    $line_nr;
}
sub get_prev_block_end {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    return 0 if $line_nr == 0;
    if ( $self->GetLine( --$line_nr ) =~ /\S/ ){
         while ($line_nr > 0){
             last unless $self->GetLine( --$line_nr ) =~ /\S/;
    } }
    while ($line_nr > 0){
        last if $self->GetLine( --$line_nr ) =~ /\S/;
    }
    $line_nr;
}
sub get_next_block_end {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    my $last_line_nr = $self->GetLineCount - 1;
    return $line_nr if $line_nr == $last_line_nr;
    unless ( $self->GetLine( ++$line_nr ) =~ /\S/ ){
         while ($line_nr < $last_line_nr){
             last if $self->GetLine( ++$line_nr ) =~ /\S/;
    } }
    while ($line_nr < $last_line_nr){
        last unless $self->GetLine( $line_nr + 1 ) =~ /\S/;
        $line_nr++;
    }
    $line_nr;
}

sub prev_sub {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos-1 );
    $self->SearchAnchor;
    $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub next_sub {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos+1 );
    $self->SearchAnchor;
    $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub smart_up_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $bpos = $self->prev_brace_pos( $pos );
    return $bpos if $bpos != $pos;
    my $line_nr = $self->get_prev_block_start( $pos );
    defined $line_nr ? $self->PositionFromLine( $line_nr ) : $pos;
}

sub smart_down_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $bpos = $self->next_brace_pos( $pos );
    return $bpos if $bpos != $pos;
    my $line_nr = $self->get_next_block_start( $pos );
    defined $line_nr ? $self->PositionFromLine( $line_nr ) : $pos;
}

sub prev_brace_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    if ( $char_before eq ')' or $char_before eq '}' or $char_before eq ']' ) {
        my $mpos = $self->BraceMatch( $pos - 1 );
        return $mpos if $mpos != &Wx::wxSTC_INVALID_POSITION;
    } elsif ($char_after eq ')' or $char_after eq '}' or $char_after eq ']'){
        my $mpos = $self->BraceMatch( $pos );
        return $mpos + 1 if $mpos != &Wx::wxSTC_INVALID_POSITION;
    }
    $pos;
}

sub next_brace_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    if ( $char_before eq '(' or $char_before eq '{' or $char_before eq '[' ) {
        my $mpos = $self->BraceMatch( $pos - 1 );
        return $mpos if $mpos != &Wx::wxSTC_INVALID_POSITION;
    } elsif ($char_after eq '(' or $char_after eq '{' or $char_after eq '['){
        my $mpos = $self->BraceMatch( $pos );
        return $mpos + 1 if $mpos != &Wx::wxSTC_INVALID_POSITION;
    }
    $pos;
}


1;
