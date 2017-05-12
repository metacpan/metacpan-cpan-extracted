package Games::Baseball::Scorecard;

use warnings;
use strict;

require 5.006;

use File::Path;
use File::Temp 'tempdir';
use File::Spec::Functions qw(:DEFAULT rel2abs);
use Text::ParseWords;

our $VERSION = '0.03';

our($SCORECARD, $TEX, $TEXD);
our $MPOST   = 'mpost';
our $MPTOPDF = 'mptopdf';
our $PDFTEX  = 'pdftex';
our $OPEN    = 'open';

# default: black
our @COLOR = (0, 0, 0);
# others:
# light cyan
#@COLOR = (.10, 1, 1);
# dark cyan
#@COLOR = (.25, 1, 1);
# grey
#@COLOR = (.4, .4, .4);

our @FONTS = (
	# defaults that look very nice
	[ myriadrcrrl =>  9 ],
	[ myriadrcbrl => 14 ],
	[ myriadrcrrl => 14 ],
	[ myriadrcbrl => 22 ],
);

# cmssdc10 is another nice one, i prefer this: it's darker and narrower
@FONTS = (
	# ones that should work everywhere:
	[ phvr8rn =>  8 ],
	[ phvb8rn => 12 ],
	[ phvr8rn => 12 ],
	[ phvb8rn => 18 ],
);

=head1 NAME

Games::Baseball::Scorecard


=head1 SYNOPSIS

	my $score = Games::Baseball::Scorecard->new($dir, $name, {
		color  => [ .4, .4, .4 ], # grey
		fonts  => [ # Myriad Condensed regular/bold
			[ myriadrcrrl =>  9 ],
			[ myriadrcbrl => 14 ],
			[ myriadrcrrl => 14 ],
			[ myriadrcbrl => 22 ],
		],
	});

	# fill initial scorecard out
	$s->init({
		scorer	=> 'Pudge',
		date	=> '2004-10-24, 20:05-23:25',
		at	=> 'Fenway Park, Boston',
		temp	=> '48 clear',
		wind	=> '7 to RF',
		att	=> '35,001',
		home	=> {
			team	=> 'Boston Red Sox',
			starter	=> 38, # jersey number
			lineup	=> [
				# [ num, position ],
				[ 18, 8 ], # Damon, starting at CF
				# ...
			],
			roster	=> {
				# num => name
				18 => 'Damon, Johnny',
				38 => 'Schilling, Curt',
				# ...
			},
		},
		away	=> {
			team	=> 'St. Louis Cardinals',
			# ...
		}
	});

	# draw the game
	$s->inn; # new inning / end of last inning

		$s->ab; # new at-bat
			# works to full count
			$s->pitches(qw(s b s b b f));
			# struck out looking
			$s->out('!K');

		$s->ab;
			# home run to left-center
			$s->hit(4, 'lc');

	# calculate/draw stats
	$self->totals;

	# finish the job
	$s->generate;

	# open final PDF
	$s->pdfopen;


=head1 DESCRIPTION

