#!/usr/bin/env perl
use strict;
use warnings;
use 5.014 ;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Getopt::Long   qw(GetOptions);
use JSON::PP ;
use JSON::JSONFold qw(jsonfold_config write_json) ;
use Data::Dumper;

use Carp qw(confess cluck);

BEGIN {
    $SIG{__DIE__} = sub {
        return if $^S;
        local $SIG{__DIE__};
        Carp::confess(@_);
    };


    $SIG{__WARN__} = sub {
        local $SIG{__WARN__};
        Carp::cluck(@_);
    };
}

sub demo_data {
    return JSON::JSONFold::CLI::demo_data() ;
}

sub parse_options {
    my %cfg ;

    my %opt = (
        compact   => 'default',
        indent    => 2,
        demo      => 0,
        verbose   => 0,
        sort_keys => 1,
        help      => 0,
        cfg       => \%cfg,
    );

    GetOptions(
        'demo'       => \$opt{demo},
        'verbose|v'  => \$opt{verbose},
        'help|h'     => \$opt{help},
        'input|i=s'  => \$opt{input},
        'compact=s'  => \$opt{compact},
        'indent=i'   => \$opt{indent},
        'native'     => \$opt{native},
        'sort-keys!' => \$cfg{sort_keys},

        'width=i'            => \$cfg{width},
        'pack-items=i'       => \$cfg{pack_items},
        'pack-array-items=i' => \$cfg{pack_array_items},
        'pack-obj-items=i'   => \$cfg{pack_obj_items},
        'pack-nesting=i'     => \$cfg{pack_nesting},
        'fold-items=i'       => \$cfg{fold_items},
        'fold-array-items=i' => \$cfg{fold_array_items},
        'fold-obj-items=i'   => \$cfg{fold_obj_items},
        'fold-nesting=i'     => \$cfg{fold_nesting},
        'join-items=i'       => \$cfg{join_items},
        'join-array-items=i' => \$cfg{join_array_items},
        'join-obj-items=i'   => \$cfg{join_obj_items},
        'join-nesting=i'     => \$cfg{join_nesting},
    ) or die "Try --help\n";

    return \%opt;
}

sub usage {
    my $out = shift ;
    $out->print(<<___
Usage: json-jsonfold [options] < input.json

  --demo
  --compact=default|none|low|med|high|max|pack|fold|join|off
  --width=N
  --indent=N
  --sort-keys
  --input=FILE
  --pack-items=N / --pack-array-items=N / --pack-obj-items=N / --pack-nesting=N
  --fold-items=N / --fold-array-items=N / --fold-obj-items=N / --fold-nesting=N
  --join-items=N / --join-array-items=N / --join-obj-items=N / --join-nesting=N
___
    ) ;
}

sub read_input {
    my ($input) = @_ ;

    my $json_text;
    if (defined $input) {
        open my $fh, '<:encoding(UTF-8)', $input or die "$input: $!\n";
        local $/;
        $json_text = <$fh>;
        close $fh or die "$input: $!\n";
    } else {
        binmode STDIN, ":encoding(UTF-8)" ;
        local $/;
        $json_text = <STDIN>;
    }

    return JSON::PP->new->allow_nonref->decode($json_text);
}

sub get_config {
    my ($opt) = @_;

    my %cfg = %{$opt->{cfg}} ;

    for my $phase (qw(pack fold join)) {
        my $k = "${phase}_items";
        my $v = delete($cfg{$k}) ;
        next unless defined($v) ;

        $cfg{"${phase}_array_items"} //= $v ;
        $cfg{"${phase}_obj_items"}   //= $v ;
    }
    # Get only set options
    %cfg = map { ($_ => $cfg{$_}) } grep { defined $cfg{$_} } keys(%cfg) ;
# Temporary hack until we figure sort order.

    $cfg{sort_keys} = 1 ;

    my $config = jsonfold_config($opt->{compact}, $opt->{width}, %cfg);
    return $config ;
}

sub show_verbose {
    my ($label) = shift ;
    my $dumper = new Data::Dumper([])->Terse(1)->Indent(1)->Sortkeys(1)->Pair('=')->Quotekeys(0) ;

    my $s = $dumper->Values( \@_)->Dump ;
    $s =~ s/\s+/ /gsm ;

    print STDERR "$label: $s\n" ;

}

sub stdout_width {
    return unless -t STDOUT;

    eval {
        require Term::ReadKey;
        my ($cols) = Term::ReadKey::GetTerminalSize(*STDOUT);
        return $cols if $cols;
    };

    return $ENV{COLUMNS} ;
}


sub main {
    my $opt = parse_options();

    if ($opt->{help}) {
        usage();
        return 0;
    }

    binmode STDOUT, ':encoding(UTF-8)' ;
    my $verose = $opt->{verbose} ;

    my $data = $opt->{demo} ? demo_data() : read_input($opt->{input});
    $opt->{cfg}{width} //= stdout_width() if -t STDOUT ;

    my $cfg = get_config($opt);
    my $verbose = $opt->{verbose} ;
    my $native = $opt->{native} ;

    print STDERR "Backend: ", $JSON::JSONFold::BACKEND || "-", "\n" if $verbose ;
    show_verbose("config", { $cfg->as_hash }) if $verbose ;
 
    my $info = write_json($data, \*STDOUT, $opt->{width}, $cfg, sort_keys => $opt->{sort_keys}, gold => !$native);

    show_verbose("stats", { % $info }) if $verbose ;
    return 0;
}

main() ;
