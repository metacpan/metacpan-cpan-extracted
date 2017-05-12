#!/usr/bin/perl -w
use strict;

my $VERSION = '0.08';

#----------------------------------------------------------
# Loader Variables

my $BASE;
BEGIN {
    $BASE = '../../cgi-bin';
}

#----------------------------------------------------------
# Library Modules

use lib ( "$BASE/lib", "$BASE/plugins", 'lib' );

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::Variables;
use Labyrinth::Plugin::Survey;

use Data::Dumper;
use File::Basename;
use File::Path;
use File::Copy;
use Getopt::Long;
use HTML::Entities;
use Imager              qw(:handy);
use Imager::Graph::Pie;
use IO::File;
use Template;

#----------------------------------------------------------
# Variables

my (%count,%amount,%average,%text,%graphs,%options);
my ($backg,$foreg) = ('white','black');
my $TARGET = './results';
my $FORMAT = 'png';
my $CODE;

my $plugin = Labyrinth::Plugin::Survey->new();

my $config = "$BASE/config/settings.ini";

#----------------------------------------------------------
# Data sets

my $thattime;
my %thattime;

#----------------------------------------------------------
# Code

if (! GetOptions( \%options, 'ext|e=s', 'type|t=s', 'graphs|g', 'verbose|v' )) {
   print "usage: $0 [--ext=<str>] [--graphs] [--type=[survey|feedback|tpf]] [--verbose]\n";
   exit;
}

$options{ext}  ||= 'html';
$options{type} ||= 'survey';
$options{type}   = 'survey' unless($options{type} =~ /^(survey|feedback|tpf)$/);

Labyrinth::Variables::init();
Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

$CODE = $settings{icode};
die "No conference code is set\n"   unless($CODE);

    SetLogFile( FILE   => 'audit.log',
                USER   => 'labyrinth',
                LEVEL  => 4,
                CLEAR  => 1,
                CALLER => 1);

process();
write_results();

# -------------------------------------
# The Subs

sub process {
    $tvars{survey} = $plugin->LoadSurvey($settings{'survey'});

    #print STDERR "type=$options{type}\n" if($options{verbose});

    for my $section (@{$tvars{survey}->{sections}}) {
        print "section=$section->{label}\n" if($options{verbose});

        my $graph = 0;
        if($section->{tag} =~ /demographics/i && $options{type} eq 'survey') {
            $graph = 1;

            # Attendees - qu00000
            my $qu = 'qu00000';
            my $q = { name => $qu, label => 'Attendees:', type => 'private',
                      options => [ { key => 'Responded', value => 'Y' }, { key => 'No Response', value => 'N' }, { key => 'Total', value => 'T' }, { key => 'Response Percentage', value => 'P' } ] };
            unshift @{$section->{questions}}, $q;

            my @rsa = $dbi->GetQuery('array','SurveyResponded');
            $tvars{results}{$qu}{'Y'}{value} = scalar(@rsa);
            my @rsb = $dbi->GetQuery('array','SurveyNotResponded');
            $tvars{results}{$qu}{'N'}{value} = scalar(@rsb);
            $tvars{results}{$qu}{'T'}{value} = scalar(@rsa) + scalar(@rsb);
            $tvars{results}{$qu}{'P'}{value} = int((scalar(@rsa) * 100) / (scalar(@rsa) + scalar(@rsb)));

            my @data;
            push @{$data[0]}, 'Responded', 'No Response';
            push @{$data[1]}, map {$tvars{results}{$qu}{$_}{value}} ('Y', 'N');

            make_graph($q->{name},$q->{label},\@data);
        }


        for my $question (@{$section->{questions}}) {
            $question->{results} ||= $section->{results};
            next    if($question->{status} && $question->{status} eq 'hidden');
            next    if($question->{results} && $question->{results} !~ /\Q$options{type}\E/i);
            #print STDERR "type=$options{type} != ".($question->{results}||'undef')."\n" if($options{verbose});
            $section->{show} = 1;
            $question->{show} = 1;

            if($question->{multipart}) {
                print "question=".($question->{label}||'n/a')." - ".($question->{name}||'<multipart>')." - ".($question->{results}||'?')."\n"   if($options{verbose});
                for my $multipart (@{$question->{multipart}}) {
                    print "question=".($question->{label}||'n/a')." - ".($multipart->{name}||'<multipart>')." - ".($question->{results}||'?')."\n"   if($options{verbose});
                    _analyse_question($graph,$multipart,$question->{label});
                }
            } else {
                print "question=".($question->{label}||'n/a')." - ".($question->{name}||'<error>')." - ".($question->{results}||'?')."\n"   if($options{verbose});
                _analyse_question($graph,$question,$question->{label});
            }
        }
    }

LogDebug("tvars=".Dumper(\%tvars));

#    $tvars{groups}{$part->{group}}{results}{$part->{name}}{$rs->[0]} = $rs->[1];
    for my $group (keys %{ $tvars{groups} }) {
        my $max = 1;
        for my $qu (keys %{ $tvars{groups}{$group}{results} }) {
            for my $val (keys %{ $tvars{groups}{$group}{results}{$qu} }) {
                $max = $val if($max < $val);
            }
        }
        $tvars{groups}{$group}{options} = [1 .. $max];
        for my $qu (keys %{ $tvars{groups}{$group}{results} }) {
            for my $val (@{ $tvars{groups}{$group}{options} }) {
                $tvars{groups}{$group}{results}{$qu}{$val} ||= '-';
            }
        }
    }
#LogDebug("groups=".Dumper($tvars{groups}));
}