Games::Baseball::Scorecard is a frontend to a PDF scorecard written in Metapost by
Christopher Swingley (L<http://www.frontier.iarc.uaf.edu/~cswingle/baseball/scorecards.php>).
That scorecard is drawn out, and has a nice API for actually drawing out the
elements of the game: all the ball, strikes, outs, etc.

Being Metapost, it is laborious to do all this.  So this module provides a nice
frontend, that also keeps track of balls and strikes and hits and runs and outs
and more, making input of the game quite simple and efficient.

This module does not include the entire API, but most of it.  Patches and ideas
welcome.  Feel free to call C<output> directly if you want to generate Metapost
on your own, or to modify the C<$SCORECARD> variable (which contains the base
Metapost code), or the C<$TEX> (single page) and C<$TEXD> (duplex) TeX files.

I won't give a tutorial on scoring baseball games, or on Metapost, below.  Seek
other resources (Swingley's URL above has a nice tutorial on scoring baseball
games, using the scorecard he designed, which is what we're using here).


=head1 SYSTEM REQUIREMENTS

You will need TeX and Metapost installed.  F<mpost>, F<mptopdf>, and F<pdftex>
must be in your C<$ENV{PATH}>.  For opening the PDF with C<pdfopen>, you will
need C<open> (Mac OS X) in your path.  The names of these programs can be modified
with the variables C<$MPOST>, C<$MPTOPDF>, C<$PDFTEX>, and C<$OPEN>.

Also, the font by default (in the C<$SCORECARD> variable) is Helvetica Narrow.
Use whatever fonts you have installed for TeX.  The original used Myriad
Condensed, which I don't have (getting a decent-looking font and size, and
figuring out how to use it, was the hardest part of the project for me -- as
I don't know TeX -- so I picked a font everyone else could use, that should
be installed by default in most TeX installations).

See the distribution at
L<http://www.frontier.iarc.uaf.edu/~cswingle/baseball/scorecards.php> for
more information.


=head1 METHODS

The main methods are included below.  There are some other methods that are used,
but you shouldn't need to call them so I won't list them all here.

=head2 Basic Methods

=over 4

=item new([DIR, BASE, OPTS])

The C<new> method takes three optional arguments: a directory to build in,
and a base name for the scorecard file, and an options hashref.  Defaults are
the current directory, and "scorecard".  The base name is used to generate the
build files and the resulting PDFs, which will be F<${base}_away.pdf>,
F<${base}_home.pdf>, and F<$base.pdf> (both away and home together).

Options can be "color", an arrayref of RGB values (0 to 1), and "fonts",
an arrayref of four fonts (copyright notice font, basepath play labels,
balls/strikes/outs/other labels, and outs and other large label), with
the font name and size (see L<SYNOPSIS>).

Defaults are black, and Helvetica Narrow (phvr8rn/phvr8rn).

=cut

sub new {
	my($ref, $dir, $base, $opts) = @_;
	$opts ||= {};
	$dir  ||= tempdir();
	$base ||= 'scorecard';
	$base =~ s/\W+//g;

	$dir = rel2abs($dir) unless file_name_is_absolute($dir);

	mkpath($dir) unless -e $dir;

	my $self = bless {
		debug	=> 0,
		dir	=> $dir,
		base	=> $base,
	}, __PACKAGE__;

	for my $which (qw(away home)) {
		my $fh;
		my $basewhich = "${base}_$which";
		unless (open $fh, '>', catfile($dir, "$basewhich.tex")) {
			warn $!;
			return;
		}

		(my $tex = $TEX) =~ s/__BASE__/$basewhich/;
		print $fh $tex;
		close $fh;


		unless (open $fh, '>', catfile($dir, "$basewhich.mp")) {
			warn $!;
			return;
		}

		$opts->{fonts}[0] ||= $FONTS[0];
		$opts->{fonts}[1] ||= $FONTS[1];
		$opts->{fonts}[2] ||= $FONTS[2];
		$opts->{fonts}[3] ||= $FONTS[3];

		$opts->{color}[0] = $COLOR[0] unless defined $opts->{color}[0];
		$opts->{color}[1] = $COLOR[1] unless defined $opts->{color}[1];
		$opts->{color}[2] = $COLOR[2] unless defined $opts->{color}[2];

		my $mp = $SCORECARD;
		$mp =~ s/__FONTFACE0__/$opts->{fonts}[0][0]/g;
		$mp =~ s/__FONTFACE1__/$opts->{fonts}[1][0]/g;
		$mp =~ s/__FONTFACE2__/$opts->{fonts}[2][0]/g;
		$mp =~ s/__FONTFACE3__/$opts->{fonts}[3][0]/g;

		$mp =~ s/__FONTSIZE0__/$opts->{fonts}[0][1]/g;
		$mp =~ s/__FONTSIZE1__/$opts->{fonts}[1][1]/g;
		$mp =~ s/__FONTSIZE2__/$opts->{fonts}[2][1]/g;
		$mp =~ s/__FONTSIZE3__/$opts->{fonts}[3][1]/g;

		$mp =~ s/__COLOR1__/$opts->{color}[0]/g;
		$mp =~ s/__COLOR2__/$opts->{color}[1]/g;
		$mp =~ s/__COLOR3__/$opts->{color}[2]/g;

		print $fh $mp;

		$self->{$which} = {
			which	=> $which,
			base	=> $basewhich,
			fh	=> $fh,
			ab	=> 0,
			inn	=> 0,
		};
	}

	my $fhd;
	unless (open $fhd, '>', catfile($dir, "$base.tex")) {
		warn $!;
		return;
	}

	my $texd = $TEXD;
	$texd =~ s/__BASE1__/$self->{away}{base}/;
	$texd =~ s/__BASE2__/$self->{home}{base}/;
	print $fhd $texd;
	close $fhd;

	for (qw(home away)) {
		$self->home_away($_);
		$self->begin;
		$self->top if /away/;
		$self->bottom if /home/;
	}

	return $self;
}


=item debug([LEVEL])

Set debug level.  0 is off, 1 shows the commands being executed, 2 shows all
output.

=cut

sub debug {
	my($self, $level) = @_;

	$self->{debug} = $level if defined $level;
	return $self->{debug};
}

sub death {
	my($self, $err) = @_;
	printf STDERR "die: $err\nInning: $self->{curr}{inn}, order: $self->{curr}{ab}\n";
	exit;
}


=item init(DATA)

The <init> method accepts a single hashref that has all the data needed to
generate the initial scorecard.  You can some of the methods directly on your
own, but you really don't want to.

The hashref contains various root-level string keys: C<date>, C<temp>, C<wind>,
C<at>, C<att>, C<scorer>.  Each takes a simple string.

It also takes two hashref keys, C<away> and C<home>.  Each works the same way.
The C<team> key takes the team name, the C<starter> key takes the jersey number
of the starter, the C<roster> key takes a hashref of jersey number/name for
the entire active roster.

The C<lineup> key takes an arrayref -- in order -- of each starter, with each
element as an arrayref of [ jersey number, position ].

The position is standard baseball position numbering: 1 P, 2 C,
3 1B, 4 2B, 5 3B, 6 SS, 7 LF, 8 CF, 9 RF.  I use 0 for DH.

Players are thus referenced by their jersey number, when making them the
starter, putting them in the starting lineup, or when adding a new player
or pitcher.

The C<lefties> key is optional; if present, it is used to determine which
pitchers are lefties.  It takes a simple arrayref listing the jersey numbers
of the southpaws on the roster.

If not using this module to generate the entire game, but just the initial
scorecard, then the roster needs only include the players in the starting lineup.

=cut

sub init {
	my($self, $data) = @_;

	for my $which (qw(away home)) {
		$self->home_away($which);

		$self->team  ( $data->{$which}{team} );
		$self->date  ( $data->{date}         );
		$self->temp  ( $data->{temp}         );

		$self->at    ( $data->{at}           );
		$self->att   ( $data->{att}          );
		$self->scorer( $data->{scorer}       );
		$self->wind  ( $data->{wind}         );

		my $roster = $self->{curr}{roster} = $data->{$which}{roster};
		$self->{curr}{lefties} = $data->{$which}{lefties};

		my $order = 0;
		for (@{$data->{$which}{lineup}}) {
			$self->add_player(++$order, $_->[0], $_->[1]);
		}
	}

	$self->home_away('away');
	$self->add_pitcher($data->{home}{starter}) if $data->{home}{starter};

	$self->home_away('home');
	$self->add_pitcher($data->{away}{starter}) if $data->{away}{starter};
}


=item generate

The C<generate> method takes the Metapost code and generates the PDFs.
Call this last, after everything has been done to the scorecard.

Calls C<close> for you.

Returns the path to the PDF file.

=cut

sub generate {
	my($self) = @_;
	$self->close;

	for (qw(away home)) {
		my $base = $self->{$_}{base};

		$self->_run($MPOST,   "$base.mp");
		$self->_run($MPTOPDF, "$base.0");
		$self->_run($PDFTEX,  "$base.tex");
	}

	$self->_run($PDFTEX, "$self->{base}.tex");

	return catfile($self->{dir}, "$self->{base}.pdf");
}

sub _run {
	my($self, $command, $file, $abs) = @_;

	unless (chdir $self->{dir}) {
		die "Can't chdir $self->{dir}: $!";
	}

	my $path = $abs ? $file : catfile($self->{dir}, $file);
	print "==> " if $self->{debug} > 1;
	print "$command $path\n" if $self->{debug};
	local $/;
	my $output = `$command $path`;

	if ($self->{debug} > 1) {
		print "<== $output" if $output;
		print "\n", ("-" x 73), "\n\n";
	}

	return $output;
}


=item close

The C<close> method finishes up the Metapost file, and closes it for you.

Do not call this method if you also call C<generate>, as that method calls
this one.  Only call this method if you do not wish to generate the PDF files,
but only want to write out the Metapost file.

=cut

sub close {
	my($self) = @_;

	for (qw(away home)) {
		$self->home_away($_);
		if ($self->{curr}{fh}) {
			$self->end;
			$self->output("\nend\n");

			close $self->{curr}{fh};
			delete $self->{curr}{fh};
		}
	}
}


=item pdfopen([FILE])

Opens the PDF (or filename provided) using the program specified in
C<$OPEN> (default 'open', used by Mac OS X to open the document in the default
PDF viewer).

=cut

sub pdfopen {
	my($self, $file) = @_;
	my $abs = 1;
	if (!$file) {
		$abs  = 0;
		$file = "$self->{base}.pdf";
	}

	$self->_run($OPEN, $file, $abs) if $OPEN;
}


=item home_away([WHICH])

Switch which team is home, and which is away.  If WHICH then set specifically.

=cut

sub home_away {
	my($self, $which) = @_;

	if ($which) {
		$self->{curr}  = $self->{$which};
		$self->{other} = $self->{
			$which eq 'home' ? 'away' : 'home'
		};
	} else {
		($self->{curr}, $self->{other}) = ($self->{other}, $self->{curr});
	}
}


=back

=head2 Scoring Methods

These are the methods for scoring an actual game.

=head3 Setup Methods

=over 4

=item inn

Call C<inn> to start a new half-inning, and to finish the final inning.  It
generates the inning stats.

B<Note>: if you go to more than 11 innings, things will break.
See L<LIMITATIONS>.

=cut

sub inn {
	my($self) = @_;

	$self->output("\n\n    % inning end\n");

	my $stats = $self->{curr}{stats}{inning};
	if ($stats) {
		$self->output(_label(_btex($stats->{r}  ||= 0),   '1/2[(xstart,-150),(xstart+50u,-100+400)]'));
		$self->output(_label(_btex($stats->{h}  ||= 0),   '1/2[(xstart+50u,-150),(xstart+100u,-100+400)]'));
		$self->output(_label(_btex($stats->{e}  ||= 0),   '1/2[(xstart,-200),(xstart+50u,-150+400)]'));
		$self->output(_label(_btex($stats->{lb} ||= 0),   '1/2[(xstart+50u,-200),(xstart+100u,-150+400)]'));
		$self->output(_label(_btex($stats->{bb} ||= 0),   '1/2[(xstart,-250),(xstart+50u,-200+400)]'));
		$self->output(_label(_btex($stats->{k}  ||= 0),   '1/2[(xstart+50u,-250),(xstart+100u,-200+400)]'));
		$self->output(_label(_btex($stats->{strikes}||0), '1/2[(xstart,-300),(xstart+50u,-250+400)]'));
		$self->output(_label(_btex($stats->{pitches}||0), '1/2[(xstart+50u,-300),(xstart+100u,-250+400)]'));

		$self->output("    draw_inning_end(xstart,ystart,clr);\n\n");
	}

	$self->output("\n\n    % inning start\n");

	$self->home_away;

	my $inn = $self->{curr}{inn} += 1;
	$self->{_inn_new} = 1 unless $self->{curr}{inn} == 1;
	$self->{out} = [];
	$self->{bases} = [];
	$self->{curr}{stats}{inning} = $self->{curr}{stats}{innings}{$inn} ||= {};

	my $xstart = $self->{curr}{inn} * 100;
	$self->{curr}{xstart} = $xstart;
	$self->output("    xstart := $xstart;\n");
}


=item ab

Call C<ab> to start a new at-bat.  B<Note>: call C<add_pitcher> and C<add_player>
I<before> calling C<ab>.

B<Note>: if you have more than 9 batters in an inning, things will break.
See L<LIMITATIONS>.

=cut

sub ab {
	my($self) = @_;

	$self->{curr}{ab} += 1;
	$self->{curr}{ab} = 1 if $self->{curr}{ab} > 9;
	$self->{pc} = 0;

	$self->{curr}{stats}{pitcher}{bf}++;

	$self->{curr}{stats}{batter} = $self->{curr}{stats}{batters}{
		$self->{curr}{lineup}[$self->{curr}{ab}][-1][0]
	} ||= {};

	my $ystart = 1000 - $self->{curr}{ab} * 100;

	$self->output("\n\n    % inning $self->{curr}{inn}, batter $self->{curr}{ab}\n");
	$self->output("    ystart := $ystart;\n");
	$self->output("    clr := (0,0,0);\n");
	$self->output("    set_vars(xstart,ystart);\n");
#	$self->output("    draw_square(xstart,ystart);\n");
	$self->output("    draw_inning_start(xstart,ystart,clr);\n")
		if delete $self->{_inn_new};

	if ($self->{curr}{lineupnew}[ $self->{curr}{ab} ]) {
		$self->{curr}{lineupnew}[ $self->{curr}{ab} ] = 0;
		$self->output("    draw(new_hitter) withcolor clr;\n");
	}

	if (delete $self->{curr}{pitchernew}) {
		$self->output("    draw(new_pitcher) withcolor clr;\n");
	}
}


=item add_player(ORDER, NUMBER, POS [, INN])

This adds a new player -- with the given jersey number and position -- in the
given place in the batting order.  If you are scoring an actual game, call
this only at the point the player enters the game.  The inning will be figured
out automatically then.

The player will be added to the lineup list on the left of the card, and
stats for that lineup position will be added to that player (instead of the
previous one) from that moment on, and a line will be drawn on the sheet for
where that player entered.

Call this before you call C<ab> (unless the player enters as a pinch runner).

B<Note>: if you add more than three batters for a given position, the overflow
will go to one of the six spots below the nine lineup positions.  No stats
will be printed for them.  More than six of those, and the names will not be
printed either.

=cut

sub add_player {
	my($self, $order, $number, $pos, $inn) = @_;
	$inn ||= $self->{curr}{inn} || 1;

	my $lineup  = $self->{curr}{lineup}  ||= [];
	my $lineupx = $self->{curr}{lineupx} ||= {};
	my $name = $self->{curr}{roster}{$number};

	my $rep = '';
	my $rep2;
	my $xtra = 0;
	if ($lineup->[$order]) {
		$rep2 = 1 + @{$lineup->[$order]};
		if ($rep2 > 3) {
			$rep2 = 1 + keys %$lineupx;
			if ($rep2 > 6) {
				warn "Too many batters\n";
			}
			$xtra = 1;
		}
		$rep = "*$rep2";

		$self->{curr}{lineupnew}[$order] = 1;

		my $curr_batter = $self->{curr}{stats}{batters}{
			$lineup->[$order][-1][0]
		} ||= {};

		if ($self->{curr}{stats}{batter} &&
		    $self->{curr}{stats}{batter} eq $curr_batter
		) {
			$self->{curr}{stats}{batter} =
				$self->{curr}{stats}{batters}{$number} ||= {};
		}
	}

	push @{$lineup->[$order]}, [ $number, $pos, $inn ];
	$lineupx->{$number} = $order if $xtra;

	my $ystart = 1000 - ($xtra ? 10 : $order) * 100;
	my $x = '100-iposwidth';
	my $y = "$ystart+100u-100u/3$rep";
	my $dir = 'urt';

	if (!$rep2 || $rep2 <= 6) {
		if ($xtra) {
			my $name2 = "$name ($inn)";
			$self->output(_label(_btex($order, 'sf'), '-224u', "92u-(($rep2-1)*100u/3)"));
			$self->output(_label(_btex($name2),  "$x*2-namewidth", $y, $dir));
		} else {
			$self->output(_label(_btex($name),   "$x*2-namewidth", $y, $dir));
			$self->output(_label(_btex($inn),     $x,              $y, $dir));
		}
		$self->output(_label(_btex($number), "$x*3-namewidth", $y, $dir));
		$self->output(_label(_btex($pos),    "$x*2",           $y, $dir));
	}
}

=item add_pitcher(NUMBER, [, INN])

This adds a new pitcher -- with the given jersey number -- to the scorecard.
If you are scoring an actual game, call this only at the point the pitcher
enters the game.  The inning will be figured out automatically then.

The pitcher will be added to the lineup list on the left of the card, and
stats for pitching will be added to that pitcher (instead of the
previous one) from that moment on, and a line will be drawn on the sheet for
where that pitcher entered.

Call this before you call C<ab>.

B<Note>: if you add more than six pitchers, the module will die.
See L<LIMITATIONS>.

=cut

sub add_pitcher {
	my($self, $number, $inn) = @_;
	$inn ||= $self->{curr}{inn} || 1;

	$self->{curr}{pitcher} = $number;
	$self->{curr}{stats}{pitcher} = $self->{other}{stats}{pitchers}{$number} ||= {};

	my $lineup = $self->{other}{plineup} ||= [];
	my $name = $self->{other}{roster}{$number};

	my $rep = '';
	my $xstart = 100;
	if (@$lineup) {
		my $rep2 = 1 + @$lineup;
		if ($rep2 > 10) {
			die "fixme!";
		} elsif ($rep2 > 5) {
			$rep2 -= 5;
			$xstart = '905+100u*(2/3)';
		}
		$rep = "*$rep2";
		$self->{curr}{pitchernew} = 1;
	}

	push @$lineup, [ $number, $inn ];

	my $lr;
	if ($self->{other}{lefties}) {
		$lr = (grep { $_ == $number } @{$self->{other}{lefties}})
			? 'L'
			: 'R';
	}

	my $ystart = -200;
	my $x = "$xstart-iposwidth";
	my $y = "$ystart+100u-100u/3$rep-100u/3";
	my $dir = 'urt';

	$self->output(_label(_btex($name),   "$x*2-namewidth", $y, $dir));
	$self->output(_label(_btex($number), "$x*3-namewidth", $y, $dir));
	$self->output(_label(_btex($lr),     "$x*2+8",         $y, $dir)) if $lr;
	$self->output(_label(_btex($inn),     $x,              $y, $dir));
}

=back

=head3 At-Bat Methods

These methods will draw in the at-bat graphic for the current at-bat,
and will also keep track of stats for later drawing (per-inning stats,
per-batter stats, and game totals).

B<Note>: At-bats do not progress the way they would in a game.  You put in
all of the information for a given at-bat in that at-bat before moving on
to the next.  For example, if a runner reaches on a walk, and then is hit
home by a home run, you would mark the walk, then that the runner advanced home,
before moving on to the next at-bat.


=over 4

=item play_ball(TEXT[, TEAMS])

C<play_ball> is a convenience method for handling input as text instead of
method calls (internally, it converts the text to method calls).

The first token on each line is the method call, and the rest are arguments
to the method call.

Shorthands include 'p' for C<pitches>, 'bb' 'ibb' and 'hp' for C<reach()>
by BB/IBB/HBP, and '-E<gt>' for C<advance>.  Any other tokens that are not
method names are C<out('token')>.

Example:

	$s->inn;
	$s->ab;
		$s->pitches(qw(b s b s b));
		$s->out('!K');
	$s->ab;
		$s->pitches(qw(b b b));
		$s->reach('bb');
		$s->advance(2);
	$s->ab;
		$s->hit(1, 'l');

Is equivalent to:

	$s->play_ball(<<'EOT');
		inn
		ab
			p b s b s b
			!K
		ab
			p b b b
			bb
			-> 2
		ab
			hit 1 l
	
	EOT

Prefixing a method name with 'ha' will call C<home_away> for that method
(useful for adding new players, such as 'ha add_player 9 3 8' to add a
player #3 to center field in the ninth spot for the fielding team, as
doing it without 'ha' would make the change for the team at bat).

You can also put data for C<init> in the text, at the top.  Include any
of the "root-level" strings, e.g.:

	scorer  Pudge
	date    2004-10-24, 20:05-23:25

After those, add the string 'away' or 'home', with the team name following;
then 'starter' with the starer's number; then the string 'lineup' followed by
the lineup data:

	away	Boston Red Sox
	starter	32
	lineup
		18 8
		44 6
		24 7

Then put the other string ('home'), followed by the data for that team.  To
complete the data, pass in a hashref with the team name (exactly the same
as included following the string 'home' or 'away') as the key to a hashref,
and the 'roster' / 'lefties' keys filled out (just as in C<init>).

See the F<example3.plx> script and F<example3.txt> files for an example.

=cut

sub play_ball {
	my($self, $game, $data) = @_;

	my @lines =	grep { $_ }
			map  { s/^\s+//s; s/\s+$//s; $_ }
			grep { !/^\s*#/ }
			split /\n/, $game;

	if ($game =~ /\n__INIT__\n/) {
		my %init;

		while (my $l = shift @lines) {
			last if $l =~ /^__INIT__$/;

			my @w = split /\s+/, $l, 2;
			if ($w[0] =~ /^(?:date|temp|at|att|scorer|wind)$/) {
				$init{$w[0]} = $w[1];

			} elsif ($w[0] =~ /^(home|away)$/) {
				my $team = $init{$1} ||= $data->{teams}{$w[1]};
				$team->{team} = $w[1];

				TEAM: while (my $l2 = shift @lines) {
					my @w2 = split /\t/, $l2;
					if ($w2[0] eq 'starter') {
						$team->{starter} = $w2[1];

					} elsif ($w2[0] eq 'lineup') {
						while (my $l3 = shift @lines) {
							my @w3 = split /\s+/, $l3;
							if ($w3[0] !~ /^\d/) {
								unshift @lines, $l3;
								last TEAM;
							}
							push @{$team->{lineup}}, [$w3[0], $w3[1]];
						}
					}
				}
			}

		}

		$self->init(\%init);
	}

	while (my $l = shift @lines) {
		last if $l =~ /^__GAME__$/;
		my @w = quotewords('\s+', 0, $l);
		my $m = shift @w;

		my $ha;
		if ($m eq 'ha') {
			$ha = 1;
			$m = shift @w;
			$self->home_away;
		}

		next unless $m;

		$m = 'tout' if $m eq 'to';
		$m = 'reach' if $m eq 'r';
		$m = 'advance' if $m eq '->';
		$m = 'pitches' if $m eq 'p';
		if ($m eq 'pitches') {
			 @w = map { split // } @w;
		}

		if ($m =~ /^(i?bb|hp|fc)$/i) {
			unshift @w, $m;
			$m = 'reach';
		}

		unless ($self->can($m)) {
			$m =~ s/^(\D+)/\U$1/;
			unshift @w, $m;
			$m = 'out';
		}

		$self->$m(@w);
		$self->home_away if $ha;
	}
}



=item pitches(PITCHES)

C<pitches> records the individual pitches of the at-bat (except for the one
that generates an out or puts the ball in play).  It takes a list of strings,
each string representing a pitch.  Each pitch can be one of C<s>, C<b>, or C<f>.

This puts the pitch markers in the at-bat graphic, and also increments counts
for the stat drawing later.

=cut

sub pitches {
	my($self, @pitches) = @_;
	my($s, $b, $f) = (0, 0, 0);

	for (@pitches) {
		if (/s/i || (/f/i && $s < 2)) {
			$self->strike(++$s);
		} elsif (/f/i) {
			$self->foul(++$f);
		} elsif (/b/i) {
			$self->ball(++$b);
		}
	}
}

sub ball {
	my($self, $num) = @_;
	my $pc = $self->pc;

	$self->death("Ball $num?") if $num > 3;

	$self->output(_label(_btex($pc, 'sf'), 'ball'   . _num($num)));
}

sub strike {
	my($self, $num) = @_;
	my $pc = $self->pc(1);

	$self->death("Strike $num?") if $num > 2;

	$self->output(_label(_btex($pc, 'sf'), 'strike' . _num($num)));
}

sub foul {
	my($self, $num) = @_;
	my $pc = $self->pc(1);

	$self->output(_label(_btex('x', 'sf'), 'foul'   . _num($num)))
		unless $num > 4;
}

sub pc {
	my($self, $strike) = @_;

	my $pitcher = $self->{curr}{stats}{pitcher} ||= {};
	my $inning  = $self->{curr}{stats}{inning}  ||= {};

	for ($pitcher, $inning) {
		$_->{pitches}++;
		$_->{strikes}++ if $strike;
	}

	return ++$self->{pc};
}

=item hit(BASES [, WHERE, LABEL])

C<hit> denotes a hit of BASES bases, to WHERE.

WHERE is an optional string, for where the ball left the park or where the
fielder recovered it, with these options:

	infield:
		il	left
		ic	center
		ir	right

	outfield:
		l	left
		lc	left center
		cl	center left
		cr	center right
		rc	right center
		r	right

LABEL is an optional label to put on the way to first base.

=cut

sub hit {
	my($self, $bases, $where, $label) = @_;
	$where ||= '';

	if ($bases eq 'U') {
		$self->rbi;
		$bases = 4;
	} elsif ($bases == 4) {
		$self->rbi;
		$self->er;
	}

	$self->reach($bases, $bases);

	$self->{curr}{stats}{batter}{h}++;
	$self->{curr}{stats}{batter}{$bases}++;
	$self->{curr}{stats}{inning}{h}++;
	$self->{curr}{stats}{game}{$bases}++;
	$self->{curr}{stats}{pitcher}{h}++;
	$self->{curr}{stats}{pitcher}{$bases}++;

	my $foo = $bases == 4 ? 'hr' : 'of';
	my $loc = lc $where eq 'il' ? 'ifleft' :
		  lc $where eq 'ic' ? 'ifcenter' :
		  lc $where eq 'ir' ? 'ifright' :

		  lc $where eq 'l'  ? "${foo}left" :
		  lc $where eq 'lc' ? "${foo}leftc" :
		  lc $where eq 'cl' ? "${foo}centerl" :
		  lc $where eq 'cr' ? "${foo}centerr" :
		  lc $where eq 'rc' ? "${foo}rightc" :
		  lc $where eq 'r'  ? "${foo}right" :
		                      '';

	$self->output("    draw($loc) withcolor clr;\n") if $loc;
	$self->output(_label(_btex($label, 'sf'), 'wayfirst', '', 'lrt')) if $label;

}

=item reach(LABEL [, BASES])

C<reach> denotes reaching base by a method other than a hit.
LABEL is the method of reaching, and BASES is optional number
of bases reached (default is, of course, 1).

Special LABELs include 'bb', 'ibb', 'hp', 'K', 'SAC', and 'SF'.
'K' is special in that it is added to the stats totals; the others
are not included as at-bats; and 'bb', 'ibb', and 'hp' are counted as balls,
instead of strikes.

=cut

sub reach {
	my($self, $label, $bases) = @_;

	if ($label =~ /^i?bb$/i) {
		$self->{curr}{stats}{batter}{bb}++;
		$self->{curr}{stats}{inning}{bb}++;
		$self->{curr}{stats}{pitcher}{lc $label}++;
	} elsif ($label =~ /^hb?p/i) {
		$self->{curr}{stats}{game}{hp}++;
		$self->{curr}{stats}{pitcher}{hp}++;
	} elsif (uc $label eq 'K') {
		$self->{curr}{stats}{batter}{k}++;
		$self->{curr}{stats}{inning}{k}++;
		$self->{curr}{stats}{pitcher}{k}++;
	}

	$self->{curr}{stats}{inning}{lb}++;

	if ($label =~ /^(?:hb?p|i?bb)$/i) {
		$self->pc;
	} elsif ($label =~ /^(?:SAC|SF)/i) {
		$self->pc(1);
	} else {
		$self->{curr}{stats}{batter}{ab}++;
		$self->pc(1);
	}

	$bases ||= 1;
	$self->base($bases);
	$self->run if $bases == 4;

	$bases = $bases == 4 ? 'homerun' :
	         $bases == 3 ? 'triple' :
	         $bases == 2 ? 'double' :
	                       'single';

	my $circle = $label =~ /^i?bb$/i ? 'bb' :
	             $label =~ /^hb?p/i  ? 'hp' :
	                $label eq 4      ? 'hr' :
	                $label eq 3      ? 'threeb' :
	                $label eq 2      ? 'twob' :
	                $label eq 1      ? 'oneb' :
	                                   '';

	if (lc($label) eq 'ibb') {
		$self->output("    draw_ibb(bb, clr);\n");
	} elsif ($circle) {
		$self->output("    draw_circle($circle, clr);\n");
	} elsif ($label) {
		$self->output(_label(_btex($label, 'sf'), 'wayfirst', '', 'lrt'));
	}
	$self->output("    draw($bases) withcolor clr;\n");
}

sub base {
	my($self, $base) = @_;

	my $runner = $self->{curr}{ab};
	my $bases  = $self->{bases};

	if ($base) {
		$bases->[$runner] = $base;
	}
	return $bases->[$runner];

}


=item out(LABEL)

C<out> records that the at-bat resulted in an out.  LABEL is the way in
which the out was recorded, e.g., F8, 4-3, SF7, SAC4-3, DP6-4-3, K, and so on.

SF and SAC outs will not be recorded as official at-bats.  The string
'!K' is used to denote a strikeout looking.

If you use SF, SAC, DP, K, and !K, then the stats for those can be properly
tabulated at the end.

=cut

sub out {
	my($self, $label) = @_;

	if ($label =~ /^!?K/i) {
		$self->{curr}{stats}{pitcher}{k}++;
		$self->{curr}{stats}{batter}{k}++;
		$self->{curr}{stats}{inning}{k}++;
		$self->{curr}{stats}{batter}{ab}++;
	} elsif ($label =~ /^SAC/i) {
		$self->{curr}{stats}{game}{sac}++;
	} elsif ($label =~ /^SF/i) {
		$self->{curr}{stats}{game}{sf}++;
	} elsif ($label =~ /^DP/i) {
		$self->{curr}{stats}{game}{dp}++;
		$self->{curr}{stats}{batter}{ab}++;
	} else {
		$self->{curr}{stats}{batter}{ab}++;
	}

	if (uc $label eq '!K') {
		$self->output("    draw_strikeout_looking(outlabel, clr);\n");
	} elsif ($label) {
		$self->output(_label(_btex($label), 'outlabel'));
	}

	$self->pc(1);
	$self->_out;
}

sub _out {
	my($self, $num, $pitcher) = @_;
	unless ($num) {
		for (1..3) {
			$num = $_, last if !$self->{out}[$_];
		}
	}

	$self->death('No out number?') unless $num;

	$self->{out}[$num] = 1;
	$self->{curr}{stats}{game}{outs}++;

	if ($pitcher) {
		$self->{other}{stats}{pitchers}{$pitcher}{outs}++;
	} else {
		$self->{curr}{stats}{pitcher}{outs}++;
	}

	my $out = _num($num);
	$self->output("    draw_out_$out(xstart,ystart,clr);\n");
}


=item tout(BASE, LABEL [, NUM, PITCHER])

C<tout> records that the runner was thrown out at BASE.
LABEL is the way in which the out was recorded, e.g., CS2-6, FC, DP.

PITCHER is the number of the pitcher who gets the out (for IP) if not the
one that pitched to that batter.

It is not necessary to include the base the runner is coming from; that is
remembered for you.

NUM is used in case the out is not in sequential order: e.g., if a batter
walks, then the next batter strikes out, then the first batter is caught stealing,
without NUM set to 2, the code would guess that it is the first out, since the
at-bat is earlier.  By setting NUM to 2 for the throwout, the strikeout will
be set to out 1, and the next out after that will be out 3.

If you use CS for LABEL, then the stats for that can be properly tabulated at
the end.

=cut

sub tout {
	my($self, $base2, $label, $num, $pitcher) = @_;

	my $base1 = $self->base || 0;

	$self->_out($num, $pitcher);
	$self->{curr}{stats}{inning}{lb}--;
	$self->{curr}{stats}{game}{cs}++ if $label =~ /^CS/i;

	$self->waybase($label, $base2);

	my $to = $base2 == 4 ? 'to_' : 'cs_';
	my $base = $base2 > $base1+1
		? _base($base1) . _base($base2)
		: _base($base2);

	$self->output("    draw($to$base);\n");
}


=item advance(BASE [, LABEL])

C<advance> advances a runner to BASE.  LABEL is the optional way in which
the runner advanced, e.g., SB.

If you advance home (4), a run is recorded for that runner, and is marked as
earned for the pitcher.  To advance home for an unearned run, use 'U' instead
of '4'.


and EARNED is true, the run is earned.

It is not necessary to include the base the runner is coming from; that is
remembered for you.

If you use SB, then the stats for that can be properly tabulated at the end.

=cut

sub advance {
	my($self, $base2, $label) = @_;

	my $unearned;
	if (uc $base2 eq 'U') {
		$unearned = 1;
		$base2 = 4;
	}

	my $base1 = $self->base;
	$self->waybase($label, $base1+1) if $label;
	$self->base($base2);
	$self->run if $base2 == 4;
	$self->er if $base2 == 4 && !$unearned;

	if ($label && $label =~ /^SB/i) {
		$self->{curr}{stats}{batter}{sb}++;
		$self->{curr}{stats}{game}{sb}++;
	}

	for ($base1, $base2) {
		$_ = _base($_);
	}

	$self->output("    draw($base1$base2);\n");
}


=back

=head3 At-Bat Stat Methods

These methods add additional stats (and in some cases, graphics) that are
not easily decipherable from the other at-bat events, so we need them
explicitly.

=over 4

=item rbi([RBIS])

Add RBI number of RBIs to current batter's totals (default is 1).
Don't include RBIs added by a hit(4), as that is added automatically.

=cut

sub rbi {
	my($self, $rbis) = @_;
	$rbis ||= 1;
	$self->{curr}{stats}{batter}{rbi} += $rbis;
	for (1 .. $rbis) {
		my $rbi = 'rbi' . _num($_);
		$self->output("    draw_dot($rbi, clr);\n");
	}
}

# called automatically when runner advances home

sub run {
	my($self) = @_;

	$self->{curr}{stats}{pitcher}{r}++;
	$self->{curr}{stats}{batter}{r}++;
	$self->{curr}{stats}{inning}{r}++;
	$self->{curr}{stats}{inning}{lb}--;

	$self->output("    draw_dot(rundot, clr);\n");
}

sub er {
	my($self) = @_;
	$self->{curr}{stats}{pitcher}{er}++;
	$self->{curr}{stats}{inning}{er}++;
}



=item error(POSITION)

Notes that an error was committed by the player at POSITION.
(Keeping track of error by POSITION not yet implemented, but feel free to
include it anyway, for when it is implemented.)

=cut

sub error {
	my($self, $pos) = @_;
# XXX not implemented
#	$self->{other}{stats}{$POSITION}{pb}++;
	$self->{curr}{stats}{inning}{e}++;
}


=item balk

Notes that there was a balk.

=cut

sub balk {
	my($self) = @_;
	$self->{curr}{stats}{pitcher}{bk}++;
}


=item wp

Notes that there was a wild pitch.

=cut

sub wp {
	my($self) = @_;
	$self->{curr}{stats}{pitcher}{wp}++;
	$self->{curr}{stats}{game}{wp}++;
}


=item pb

Notes that there was a passed ball.

=cut

sub pb {
	my($self) = @_;
# XXX not implemented
#	$self->{other}{stats}{2}{pb}++;
	$self->{curr}{stats}{game}{pb}++;
}


=item dp

Notes that a double play was executed.  Do not use if the batter was out by
double play, but only if there was a double play in which the batter was safe,
as calling C<out('DP6-4-3')> already records the double play for you.

=cut

sub dp {
	my($self) = @_;
	$self->{curr}{stats}{game}{dp}++;
}


=back

=head3 At-Bat Label Methods

These methods are simply for adding additional labels in the at-bat graphic,
for whatever you wish.

=over 4

=item waybase(LABEL [, BASE, BIG])

Add label LABEL on the way to BASE.  If BASE is excluded, notes it on way
to the next base after the one the runner is currently at.

=cut

sub waybase {
	my($self, $label, $base, $big) = @_;

	my $size = $big ? 'bigsf' : 'sf';
	$base ||= $self->base + 1;

	my $dir = $base == 4 ? 'lft' :
	          $base == 3 ? 'ulft' :
	          $base == 2 ? 'urt' :
	                       'lrt';

	$self->output(_label(_btex($label, $size), 'way' . _base($base), '', $dir));
}

=item atbase(LABEL [, BASE, BIG])

Add label LABEL at BASE.  If BASE is excluded, notes it
at the base the runner is currently at.

=cut

sub atbase {
	my($self, $label, $base, $big) = @_;

	my $size = $big ? 'bigsf' : 'sf';
	$base ||= $self->base;

	my $dir = $base == 4 ? 'bot' :
	          $base == 3 ? 'lft' :
	          $base == 2 ? 'top' :
	                       'rt';

	$self->output(_label(_btex($label, $size), _base($base), '', $dir));
}


=back

=head2 Stat Totals Methods

=over 4

=item win(NUMBER)

=item loss(NUMBER)

=item save(NUMBER)

=item blown_save(NUMBER)

NUMBER is the jersey number of the pitcher who got the (win, loss, save, blown save).
Call these methods while the pitcher's team is still on the field (while
the opposing team is still at bat), any time before the totals are calculated.

=cut

sub win {
	my($self, $number) = @_;
	$self->{other}{stats}{pitchers}{$number}{record}{w} = 1;
}

sub loss {
	my($self, $number) = @_;
	$self->{other}{stats}{pitchers}{$number}{record}{l} = 1;
}

sub hold {
	my($self, $number) = @_;
	$self->{other}{stats}{pitchers}{$number}{record}{h} = 1;
}

sub save {
	my($self, $number) = @_;
	$self->{other}{stats}{pitchers}{$number}{record}{'s'} = 1;
}

sub blown_save {
	my($self, $number) = @_;
	$self->{other}{stats}{pitchers}{$number}{record}{bs} = 1;
}



=item totals

This generates the stat totals for the game, batters, and pitchers.  Call it after the
finall C<inn> method call, if you wish to generate the stat totals.

=cut

sub totals {
	my($self) = @_;

	return if $self->{_totals};

	for (qw(away home)) {
		$self->home_away($_);
		$self->_totals;
	}

	$self->{_totals} = 1;
}

sub _totals {
	my($self) = @_;

	my $game    = $self->{curr}{stats}{game};
	my $innings = $self->{curr}{stats}{innings};
	my(%tstats, %pstats);
	for my $n (qw(r h e lb bb k strikes pitches)) {
		$tstats{$n} += $innings->{$_}{$n} ||= 0 for keys %$innings;
	}

	$self->output("\n\n\n    %totals\n    nudge := 10u;\n");
	$self->output(_label(_btex($tstats{r}),       '1/2[(1200,-150+nudge),(1200+100u/3,-100+400)]'));
	$self->output(_label(_btex($tstats{h}),       '1/2[(1200+100u/3,-150),(1200+100u/3*2,-100+400-nudge)]'));
	$self->output(_label(_btex($tstats{e}),       '1/2[(1200,-200+nudge),(1200+100u/3,-150+400)]'));
	$self->output(_label(_btex($tstats{lb}),      '1/2[(1200+100u/3,-200),(1200+100u/3*2,-150+400-nudge)]'));
	$self->output(_label(_btex($tstats{bb}),      '1/2[(1200,-250+nudge),(1200+100u/3,-200+400)]'));
	$self->output(_label(_btex($tstats{k}),       '1/2[(1200+100u/3,-250),(1200+100u/3*2,-200+400-nudge)]'));
	$self->output(_label(_btex($tstats{strikes}), '1/2[(1200,-300+nudge),(1200+100u/3,-250+400)]'));
	$self->output(_label(_btex($tstats{pitches}), '1/2[(1200+100u/3,-300),(1200+100u/3*2,-250+400-nudge)]'));

	my $lineup = $self->{curr}{lineup};
	for my $i (0 .. $#$lineup) {
		next unless $lineup->[$i];

		for my $j (0 .. $#{$lineup->[$i]}) {
			my $bstats = $self->{curr}{stats}{batters}{$lineup->[$i][$j][0]};
			for (qw(ab r h rbi bb k)) {
				$pstats{$_} += $bstats->{$_} ||= 0;
			}
			next if $j > 2;

			my $rep = '';
			$rep = sprintf('*%d', 1+$j) if $j;

			my $ystart = 1000 - $i * 100;
			my $x = '1200+10';
			my $y = "$ystart+100u-100u/3$rep";
			my $dir = 'urt';

			$self->output(_label(_btex($bstats->{ab}),   $x,               $y, $dir));
			$self->output(_label(_btex($bstats->{r}),   "$x+(100u/3)",     $y, $dir));
			$self->output(_label(_btex($bstats->{h}),   "$x+((100u/3)*2)", $y, $dir));

			$self->output(_label(_btex($bstats->{rbi}), "$x+((100u/3)*3)", $y, $dir));
			$self->output(_label(_btex($bstats->{bb}),  "$x+((100u/3)*4)", $y, $dir));
			$self->output(_label(_btex($bstats->{k}),   "$x+((100u/3)*5)", $y, $dir));
		}
	}

	my $plineup = $self->{other}{plineup};
	for my $j (0 .. $#$plineup) {
		my $kstats = $self->{other}{stats}{pitchers}{$plineup->[$j][0]};

		my $rep = '';
		$rep = sprintf('*%d', ($j<5 ? $j+1 : $j-4)) if $j;

		my $ystart = -200;
		my $x = $j < 5 ? '100+5' : '900+5+100u*(2/3)';
		my $y = "$ystart+5+100u-100u/3$rep-100u/3";
		my $dir = 'urt';

		my $wls = uc join ',', grep $kstats->{record}{$_}, qw(w l h s bs);
		my $remainder  = ( ($kstats->{outs} ||= 0) % 3)  || 0;
		$kstats->{ip}  = ( ($kstats->{outs} - $remainder) / 3 ) . ".$remainder";

		$self->output(_label(_btex($wls),                   $x,                $y, $dir)) if $wls;
		$self->output(_label(_btex($kstats->{bf}||0),      "$x+(100u/3)",      $y, $dir));
		$self->output(_label(_btex($kstats->{ip}||0),      "$x+((100u/3)*2)",  $y, $dir));

		$self->output(_label(_btex($kstats->{h}||0),       "$x+((100u/3)*3)",  $y, $dir));
		$self->output(_label(_btex($kstats->{r}||0),       "$x+((100u/3)*4)",  $y, $dir));
		$self->output(_label(_btex($kstats->{er}||0),      "$x+((100u/3)*5)",  $y, $dir));

		$self->output(_label(_btex($kstats->{bb}||0),      "$x+((100u/3)*6)",  $y, $dir));
		$self->output(_label(_btex($kstats->{k}||0),       "$x+((100u/3)*7)",  $y, $dir));
		$self->output(_label(_btex($kstats->{ibb}||0),     "$x+((100u/3)*8)",  $y, $dir));

		$self->output(_label(_btex($kstats->{hp}||0),      "$x+((100u/3)*9)",  $y, $dir));
		$self->output(_label(_btex($kstats->{bk}||0),      "$x+((100u/3)*10)", $y, $dir));
		$self->output(_label(_btex($kstats->{wp}||0),      "$x+((100u/3)*11)", $y, $dir));

		$self->output(_label(_btex($kstats->{4}||0),       "$x+((100u/3)*12)", $y, $dir));
		$self->output(_label(_btex($kstats->{strikes}||0), "$x+((100u/3)*13)", $y, $dir));
		$self->output(_label(_btex($kstats->{pitches}||0), "$x+((100u/3)*14)", $y, $dir));
	}

	$self->output("    nudge := 5u;\n");

	my $xstart = '1200+100u/3*2+40u';
	my $ystart = '+25u+nudge';
	my $dir = 'urt';

	$self->output(_label(_btex($game->{1}||0, 'sf'),   $xstart, "-150+200$ystart", $dir));
	$self->output(_label(_btex($game->{2}||0, 'sf'),   $xstart, "-175+200$ystart", $dir));
	$self->output(_label(_btex($game->{3}||0, 'sf'),   $xstart, "-200+200$ystart", $dir));
	$self->output(_label(_btex($game->{4}||0, 'sf'),   $xstart, "-225+200$ystart", $dir));
	$self->output(_label(_btex($game->{sf}||0, 'sf'),  $xstart, "-250+200$ystart", $dir));
	$self->output(_label(_btex($game->{sac}||0, 'sf'), $xstart, "-275+200$ystart", $dir));

	$xstart = '1200+100u/3*2+150u';
	$self->output(_label(_btex($game->{dp}||0, 'sf'),  $xstart, "-150+200$ystart", $dir));
	$self->output(_label(_btex($game->{hp}||0, 'sf'),  $xstart, "-175+200$ystart", $dir));
	$self->output(_label(_btex($game->{wp}||0, 'sf'),  $xstart, "-200+200$ystart", $dir));
	$self->output(_label(_btex($game->{pb}||0, 'sf'),  $xstart, "-225+200$ystart", $dir));
	$self->output(_label(_btex($game->{sb}||0, 'sf'),  $xstart, "-250+200$ystart", $dir));
	$self->output(_label(_btex($game->{cs}||0, 'sf'),  $xstart, "-275+200$ystart", $dir));


	my @nums = map { $_ || 0 } ($pstats{ab}, $pstats{bb}, $game->{hp}, $game->{sac}, $game->{sf});
	my $numt = 0;
	$numt += $_ for @nums;
	my $nums = sprintf('%s~~=~~%s', join('+', @nums), $numt);
	$self->output(_label(_btex($nums, 'sf', 1), '1200+100u/3*2+110u', '-300+200+25u+nudge', $dir));

	@nums = map { $_ || 0 } ($tstats{r}, $tstats{lb}, $game->{outs});
	$numt = 0;
	$numt += $_ for @nums;
	$nums = sprintf('%s~~=~~%s', join('+', @nums), $numt);
	$self->output(_label(_btex($nums, 'sf', 1), '1200+100u/3*2+110u', '-300+200+nudge', $dir));
}



=back

=cut


#### misc output methods

sub output {
	my($self, @lines) = @_;
	my $fh = $self->{curr}{fh};
	print $fh @lines;
}

sub begin {
	my($self) = @_;
	$self->output("beginfig(0);\n");
	$self->output("    draw_full_scorecard;\n\n");
	$self->output("    clr:=scoring;\n\n");
}


sub end {
	my($self) = @_;
	$self->output("endfig;\n");
}

sub top {
	my($self) = @_;
	$self->output(_label(_btex('TOP'), 1431, 1020));
}

sub bottom {
	my($self) = @_;
	$self->output(_label(_btex('BOTTOM'), 1433, 1020));
}

#        label(btex {\bigsf Team}    etex rotated 90, (1416,130)) withcolor clr;
#        label(btex {\bigsf FP}      etex rotated 90, (1416,614)) withcolor clr;
#        label(btex {\bigsf Temp}    etex rotated 90, (1416,900)) withcolor clr;
#        label(btex {\bigsf At}      etex rotated 90, (1448,142)) withcolor clr;
#        label(btex {\bigsf Att}     etex rotated 90, (1448,450)) withcolor clr;
#        label(btex {\bigsf Scorer}  etex rotated 90, (1448,600)) withcolor clr;

#        label(btex {\bigsf Team:}   etex rotated 90, (1420,-50)) withcolor clr;
#        label(btex {\bigsf Date:}   etex rotated 90, (1420,600)) withcolor clr;
#        label(btex {\bigsf At:}     etex rotated 90, (1450,-50)) withcolor clr;
#        label(btex {\bigsf Scorer:} etex rotated 90, (1450,600)) withcolor clr;

sub team {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1416+13, 280, 'lft', 'rotated 90'))
		if $info;
}

sub date {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1416+13, 714, 'lft', 'rotated 90'))
		if $info;
}

sub temp {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1416+13, 940, 'lft', 'rotated 90'))
		if $info;
}

sub at {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1448+13, 292, 'lft', 'rotated 90'))
		if $info;
}

sub att {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1448+13, 500, 'lft', 'rotated 90'))
		if $info;
}

sub scorer {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1448+13, 700, 'lft', 'rotated 90'))
		if $info;
}

sub wind {
	my($self, $info) = @_;
	$self->output(_label(_btex($info), 1448+13, 940, 'lft', 'rotated 90'))
		if $info;
}


#### helper functions

sub _num {
	my($num) = @_;
	return $num == 4 ? 'four' :
	       $num == 3 ? 'three' :
	       $num == 2 ? 'two' :
	                   'one';
}

sub _base {
	my($num) = @_;
	return $num == 4 ? 'home' :
	       $num == 3 ? 'third' :
	       $num == 2 ? 'second' :
	                   'first';
}

sub _label {
	my($label, $x, $y, $direction, $extra) = @_;

	$direction ||= '';
	$direction &&= ".$direction";

	$extra ||= '';
	$extra &&= " $extra";

	my $xy = defined $y && length $y ? "($x,$y)" : $x;

	return "    label$direction($label$extra, $xy) withcolor clr;\n";
}

sub _btex {
	my($string, $font, $lit) = @_;
	$font ||= 'bigsf';
	if (!defined $string || !length $string) {
#		print join "|", caller(0), "\n";
		return;
	}

	unless ($lit) {
		$string =~ s/\\/--BACKSLASH--/g;
		$string =~ s/{/--LBRACE--/g;
		$string =~ s/}/--RBRACE--/g;

		$string =~ s/( [\#\$\%\&\_\{\}] )/\\$1/gx;
		$string =~ s/( [\^~]       )/\\$1\{\}/gx;

		$string =~ s/--BACKSLASH--/\$\\backslash\$/g;
		$string =~ s/--LBRACE--/\$\\lbrace\$/g;
		$string =~ s/--RBRACE--/\$\\rbrace\$/g;
	}

	return "btex {\\$font $string} etex";
}


$SCORECARD = <<'EOT';
%prologues:=2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright (C) 2005, Christopher Swingley
%
% Licensed under the terms of the GNU General Public License, Version 2
% available from http://www.gnu.org/copyleft/gpl.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The following Metapost program draws baseball scorecards as well as
% allows you to record plays on the same card.  It contains two figures.
% Figure 0 is a complete, unfilled scorecard that can be converted to PDF
% and printed.
%
% Figure 2 is an example, showing the Cardinals scoring from the game 
% where Mark McGwire broke Roger Maris' home run record.
%
% Figure 1 is the Cubs scoring from the same game
%
% A few variables can be set at the beginning of the card to adjust
% colors and line thicknesses and other parameters.  Also note that
% I am using Adobe's Myriad Condensed fonts for the scorecard, so
% you will need to modify the font names to suit your own preferences
% and fonts.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Manual for metapost:
%   $ texdoc mpman
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Locations for stuff:
%
%    ballone, balltwo, ballthree, strikeone, striketwo, foulone, foultwo,
%    foulthree, foulfour
%
%       These are the locations for writing in the pitch counts to each 
%       batter:
%           label(btex {\sf 1} etex, ballone) withcolor clr;
%           label(btex {\sf 2} etex, strikeone) withcolor clr;
%           
%    rbione, rbitwo, rbithree, rbifour, rundot, outlabel
%
%       These are the locations for RBI dots, run dots (in the middle 
%       of the diamond), and the out labels (which also go in the middle 
%       of the diamond):
%           draw_dot(rbione, clr);
%           draw_dot(rbitwo, clr);
%           draw_dot(rundot, clr);
%           label(btex {\bigsf 6-3} etex, outlabel) withcolor clr;
%
%    first, second, third, home
%
%       Locations of the bases.  Mostly used for building the paths, 
%       but also useful for pinch runners:
%           label.top(btex {\sf PR} etex, second) withcolor clr;
%
%    hr, threeb, twob, oneb, bb, hp
%
%       Locations for the hit / walk / HBP text on the right side of
%       the box.  Circled to indicate the result of the at bat:
%           draw_circle(twob, clr);
%
%    wayfirst, waysecond, waythird, wayhome
%
%       The half-way points between bases.  Used as part of the CS and 
%       TO paths, but also useful for labelling CS and TO plays:
%           label.lft(btex {\sf TO 7-2} etex, wayhome) withcolor clr;
%
% Paths available:
%    single, double, triple, homerun
%
%       Paths showing a runner's progress on the bases:
%           draw(double) withcolor clr;
%
%    firstsecond, firstthird, firsthome, secondthird, secondhome, 
%    thirdhome
%
%       Paths for runners along the bases:
%           draw(secondhome) withcolor clr;
%
%    ifleft, ifright, ifcenter, ofleft, ofleftc, ofcenterl, ofcenterr, 
%    ofrightc, ofright
%
%       Paths for various type of hits (infield, outfield):
%           draw(ofleftc) withcolor clr;
%
%    hrleft, hrleftc, hrcenterl, hrcenterr, hrrightc, hrright;
%
%       Paths for home runs:
%           draw(hrleftc) withcolor clr;
%
%    cs_second, cs_third, to_home,
%    cs_firstthird, to_firsthome, to_secondhome,
%
%       Paths for caught stealing and thrown out:
%           draw(cs_second) withcolor clr;
%
%    new_hitter, new_pitcher
%
%       Paths for new hitters (left side of box) and pitchers 
%       (top of box)
%           draw(new_hitter) withcolor clr;
%           draw(new_pitcher) withcolor clr;
%
% Fonts:
%
%   \tiny   - used for the Copyright line
%   \tnsf   - used for the basepath plays
%   \sf     - used for balls and strikes, outs, various labelling
%   \bigsf  - used for out labels
%
% Normal functions:
%
%   draw(path) withcolor clr;                       - stroke a path
%   label(btex {\sf 1} etex, pair) withcolor clr;   - label
%       directional suffixes: lft,rt,top,bot,ulft,urt,llft,lrt
%   label(btex {\sf (6 empty boxes)} etex,                  \
%       1/2[(xstart, ystart-25u),(xstart+100u,ystart-25u)]) \
%       withcolor clr;  - use this when the lineup turns over
%
% User functions:
%
%   
%   def set_vars(expr xstart, ystart) =
%
%       Used to initialize all the locations and paths for a new 
%       starting locations.  Needs to be called right after setting
%       xstart and ystart.  These should be multiples of 100u
%
%   def draw_square(expr xstart, ystart) =
%
%       Draws an at-bat box in cyan
%
%   def draw_out_[one|two|three](expr xstart, ystart, clr) =
%
%       Indicates the first (second or third) out with the out number
%       in a circle.
%
%   def draw_dot(expr loc, clr) =
%
%       Draws a 5pt dot at the location indicated.  Used for RBI's,
%       and runs scored
%
%   def draw_circle(expr centerpoint, clr) =
%
%       Draws a circle around a location.  Used to circle the plays
%       on the right of the at-bat box.
%
%   def draw_inning_end(expr xstart, ystart, clr) =
%
%       Draws the slash in the lower right that signals the end of
%       the inning.
%
%   def draw_inning_start(expr xstart, ystart, clr) =
%
%       Draws the slash in the upper left that signals the start of
%       the inning.
%
%   def draw_strikeout_looking(expr outlabel, clr) =
%
%       Draws a backwards K
%
%   def draw_ibb(expr bb, clr)=
%
%       Adds 'I' in front of BB and circles it for an intentional walk
%
% Consult the Makefile for the commands used to turn the code in  this 
% file into PDF, EPS or PNG files.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Wed Apr 20 07:58:23 AKDT 2005
%       * Reversed figures 1 and 2 so the scoring of the game is in
%           order
%       * Added more comments to the beginning of the file
%       * Christopher Swingley, cswingle@iarc.uaf.edu
%
%   Sat Apr 16 13:33:14 AKDT 2005
%       * scoring.mp Version 0.2
%       * Pulled out a bunch of variables
%       * Finished the full scorecard code
%       * Christopher Swingley, cswingle@iarc.uaf.edu
%
%   Thu Apr 14 14:37:29 AKDT 2005
%       * scoring.mp Version 0.1
%       * Initial release
%       * Christopher Swingley, cswingle@iarc.uaf.edu
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FONTS
verbatimtex \font\tiny  __FONTFACE0__ at __FONTSIZE0__pt etex
verbatimtex \font\sf    __FONTFACE1__ at __FONTSIZE1__pt etex
verbatimtex \font\tnsf  __FONTFACE2__ at __FONTSIZE2__pt etex
verbatimtex \font\bigsf __FONTFACE3__ at __FONTSIZE3__pt etex

% VARIABLES
color card;
color scoring;
% Cyan card - modify first number to control lightness 
% (0 - 1, dark - light):
% card:=(0.10,1,1);  % Darker
% card:=(0.25,1,1);  % Lighter
% Grey card:
% card:=(0.4,0.4,0.4);
% Black card:
% card:=(0.0,0.0,0.0);
card:=(__COLOR1__,__COLOR2__,__COLOR3__);
% Black scoring color
scoring:=(0,0,0);
% Diameter of circles (outs)
outcircle_d := 7;
% Size of dots (rbi, runs scored)
dotsize := 7pt;
% Diameter of play circles
playcircle_d := 9;
% Thickness of play lines
playline_t := 1.5pt;
% Thickness of thick card lines
thickline_t := 0.5pt;
% Thickness of thin card lines
thinline_t := 0.05pt;

def draw_square(expr xstart, ystart) =
    begingroup
        pickup pencircle scaled thickline_t;
        % Outer box
        draw (xstart,ystart)--(xstart,ystart+100u)--(xstart+100u,ystart+100u)--(xstart+100u,ystart)--cycle withcolor card;
        pickup pencircle scaled thinline_t;
        % Pitches
        pbsize := 15u;
        pbstart := 50u;
        draw (xstart+pbstart,ystart)--(xstart+pbstart,ystart+pbsize)--(xstart+pbstart+(1*pbsize),ystart+pbsize)--(xstart+pbstart+pbsize,ystart)--cycle withcolor card;
        pbstart := pbstart + pbsize;
        draw (xstart+pbstart,ystart)--(xstart+pbstart,ystart+pbsize)--(xstart+pbstart+(1*pbsize),ystart+pbsize)--(xstart+pbstart+pbsize,ystart)--cycle withcolor card;
        pbstart := pbstart + pbsize;
        draw (xstart+pbstart,ystart)--(xstart+pbstart,ystart+pbsize)--(xstart+pbstart+(1*pbsize),ystart+pbsize)--(xstart+pbstart+pbsize,ystart)--cycle withcolor card;
        pbstart := 50u;
        draw (xstart+pbstart,ystart+pbsize)--(xstart+pbstart,ystart+pbsize*2)--(xstart+pbstart+(1*pbsize),ystart+pbsize*2)--(xstart+pbstart+pbsize,ystart+pbsize)--cycle withcolor card;
        pbstart := pbstart + pbsize;
        draw (xstart+pbstart,ystart+pbsize)--(xstart+pbstart,ystart+pbsize*2)--(xstart+pbstart+(1*pbsize),ystart+pbsize*2)--(xstart+pbstart+pbsize,ystart+pbsize)--cycle withcolor card;
        % Diamond
        dsize := 24u;
        dxstart := xstart+40u;
        dystart := ystart+pbsize*1.7;
        ofactor := 1.5;
        draw (dxstart,dystart)--(dxstart+dsize,dystart+dsize)--(dxstart,dystart+dsize*2)--(dxstart-dsize,dystart+dsize)--cycle withcolor card;
        % Outfield
        draw (dxstart+dsize,dystart+dsize)--(dxstart+(dsize*ofactor),dystart+(dsize*ofactor))..(dxstart,dystart+(2*dsize*ofactor))..(dxstart-(dsize*ofactor),dystart+(dsize*ofactor))--(dxstart-dsize,dystart+dsize) withcolor card;
        % Labels
        lxstart := xstart+90u;
        lystart := ystart+92u;
        lsize := (lystart-ystart+(fsize/2)-pbsize)/6;
        label(btex {\tnsf HR} etex, (lxstart,lystart)) withcolor card;
        lystart := lystart - lsize;
        label(btex {\tnsf 3B} etex, (lxstart,lystart)) withcolor card;
        lystart := lystart - lsize;
        label(btex {\tnsf 2B} etex, (lxstart,lystart)) withcolor card;
        lystart := lystart - lsize;
        label(btex {\tnsf 1B} etex, (lxstart,lystart)) withcolor card;
        lystart := lystart - lsize;
        label(btex {\tnsf BB} etex, (lxstart,lystart)) withcolor card;
        lystart := lystart - lsize;
        label(btex {\tnsf HP} etex, (lxstart,lystart)) withcolor card;
        pickup pencircle scaled playline_t;
    endgroup
enddef;

def draw_out_one(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled playline_t;
        label(btex {\sf 1} etex, (xstart+25u, ystart+10u)) withcolor clr;
        draw (xstart+25u,ystart+10u-outcircle_d)..(xstart+25u+outcircle_d,ystart+10u)..
                (xstart+25u,ystart+10u+outcircle_d)..(xstart+25u-outcircle_d,ystart+10u)..cycle withcolor clr;
    endgroup
enddef;

def draw_out_two(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled playline_t;
        label(btex {\sf 2} etex, (xstart+25u, ystart+10u)) withcolor clr;
        draw (xstart+25u,ystart+10u-outcircle_d)..(xstart+25u+outcircle_d,ystart+10u)..
                (xstart+25u,ystart+10u+outcircle_d)..(xstart+25u-outcircle_d,ystart+10u)..cycle withcolor clr;
    endgroup
enddef;

def draw_out_three(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled playline_t;
        label(btex {\sf 3} etex, (xstart+25u, ystart+10u)) withcolor clr;
        draw (xstart+25u,ystart+10u-outcircle_d)..(xstart+25u+outcircle_d,ystart+10u)..
                (xstart+25u,ystart+10u+outcircle_d)..(xstart+25u-outcircle_d,ystart+10u)..cycle withcolor clr;
    endgroup
enddef;

def draw_dot(expr loc, clr) =
    begingroup
        pickup pencircle scaled dotsize;
        draw(loc) withcolor clr;
        pickup pencircle scaled playline_t;
    endgroup
enddef;

def draw_circle(expr centerpoint, clr) =
    begingroup
        pickup pencircle scaled playline_t;
        draw (centerpoint+(0,-playcircle_d))..(centerpoint+(playcircle_d,0))..(centerpoint+(0,playcircle_d))..
                (centerpoint+(-playcircle_d,0))..cycle withcolor clr;
    endgroup
enddef;

def draw_inning_end(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled playline_t;
        draw (xstart+95u,ystart-5u)--(xstart+105u,ystart+5u) withcolor clr;
    endgroup
enddef;

def draw_inning_start(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled playline_t;
        draw (xstart-5u,ystart+95u)--(xstart+5u,ystart+105u) withcolor (0,0,0);
    endgroup
enddef;

def draw_strikeout_looking(expr outlabel, clr) =
    begingroup
        label(btex {\bigsf K} etex, outlabel) reflectedabout (outlabel+(0,1u), outlabel+(0,-1u)) withcolor clr;
    endgroup
enddef;

def draw_ibb(expr bb, clr)=
    begingroup
        label(btex {\sf I} etex, bb+(-9u,0)) withcolor clr;
        draw (bb+(-3u,-playcircle_d))..(bb+(playcircle_d+3u,0))..(bb+(-3u,playcircle_d))..(bb+(-playcircle_d-6u,0))..cycle withcolor clr;
    endgroup
enddef;

def draw_player_box(expr xstart, ystart, clr, inncol) =
    % Intended to draw to the *left* of xstart, ystart
    begingroup
        iposwidth := 40u;
        namewidth := 250u;
        pickup pencircle scaled thickline_t;
        % Inning and Position box
        if inncol:
            draw (xstart,ystart)--(xstart-iposwidth*2u,ystart)--(xstart-iposwidth*2u,ystart+100u)--(xstart,ystart+100u)--cycle withcolor clr;
            draw (xstart-iposwidth,ystart)--(xstart-iposwidth,ystart+100u) withcolor clr;
        else:
            draw (xstart-iposwidth,ystart)--(xstart-iposwidth*2u,ystart)--(xstart-iposwidth*2u,ystart+100u)--(xstart-iposwidth,ystart+100u)--cycle withcolor clr;
        fi
        % Player name box
        draw (xstart-iposwidth*2,ystart)--(xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*2-namewidth,ystart+100u)--
                (xstart-iposwidth*2,ystart+100u)--cycle withcolor clr;
        % Number box
        draw (xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart+100u)--
                (xstart-iposwidth*2-namewidth,ystart+100u)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;
        % other player lines
        if inncol:
            draw (xstart,ystart+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3) withcolor clr;
            draw (xstart,ystart+100u/3+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3+100u/3) withcolor clr;
        else:
            draw (xstart-iposwidth,ystart+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3) withcolor clr;
            draw (xstart-iposwidth,ystart+100u/3+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3+100u/3) withcolor clr;
        fi
    endgroup
enddef;

def draw_pitcher_box(expr xstart, ystart, clr) =
    % Intended to draw to the *left* of xstart, ystart
    begingroup
        iposwidth := 40u;
        namewidth := 250u;
        pickup pencircle scaled thickline_t;
        % Inning and Position box
        draw (xstart,ystart)--(xstart-iposwidth*2u,ystart)--(xstart-iposwidth*2u,ystart+100u)--(xstart,ystart+100u)--cycle withcolor clr;
        draw (xstart-iposwidth,ystart)--(xstart-iposwidth,ystart+100u) withcolor clr;
        % Player name box
        draw (xstart-iposwidth*2,ystart)--(xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*2-namewidth,ystart+100u)--(xstart-iposwidth*2,ystart+100u)--cycle withcolor clr;
        % Number box
        draw (xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart+100u)--(xstart-iposwidth*2-namewidth,ystart+100u)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;
        % other player lines
        draw (xstart-iposwidth,ystart+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3) withcolor clr;
        draw (xstart-iposwidth,ystart+100u/3+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3+100u/3) withcolor clr;
    endgroup
enddef;

def draw_column_totals_key(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled thickline_t;
        draw (xstart,ystart)--(xstart,ystart+100u)--(xstart-iposwidth,ystart+100u)--(xstart-iposwidth,ystart)--cycle withcolor clr;
        draw (xstart,ystart+100u/2)--(xstart-iposwidth,ystart+100u/2)--(xstart,ystart+100u) withcolor clr;
        draw (xstart,ystart+100u/2)--(xstart-iposwidth,ystart) withcolor clr;
    endgroup
enddef;

def draw_totals_box(expr xstart, ystart, clr) =
    begingroup
        pickup pencircle scaled thickline_t;
        draw (xstart,ystart)--(xstart,ystart+50u)--(xstart+100u,ystart+50u)--(xstart+100u,ystart)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;
        draw 1/3[(xstart,ystart),(xstart+100u,ystart)]-- 2/3[(xstart,ystart+50u),(xstart+100u,ystart+50u)] withcolor clr;
    endgroup
enddef;

def draw_row_summary_box(expr xstart,ystart,clr) =
    begingroup
        pickup pencircle scaled thickline_t;
        draw (xstart,ystart)--(xstart,ystart+100u)--(xstart+100u,ystart+100u)--(xstart+100u,ystart)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;
        draw (xstart,ystart+100u/3)--(xstart+100u,ystart+100u/3) withcolor clr;
        draw (xstart,ystart+100u/3*2)--(xstart+100u,ystart+100u/3*2) withcolor clr;
        draw (xstart+100u/3,ystart)--(xstart+100u/3,ystart+100u) withcolor clr;
        draw (xstart+100u/3*2,ystart)--(xstart+100u/3*2,ystart+100u) withcolor clr;
    endgroup
enddef;

def draw_game_summary_box(expr xstart,ystart,clr) =
    begingroup
        pickup pencircle scaled thickline_t;
        draw (xstart,ystart)--(xstart,ystart+50u)--(xstart+100u/3*2,ystart+50u)--(xstart+100u/3*2,ystart)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;
        draw (xstart,ystart)--(xstart+100u/3*2,ystart+50u) withcolor clr;
    endgroup
enddef;

def draw_play_total_box(expr xstart,ystart,clr) =
    begingroup
        pickup pencircle scaled thickline_t;
        draw (xstart+100u/3*2,ystart)--(xstart+100u/3*2,ystart+50u)--(xstart+100u/3*2+200.3u,ystart+50u)--(xstart+100u/3*2+200.3u,ystart)--cycle withcolor clr;
        draw (xstart+100u/3*2,ystart+25u)--(xstart+100u/3*2+200u,ystart+25u) withcolor clr;
    endgroup
enddef;

def draw_pitcher_row(expr xstart,ystart,clr,leftish) =
    begingroup
        if leftish:
            iposwidth := 40u;
            namewidth := 250u;
        else:
            iposwidth := 100u/3;
            namewidth := 200u+100u*(2/3)+1u;
        fi
        pickup pencircle scaled thickline_t;
        % Inning and Position box
        draw (xstart,ystart)--(xstart-iposwidth*2u,ystart)--(xstart-iposwidth*2u,ystart+100u)--(xstart,ystart+100u)--cycle withcolor clr;
        draw (xstart-iposwidth,ystart)--(xstart-iposwidth,ystart+100u) withcolor clr;
        % Player name box
        draw (xstart-iposwidth*2,ystart)--(xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*2-namewidth,ystart+100u)--
                (xstart-iposwidth*2,ystart+100u)--cycle withcolor clr;
        % Number box
        draw (xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart+100u)--
                (xstart-iposwidth*2-namewidth,ystart+100u)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;
        % other player lines
        draw (xstart,ystart+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3) withcolor clr;
        draw (xstart,ystart+100u/3+100u/3)--(xstart-iposwidth*3-namewidth,ystart+100u/3+100u/3) withcolor clr;
        % Now draw stats boxes
        for nxstart := xstart step 100 until xstart+400:
            draw_row_summary_box(nxstart,ystart,clr);
        endfor
    endgroup
enddef;

def draw_pitcher_labels(expr xstart,ystart,clr,leftish) =
    begingroup
        if leftish:
            iposwidth := 40u;
            namewidth := 250u;
        else:
            iposwidth := 100u/3;
            namewidth := 200u+100u*(2/3);
        fi
        statboxwidth := 100u/3;
        label(btex {\bigsf \#} etex, 1/2[(xstart-iposwidth*2-namewidth,ystart),(xstart-iposwidth*3-namewidth,ystart-(100u/3))]) withcolor clr;
        label(btex {\bigsf Pitcher} etex, 1/2[(xstart-iposwidth*2,ystart),(xstart-iposwidth*2-namewidth,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf L/R} etex, 1/2[(xstart-iposwidth,ystart),(xstart-iposwidth*2,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf Inn} etex, 1/2[(xstart,ystart),(xstart-iposwidth,ystart-100u/3)]) withcolor clr;
        %
        label(btex {\bigsf WLS} etex, 1/2[(xstart+statboxwidth,ystart),(xstart,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf BF} etex, 1/2[(xstart+statboxwidth*2,ystart),(xstart+statboxwidth,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf IP} etex, 1/2[(xstart+statboxwidth*3,ystart),(xstart+statboxwidth*2,ystart-100u/3)]) withcolor clr;
        %
        label(btex {\bigsf H} etex, 1/2[(xstart+statboxwidth*4,ystart),(xstart+statboxwidth*3,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf R} etex, 1/2[(xstart+statboxwidth*5,ystart),(xstart+statboxwidth*4,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf ER} etex, 1/2[(xstart+statboxwidth*6,ystart),(xstart+statboxwidth*5,ystart-100u/3)]) withcolor clr;
        %
        label(btex {\bigsf BB} etex, 1/2[(xstart+statboxwidth*7,ystart),(xstart+statboxwidth*6,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf SO} etex, 1/2[(xstart+statboxwidth*8,ystart),(xstart+statboxwidth*7,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf IBB} etex, 1/2[(xstart+statboxwidth*9,ystart),(xstart+statboxwidth*8,ystart-100u/3)]) withcolor clr;
        %
        label(btex {\bigsf HBP} etex, 1/2[(xstart+statboxwidth*10+1,ystart),(xstart+statboxwidth*9+1,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf BLK} etex, 1/2[(xstart+statboxwidth*11+1,ystart),(xstart+statboxwidth*10+1,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf WP} etex, 1/2[(xstart+statboxwidth*12+1,ystart),(xstart+statboxwidth*11+1,ystart-100u/3)]) withcolor clr;
        %
        label(btex {\bigsf HR} etex, 1/2[(xstart+statboxwidth*13,ystart),(xstart+statboxwidth*12,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf S} etex, 1/2[(xstart+statboxwidth*14,ystart),(xstart+statboxwidth*13,ystart-100u/3)]) withcolor clr;
        label(btex {\bigsf P} etex, 1/2[(xstart+statboxwidth*15,ystart),(xstart+statboxwidth*14,ystart-100u/3)]) withcolor clr;
    endgroup
enddef;

def set_vars(expr xstart, ystart) =
    begingroup
        % locations
        pair ballone, balltwo, ballthree, strikeone, striketwo, foulone, foultwo, foulthree, foulfour;
        ballone := (xstart+50u+(15u/2),ystart+(15u/2));
        balltwo := (xstart+50u+(15u/2)+15u,ystart+(15u/2));
        ballthree := (xstart+50u+(15u/2)+30u,ystart+(15u/2));
        strikeone := (xstart+50u+(15u/2),ystart+(15u/2)+15u);
        striketwo := (xstart+50u+(15u/2)+15u,ystart+(15u/2)+15u);
        foulone := (xstart+5u,ystart+9u);
        foultwo := (xstart+8u,ystart+5u);
        foulthree := (xstart+10u,ystart+11u);
        foulfour := (xstart+13u,ystart+7u);
        pair rbione, rbitwo, rbithree, rbifour, rundot, outlabel;
        rundot := (xstart+40u,ystart+49.5u);
        outlabel := (xstart+40u,ystart+49.5u);
        rbione := (xstart+5u,ystart+25u);
        rbitwo := (xstart+9u,ystart+20u);
        rbithree := (xstart+11u,ystart+28u);
        rbifour := (xstart+15u,ystart+23u);
        pair first, second, third, home;
        path single, double, triple, homerun;
        pbsize := 15u;
        dsize := 24u;
        dxstart := xstart+40u;
        dystart := ystart+pbsize*1.7;
        home := (dxstart,dystart);
        first := (dxstart+dsize,dystart+dsize);
        second := (dxstart,dystart+dsize*2);
        third := (dxstart-dsize,dystart+dsize);
        single := home--first--(first+(-7u,0));
        double := home--first--second--(second+(0,-7u));
        triple := home--first--second--third--(third+(7u,0));
        homerun := home--first--second--third--cycle;
        path firstsecond, firstthird, firsthome, secondthird, secondhome, thirdhome;
        firstsecond := first--second--(second+(0,-7u));
        firstthird := first--second--third--(third+(7u,0));
        firsthome := first--second--third--home;
        secondthird := second--third--(third+(7u,0));
        secondhome := second--third--home;
        thirdhome := third--home;
        path ifleft, ifright, ifcenter, ofleft, ofleftc, ofcenterl, ofcenterr, ofrightc, ofright;
        ifleft := home--(home+(-13u,18u));
        ifright := home--(home+(13u,18u));
        ifcenter := home--(home+(0,18u));
        ofleft := home--(home+(-32u, 36u));
        ofleftc := home--(home+(-20u, 60u));
        ofright := home--(home+(32u, 36u));
        ofrightc := home--(home+(20u, 60u));
        ofcenterl := home--(home+(-5u, 65u));
        ofcenterr := home--(home+(5u, 65u));
        path hrleft, hrleftc, hrcenterl, hrcenterr, hrrightc, hrright;
        hrleft := home--(home+(-37u, 41u));
        hrleftc := home--(home+(-27u, 67u));
        hrright := home--(home+(37u, 41u));
        hrrightc := home--(home+(27u, 67u));
        hrcenterl := home--(home+(-5u, 75u));
        hrcenterr := home--(home+(5u, 75u));
        lxstart := xstart+90u;
        lystart := ystart+92u;
        lsize := (lystart-ystart+(fsize/2)-pbsize)/6;
        pair hr, threeb, twob, oneb, bb, hp;
        hr := (lxstart,lystart);
        lystart := lystart - lsize;
        threeb := (lxstart,lystart);
        lystart := lystart - lsize;
        twob := (lxstart,lystart);
        lystart := lystart - lsize;
        oneb := (lxstart,lystart);
        lystart := lystart - lsize;
        bb := (lxstart,lystart);
        lystart := lystart - lsize;
        hp := (lxstart,lystart);
        pair wayfirst, waysecond, waythird, wayhome;
        path cs_second, cs_third, to_home;
        path cs_firstthird, to_firsthome, to_secondhome;
        wayfirst := 1/2[home,first];
        waysecond := 1/2[first,second];
        waythird := 1/2[second,third];
        wayhome := 1/2[third,home];
        cs_second := first--waysecond--(waysecond+(3u,3u))--(waysecond-(3u,3u));
        cs_third := second--waythird--(waythird+(-3u,3u))--(waythird-(-3u,3u));
        to_home := third--wayhome--(wayhome+(3u,3u))--(wayhome-(3u,3u));
        cs_firstthird := first--second--waythird--(waythird+(-3u,3u))--(waythird-(-3u,3u));
        to_firsthome := first--second--third--wayhome--(wayhome+(3u,3u))--(wayhome-(3u,3u));
        to_secondhome := second--third--wayhome--(wayhome+(3u,3u))--(wayhome-(3u,3u));
        path new_hitter, new_pitcher;
        new_hitter := (xstart-3u,ystart-3u)--(xstart+3u,ystart+3u)--(xstart,ystart)--(xstart+3u,ystart-3u)--(xstart-3u,ystart+3u)--(xstart,ystart)--(xstart,ystart+100u)--(xstart-3u,ystart+97u)--(xstart+3u,ystart+103u)--(xstart,ystart+100u)--(xstart+3u,ystart+97u)--(xstart-3u,ystart+103u);
        new_pitcher := (xstart-3u,ystart+97u)--(xstart+3u,ystart+103u)--(xstart,ystart+100u)--(xstart+3u,ystart+97u)--(xstart-3u,ystart+103u)--(xstart,ystart+100u)--(xstart+100u,ystart+100u)--(xstart+97u,ystart+97u)--(xstart+103u,ystart+103u)--(xstart+100u,ystart+100u)--(xstart+103u,ystart+97u)--(xstart+97u,ystart+103u);
    endgroup
enddef;

def draw_full_scorecard =
    begingroup
        % Draw the player boxes
        color clr;
        clr:=card;
        u := 1.0pt;
        size := 100u;
        fsize := 11u;
        xstart := 100;
        % Draw first nine position boxes
        for ystart := 100 step 100 until 900:
            draw_player_box(xstart,ystart,clr,true);
        endfor
        % Draw extra player boxes (without an inning column)
        for ystart := -100 step 100 until 0:
            draw_player_box(xstart,ystart,clr,false);
        endfor
        % Draw key for column totals
        for ystart := -100 step 100 until 0:
            draw_column_totals_key(xstart,ystart,clr);
        endfor
        % Draw all the at-bat boxes
        for ystart := 100 step 100 until 900:
            for xstart := 100 step 100 until 1100:
                draw_square(xstart, ystart);
            endfor
        endfor
        % Draw the totals boxes
        clr:=card;
        for ystart := -100 step 50 until 50:
            for xstart := 100 step 100 until 1100:
                draw_totals_box(xstart,ystart,clr);
            endfor
        endfor
        % Pitcher Rows
        for ystart := -300 step 100 until -200:
            draw_pitcher_row(100,ystart,clr,true);
            draw_pitcher_row(900+100u*(2/3),ystart,clr,false);
        endfor
        % Label pitcher rows (key on top line, numbers)
        draw_pitcher_labels(100,-100,clr,true);
        draw_pitcher_labels(900+100u*(2/3)-1,-100,clr,false);
        % Draw a thick line below the pitcher row label
        pickup pencircle scaled thickline_t;
        draw (100-iposwidth*3-namewidth,-100-100u/3)--(900+100u*2/3+400+100u,-100-100u/3) withcolor clr;
        pickup pencircle scaled thinline_t;
        % Put key into column totals
        iposwidth := 40u;
        namewidth := 250u;
        label(btex {\bigsf R} etex, 1/2[1/2[(100u,100u),(100u-iposwidth,50u)],(100u-iposwidth,100u)]) withcolor clr;
        label(btex {\bigsf H} etex, 1/2[1/2[(100u,100u),(100u-iposwidth,50u)],(100u,50u)]) withcolor clr;
        label(btex {\bigsf E} etex, 1/2[1/2[(100u,50u),(100u-iposwidth,0u)],(100u-iposwidth,50u)]) withcolor clr;
        label(btex {\bigsf LB} etex, 1/2[1/2[(100u,50u),(100u-iposwidth,0u)],(100u,0u)]) withcolor clr;
        label(btex {\bigsf BB} etex, 1/2[1/2[(100u,0u),(100u-iposwidth,-50u)],(100u-iposwidth,0u)]) withcolor clr;
        label(btex {\bigsf K} etex, 1/2[1/2[(100u,0u),(100u-iposwidth,-50u)],(100u,-50u)]) withcolor clr;
        label(btex {\bigsf S} etex, 1/2[1/2[(100u,-50u),(100u-iposwidth,-100u)],(100u-iposwidth,-50u)]) withcolor clr;
        label(btex {\bigsf P} etex, 1/2[1/2[(100u,-50u),(100u-iposwidth,-100u)],(100u,-100u)]) withcolor clr;
        % Draw all the row totals boxes
        for ystart := 100 step 100 until 900:
            for xstart := 1200 step 100 until 1300:
                draw_row_summary_box(xstart,ystart,clr);
            endfor
        endfor
        % Draw the game and play total boxes
        for ystart := -100 step 50 until 50:
            xstart := 1200;
            draw_game_summary_box(xstart,ystart,clr);
            draw_play_total_box(xstart,ystart,clr);
        endfor
        % Put the key on the play total boxes
        nudge := 5u;
        label.urt(btex {\sf 1B} etex, (1200+100u/3*2,50+25u+nudge)) withcolor clr;
        label.urt(btex {\sf 2B} etex, (1200+100u/3*2,50+nudge)) withcolor clr;
        label.urt(btex {\sf DP} etex, (1200+100u/3*2+100u,50+25u+nudge)) withcolor clr;
        label.urt(btex {\sf HBP} etex, (1200+100u/3*2+100u,50+nudge)) withcolor clr;
        label.urt(btex {\sf 3B} etex, (1200+100u/3*2,0+25u+nudge)) withcolor clr;
        label.urt(btex {\sf HR} etex, (1200+100u/3*2,0+nudge)) withcolor clr;
        label.urt(btex {\sf WP} etex, (1200+100u/3*2+100u,0+25u+nudge)) withcolor clr;
        label.urt(btex {\sf PB} etex, (1200+100u/3*2+100u,0+nudge)) withcolor clr;
        label.urt(btex {\sf SF} etex, (1200+100u/3*2,-50+25u+nudge)) withcolor clr;
        label.urt(btex {\sf SAC} etex, (1200+100u/3*2,-50+nudge)) withcolor clr;
        label.urt(btex {\sf SB} etex, (1200+100u/3*2+100u,-50+25u+nudge)) withcolor clr;
        label.urt(btex {\sf CS} etex, (1200+100u/3*2+100u,-50+nudge)) withcolor clr;
        % Proof
        label.urt(btex {\sf AB+BB+HBP+SAC+SF} etex, (1200+100u/3*2,-100+25u+nudge)) withcolor clr;
        label.urt(btex {\sf =\quad R+LOB+OPO} etex, (1200+100u/3*2+24u,-100+nudge)) withcolor clr;
        % Side information
        % pickup pencircle scaled thickline_t;
        pickup pencircle scaled thickline_t;
        draw (1400,100)--(1400,1000)--(1466,1000)--(1466,100)--cycle withcolor clr;
        draw (1399,1000)--(1399,1033.3)--(1466,1033.3)--(1466,1000)--cycle withcolor clr;
        pickup pencircle scaled thinline_t;;
        draw (1433.3,100)--(1433.3,1000) withcolor clr;
        label(btex {\bigsf Team} etex rotated 90, (1416,130)) withcolor clr;
        label(btex {\bigsf FP} etex rotated 90, (1416,614)) withcolor clr;
        label(btex {\bigsf Temp} etex rotated 90, (1416,870)) withcolor clr;
        label(btex {\bigsf At} etex rotated 90, (1448,142)) withcolor clr;
        label(btex {\bigsf Att} etex rotated 90, (1448,450)) withcolor clr;
        label(btex {\bigsf Scorer} etex rotated 90, (1448,600)) withcolor clr;
        label(btex {\bigsf Wind} etex rotated 90, (1448,870)) withcolor clr;
        label(btex {\tiny Copyright \char'251 2005, Christopher Swingley, cswingle@iarc.uaf.edu} etex rotated 90, (1472,-210)) withcolor clr;
        % Little numbers for first nine in batting order
        label(btex {\sf 1} etex, (-224u, 995u)) withcolor clr;
        label(btex {\sf 2} etex, (-224u, 895u)) withcolor clr;
        label(btex {\sf 3} etex, (-224u, 795u)) withcolor clr;
        label(btex {\sf 4} etex, (-224u, 694u)) withcolor clr;
        label(btex {\sf 5} etex, (-224u, 594u)) withcolor clr;
        label(btex {\sf 6} etex, (-224u, 494u)) withcolor clr;
        label(btex {\sf 7} etex, (-224u, 393u)) withcolor clr;
        label(btex {\sf 8} etex, (-224u, 293u)) withcolor clr;
        label(btex {\sf 9} etex, (-224u, 193u)) withcolor clr;
        % Numbers for pitchers
        label(btex {\sf 1} etex, (-224u, -141u)) withcolor clr;
        label(btex {\sf 2} etex, (-224u, -174u)) withcolor clr;
        label(btex {\sf 3} etex, (-224u, -208u)) withcolor clr;
        label(btex {\sf 4} etex, (-224u, -241u)) withcolor clr;
        label(btex {\sf 5} etex, (-224u, -274u)) withcolor clr;
        % second column of pitchers
        label(btex {\sf 6} etex, (640u, -141u)) withcolor clr;
        label(btex {\sf 7} etex, (640u, -174u)) withcolor clr;
        label(btex {\sf 8} etex, (640u, -208u)) withcolor clr;
        label(btex {\sf 9} etex, (640u, -241u)) withcolor clr;
        label(btex {\sf 10} etex, (643u, -274u)) withcolor clr;
        % Title boxes
            xstart:=100;
            ystart:=1000;
            pickup pencircle scaled thickline_t;
            % Inning and Position box
            draw (xstart,ystart)--(xstart-iposwidth*2u,ystart)--(xstart-iposwidth*2u,ystart+100u/3)--(xstart,ystart+100u/3)--cycle withcolor clr;
            draw (xstart-iposwidth,ystart)--(xstart-iposwidth,ystart+100u/3) withcolor clr;
            label(btex {\bigsf Pos} etex, 1/2[(xstart-iposwidth*2u,ystart),(xstart-iposwidth,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf Inn} etex, 1/2[(xstart-iposwidth,ystart),(xstart,ystart+100u/3)]) withcolor clr;
            % Player name box
            draw (xstart-iposwidth*2,ystart)--(xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*2-namewidth,ystart+100u/3)--
                    (xstart-iposwidth*2,ystart+100u/3)--cycle withcolor clr;
            label(btex {\bigsf Batter} etex, 1/2[(xstart-iposwidth*2-namewidth,ystart),(xstart-iposwidth*2,ystart+100u/3)]) withcolor clr;
            % Number box
            draw (xstart-iposwidth*2-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart)--(xstart-iposwidth*3-namewidth,ystart+100u/3)--
                    (xstart-iposwidth*2-namewidth,ystart+100u/3)--cycle withcolor clr;
            label(btex {\bigsf \#} etex, 1/2[(xstart-iposwidth*2-namewidth,ystart),(xstart-iposwidth*3-namewidth,ystart+100u/3)]) withcolor clr;
            % Inning boxes
            ystart:=1000;
            for xstart := 100 step 100 until 1100:
                draw (xstart,ystart)--(xstart+100u,ystart)--(xstart+100u,ystart+100u/3)--(xstart,ystart+100u/3)--cycle withcolor clr;
            endfor
            label(btex {\bigsf 1} etex, 1/2[(100,ystart),(200,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 2} etex, 1/2[(200,ystart),(300,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 3} etex, 1/2[(300,ystart),(400,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 4} etex, 1/2[(400,ystart),(500,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 5} etex, 1/2[(500,ystart),(600,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 6} etex, 1/2[(600,ystart),(700,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 7} etex, 1/2[(700,ystart),(800,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 8} etex, 1/2[(800,ystart),(900,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 9} etex, 1/2[(900,ystart),(1000,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 10} etex, 1/2[(1000,ystart),(1100,ystart+100u/3)]) withcolor clr;
            label(btex {\bigsf 11} etex, 1/2[(1100,ystart),(1200,ystart+100u/3)]) withcolor clr;
            % Player totals
            ystart:=1000;
            for xstart := 1200 step 100u/3 until 1300+100u/3*2:
                draw (xstart,ystart)--(xstart+100u/3,ystart)--(xstart+100u/3,ystart+100u/3)--(xstart,ystart+100u/3)--cycle withcolor clr;
            endfor
            % On the top
            label(btex {\bigsf AB} etex, 1/2[(1200,1000),(1200+100u/3,1000+100u/3)]) withcolor clr;
            label(btex {\bigsf R} etex, 1/2[(1200+100u/3,1000),(1200+100u/3*2,1000+100u/3)]) withcolor clr;
            label(btex {\bigsf H} etex, 1/2[(1200+100u/3*2,1000),(1300,1000+100u/3)]) withcolor clr;
            label(btex {\bigsf RBI} etex, 1/2[(1300,1000),(1300+100u/3,1000+100u/3)]) withcolor clr;
            label(btex {\bigsf BB} etex, 1/2[(1300+100u/3,1000),(1300+100u/3*2,1000+100u/3)]) withcolor clr;
            label(btex {\bigsf SO} etex, 1/2[(1300+100u/3*2,1000),(1400,1000+100u/3)]) withcolor clr;
        pickup pencircle scaled playline_t;
    endgroup
enddef;

EOT


$TEX = <<'EOT';
\pdfinfo
  { /Title          (scorecard.pdf)
    /Creator        (Metapost, TeX)
    /Author         (Christopher Swingley) }
\input miniltx
\input graphicx.sty
\input eplain
\resetatcatcode
\paperheight 11 true in
\paperwidth 8.5 true in
\topmargin 0.75cm
\bottommargin 0.75cm
\leftmargin 1.00cm
\rightmargin 0.75cm
\nopagenumbers
\parindent=0pt\parskip=8pt
\vfill
\includegraphics[height=\hsize,angle=90]{__BASE__-0.pdf}
\vfill\eject
\bye
EOT


$TEXD = <<'EOT';
\pdfinfo
  { /Title          (metapost_scorecard.pdf)
    /Creator        (Metapost, TeX)
    /Author         (Christopher Swingley) }
\input miniltx
\input graphicx.sty
\input eplain
\resetatcatcode
\paperheight 11 true in
\paperwidth 8.5 true in
\topmargin 0.85cm
\bottommargin 0.65cm
\leftmargin 1.00cm
\rightmargin 0.75cm
\nopagenumbers
\parindent=0pt\parskip=8pt
\vfill
\includegraphics[height=\hsize,angle=90]{__BASE1__-0.pdf}
\vfill\eject
\includegraphics[height=\hsize,angle=90]{__BASE2__-0.pdf}
\vfill\eject
\bye
EOT


=head1 LIMITATIONS

This module makes no attempt to try to work around the physical limitations
of the scorecard.  So if there are more than 11 innings, more than nine batters
in an inning, more than three players in a lineup position, or more than
ten pitchers, it will fail, either by dying, or just screwing up the output.

More than four foul balls will not be recorded for a given at-bat in the graphic
(but the pitch counts will still be incremented appropriately).

Also, no attempt is made to make sure you have the right number of outs in an
innings, balls/strikes in a walk/strikeout, and so on.  We don't even necessarily
check to make sure you've called inn() before you call your first ab(), or that
you don't use an incorrect base number, and so on.  Or that David Ortiz isn't
pitching, or playing all positions at once.  Just don't record something
illegal in a baseball game, and you likely won't run into problems here,
either.

There are also likely things that happen in the game that the API here does
not well-address.

Patches are welcome for all of this, if you want it.


=head1 TODO

Automatically, or otherwise, handle more than 9 batters per inning, or more
than 11 innings, perhaps by adding a new scorecard, or by re-using existing
innings for overflow.


=head1 AUTHOR

Chris Nandor E<lt>projects@pudge.netE<gt>, http://projects.pudge.net/

Copyright (c) 2005 Chris Nandor.  Licensed under the terms of the GNU General
Public License, Version 2 available from http://www.gnu.org/copyleft/gpl.html.

Front end to mpost_scorecard by Christopher Swingley, also licensed under
the GPL.

=head1 SEE ALSO

http://www.frontier.iarc.uaf.edu/~cswingle/baseball/scorecards.php


=head1 VERSION

$Id: Scorecard.pm,v 1.5 2005/10/21 04:48:58 pudge Exp $

__END__