sub _analyse_question {
    my ($graph,$part,$label) = @_;

    unless($part && $part->{type}) {
        print STDERR "Missing type: " . Dumper($part);
        next;
    }

    my $sql = $options{type} eq 'feedback' ? 'SurveyFeedbackResults' : 'SurveyQuestionResults';

    my @rs = $dbi->GetQuery('array',$sql,$part->{name});
    if($part->{type} =~ /radio|select/) {
        my $default = 0;
        my %rs = map {$_->[0] => $_->[1]} @rs;
        for my $opt (@{$part->{options}}) {
            $tvars{results}{$part->{name}}->{$opt->{value}}->{label} = $opt->{key};
            $tvars{results}{$part->{name}}->{$opt->{value}}->{value} = $rs{$opt->{value}} || 0;
            $default = 1    if($opt->{default});
        }

        if($graph) {
            my @data;
            push @{$data[0]}, map {
                    my $x = $tvars{results}{$part->{name}}->{$_}->{label};
                    $x =~ s!Technical Archi.*!Analyst!;
                    $x =~ s!Technical Manag.*!Manager!;
                    $x =~ s!CEO.*!Director!;
                    $x =~ s!Telecomm.*!Telecomms!;
                    $x =~ s!Media.*!Media!;
                    $x =~ s!Medical.*!Medical!;
                    $x =~ s!Internet.*!Internet!;
                    $x;
                }
                sort {$tvars{results}{$part->{name}}->{$b}->{value} <=> $tvars{results}{$part->{name}}->{$a}->{value}}
                keys %{$tvars{results}{$part->{name}}};
            push @{$data[1]}, map {$tvars{results}{$part->{name}}->{$_}->{value}}
                sort {$tvars{results}{$part->{name}}->{$b}->{value} <=> $tvars{results}{$part->{name}}->{$a}->{value}}
                keys %{$tvars{results}{$part->{name}}};

            make_graph($part->{name},$label,\@data);
        }

        if($default) {
            @rs = $dbi->GetQuery('array',$sql,"$part->{name}X");
        #print uc($part->{type}).": $part->{name}X/default=".Dumper(\@rs);
            $tvars{results}{"$part->{name}X"}->{value} = [
                map {
                    if($_->[0]) { $_->[0] =~ s/[\n\r]/\n/g; $_->[0] =~ s/\n{2,}/\n/g; $_->[0] =~ s/\n/\n    /g; $_->[0] =~ s/&#8206;//g; $_->[0] }
                    else        { '' }
                } @rs ];
        #print uc($part->{type}).": $part->{name}X/result=".Dumper($tvars{results}{"$part->{name}X"}->{value});
        }

    } elsif($part->{type} =~ /matrix/) {
        my $choices = @{$part->{choices}};
        #print "MATRIX: choices=".Dumper($part->{choices});
        #print "MATRIX: options=".Dumper($part->{options});
        for my $inx (1 .. $choices) {
            my @rs = $dbi->GetQuery('array',$sql,"$part->{name}_$inx");
            for my $rs (@rs) {
                next    unless($rs->[0] && $part->{options}->[$rs->[0]]);
                #print "MATRIX: name=$part->{name}, inx=$inx, choice=$part->{choices}->[$inx-1], option=$part->{options}->[$rs->[0]], key=$rs->[0], value=$rs->[1]\n";
                $tvars{results}{$part->{name}}->{$inx-1}->{$rs->[0]}->{value} = $rs->[1];
            }
            my $options = @{$part->{options}};
            for my $opt (1 .. $options) {
                $tvars{results}{$part->{name}}->{$inx-1}->{$opt}->{value} ||= '-';
            }
        }

    } elsif($part->{type} =~ /text/) {
        $tvars{results}{$part->{name}}->{value} = [
            map {
                if($_->[0]) { $_->[0] =~ s/[\n\r]/\n/g; $_->[0] =~ s/\n{2,}/\n/g; $_->[0] =~ s/\n/\n    /g; $_->[0] =~ s/&#8206;//g; $_->[0] }
                else        { '' }
            } @rs ];

    } elsif($part->{type} =~ /currency/) {
        for my $rs (@rs) {
            #print "CURRENCY: name=$part->{name}, key=$rs->[0], value=$rs->[1]\n";
            $tvars{results}{$part->{name}}->{$rs->[0]}->{value} = $rs->[1] || 0;
        }

    } elsif($part->{type} =~ /count/) {
        $tvars{results}{$part->{name}}->{value} = 0;
        for my $rs (@rs) {
            $rs->[0] = 3    if($rs->[0] eq 'AL');
            $tvars{results}{$part->{name}}->{name} = $part->{options}[0]{key};
            $tvars{results}{$part->{name}}->{value} += $rs->[0] * $rs->[1];
            $tvars{groups}{$part->{group}}{results}{$part->{name}}{$rs->[0]} = $rs->[1];
        }

    } elsif($part->{type} =~ /checkbox/) {
        $tvars{results}{$part->{name}}->{value} = $rs[0]->[1];
        if($part->{default}) {
            @rs = $dbi->GetQuery('array',$sql,"$part->{name}X");
        #print "CHECKBOX: $part->{name}X/default=".Dumper(\@rs);
            $tvars{results}{"$part->{name}X"}->{value} = [
                map {
                    if($_->[0]) { $_->[0] =~ s/[\n\r]/\n/g; $_->[0] =~ s/\n{2,}/\n/g; $_->[0] =~ s/\n/\n    /g; $_->[0] =~ s/&#8206;//g; $_->[0] }
                    else        { '' }
                } @rs ];
        #print "CHECKBOX: $part->{name}X/result=".Dumper($tvars{results}{"$part->{name}X"}->{value});
        }
    }
#LogDebug("results=".Dumper($tvars{results}));
}


sub write_results {
    $tvars{CODE} = $CODE;
    my $SOURCE = "$BASE/templates";
    my $source = "survey/results-$options{type}.$options{ext}";
    $source = "survey/results-survey.$options{ext}" unless(-f "$SOURCE/$source");
    unless(-f "$SOURCE/$source") {
        print STDERR "No source template file found: $source\n";
        exit;
    }

    my $target = "$CODE-$options{type}.$options{ext}";
    mkpath(dirname("$TARGET/$target"));

    writer($source,$target,\%tvars,$SOURCE,$TARGET);
}

sub make_graph {
    my ($name,$title,$data) = @_;
    my $base = "$TARGET/$CODE-images";
    mkpath($base);

    LogDebug("$name=[$title], data=".Dumper($data));

    set_image_format();
    my $image = "$base/$name.$FORMAT";
    my $thumb = "$base/$name-thumb.$FORMAT";
    print "## image image=$image\n";

    my %graph = ( image => basename($image), thumb => basename($thumb) );
    $tvars{graphs}{$name} = \%graph;
    return  unless($options{graphs});

    my $fontfile = '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf';
    #my $fontfile = '/usr/share/fonts/truetype/ttf-bitstream-vera/VeraSe.ttf';
    die "Font file not found [$fontfile]\n" unless(-f $fontfile);

    my $font = Imager::Font->new(file => $fontfile);

    #my $font = Imager::Font->new(family => 'Sans');
    my $pie = Imager::Graph::Pie->new();
    $pie->set_user_defaults(
        minsegsize  => 0,
        maxsegment  => 8,
        otherlabel  => '(etc.)',
        width       => 600,
        height      => 400
    );

    my $img = $pie->draw(
        data        => $data->[1],
        labels      => $data->[0],
        font        => $font,
        style       => 'fount_lin',
        features    => [ 'legend', 'labelspconly', ],
        legend      => { valign => 'center' }
    );

    #print "1.IMAGE: $image\n";
    return  unless($img);
    #print "2.IMAGE: $image\n";

    $img->write(file=>$image)
        or die "Cannot save file [$image]: ",$img->errstr,"\n";
    #print "3.IMAGE: $image\n";

    # make thumbnail
    copy($image,$thumb);
    my $t;
    eval { $t = Labyrinth::DIUtils->new($thumb); };
    $t->reduce(200,200) if($t);
}

sub writer {
    my ($template,$output,$vars,$path_input,$path_output) = @_;

    $path_input  ||= '.';
    $path_output ||= './html';
    #mkpath($path_output);

    my $layout = "$path_input/$template";

    die "Missing template [$layout]\n"  unless(-e $layout);

    my %config = (                              # provide config info
        RELATIVE        => 1,
        ABSOLUTE        => 1,
        INCLUDE_PATH    => $path_input,
        OUTPUT_PATH     => $path_output,
        INTERPOLATE     => 0,
        POST_CHOMP      => 1,
    );

    my $parser = Template->new(\%config);   # initialise parser
    $parser->process($layout,$vars,$output) # parse the template
        or die $parser->error();
}

sub set_image_format {
    return  if($FORMAT);
    for my $format ( qw( png gif jpg tiff bmp ) ) {
        if($Imager::formats{$format}) {
            $FORMAT = $format;
            last;
        }
    }
}

__END__

=head1 NAME

results.pl - script to intepret sections of the main conference survey.

=head1 DESCRIPTION

Based on the arguments filters sections of the main conference survey into
output files for the YAPC Surveys and organisers of the event.

NOTE: The graphs produced are created by a modified version of
Imager::Graph::Pie, which is no longer compatible with the version on CPAN.
This version may appear on GitHub at some point in the future, or patches will
be submitted for the current released version.

=head1 USAGE

  results.pl [--ext=<str>] [--graphs] [--type=[survey|feedback|tpf]] [--verbose]

=head1 OPTIONS

=over

=item --ext=<str>

This allows you to difine the extension to be used. This is also determined
by the templates available. In most cases the default is 'html'.

=item --graphs

Creates the demographic graphs, providing the correct version of
Imager::Graph::Pie is used.

=item --type=<type>

This the filter used on the survey responses, to only extract data for these
types of questions. By default the type is 'survey'. However, this also depends
on the type attributed to sections and questions in the survey configuration
file.

See Survey Specification documentation for further details.

=item --verbose

Prints messages as survey data is processed and printed out.

=back

=head1 SEE ALSO

L<Labyrinth>

L<http://yapc-surveys.org>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug report and/or patch via RT [1], or raise
an issue or submit a pull request via GitHub [2]. Note that it helps
immensely if you are able to pinpoint problems with examples, or supply a
patch.

[1] http://rt.cpan.org/Public/Dist/Display.html?Name=Labyrinth-Plugin-Survey
[2] http://github.com/barbie/labyrinth-plugin-survey

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

Barbie, <barbie@cpan.org>
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT

  Copyright (C) 2006-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
