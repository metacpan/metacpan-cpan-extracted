package Lingua::TreeTagger::Installer;

use warnings;
use strict;

our $VERSION = '0.54';

use Clone 'clone';
use YAML;
use LWP::Simple;
use IO::Uncompress::Gunzip 'gunzip';
use File::Copy qw'move cp';
use File::Temp qw'tempdir tempfile';
use File::Basename;
use Archive::Any;


our $data;

{
    local $/ = "";
    $data = Load( <DATA> );
}

sub custom_install {
    my ($self, $from, $to) = @_;

    $self->verbose(" - installing", basename($from), "into $to");
    $to .= "/" unless $to =~ m{/$};
    $to .= basename($from);
    if (-f $to && not $self->{force}) {
        die "Target file exists.\nProbably another version of parameter file was already installed.\nWon't install without force (-f)\n";
    }
    cp $from => $to or die "Installation failed. You have write permissions?\n";
}

sub install_to_cmd {
    my ($self, $file) = @_;

    require Lingua::TreeTagger::Installer::ConfigData;
    my $treebin = Lingua::TreeTagger::Installer::ConfigData->config('treebin');

    $self->custom_install($file, $treebin);
    chmod 0755, "$treebin/" . basename($file);
}

sub install_to_bin {
    my ($self, $file) = @_;

    require Lingua::TreeTagger::Installer::ConfigData;
    my $bin = Lingua::TreeTagger::Installer::ConfigData->config('bin');

    $self->custom_install($file, $bin);
    chmod 0755, "$bin/" . basename($file);
}

sub install_to_lib {
    my ($self, $file) = @_;

    require Lingua::TreeTagger::Installer::ConfigData;
    my $treelib = Lingua::TreeTagger::Installer::ConfigData->config('treelib');

    $self->custom_install($file, $treelib);
}

sub new {
    my $class = shift;
    my %ops = @_;
    local $/ = "";
    open R, "<", "$ENV{HOME}/.treetagger" or die "Can't find .treetagger config file\n";
    my $data = Load( <R> );
    close R;

    my $self = { data => $data };

    for my $l (keys %{$data->{languages}}) {
        for my $e (@{$data->{languages}{$l}}) {
            $self->{lookup}{$e->{id}} = clone $e;
            $self->{lookup}{$e->{id}}{lang} = $l;
        }
    }

    $self->{verbose}++ if $ops{verbose};
    $self->{force}++   if $ops{force};

    return bless $self => $class
}

sub verbose {
    my ($self, @message) = @_;
    if ($self->{verbose}) {
        print STDERR join(" " => @message), "\n";
    }
}

sub list_parameter_files {
    my $self = shift;
    my $count = 0;
    print "Listing available and installed parameter files\n";
    for my $lang (keys %{$self->{data}{languages}}) {
        for my $par (@{$self->{data}{languages}{$lang}}) {
            my $author = exists($par->{author}) ? " by $par->{author}" : "";
            my $parfile = exists($par->{parfile}) ? $par->{parfile} : undef;
            if ($parfile) {
                print "$par->{id} [INSTALLED] $lang ($par->{encoding})$author as $parfile.\n";
            } else {
                print "$par->{id} [AVAILABLE] $lang ($par->{encoding})$author.\n";
            }
        }
    }
}

sub installed {
    my ($self, $parameter, $filename) = @_;
    my $l = $self->{lookup}{$parameter}{lang};
    for my $e (@{$self->{data}{languages}{$l}}) {
        $e->{parfile} = $filename if $e->{id} eq $parameter;
    }
    $self->save;
}

sub install {
    my ($self, $parameter) = @_;

    $parameter = uc $parameter;
    return "unknown code" unless exists($self->{lookup}{$parameter});

    my $url  = $self->{lookup}{$parameter}{url};
    my $lang = $self->{lookup}{$parameter}{lang};
    my $filename = $url;
    $filename =~ s{^.*/}{};

    $self->verbose(" - downloading into $filename");
    getstore $url => $filename;

    if (exists($self->{lookup}{$parameter}{manifest})) {
        if ($filename =~ /tar.gz$/) {
            my $tgz = Archive::Any->new( $filename );

            my $dir = tempdir CLEANUP => 1;
            $tgz->extract( $dir );

            unlink $filename;
            my $files = $self->{lookup}{$parameter}{manifest};
            for my $f (@$files) {

                if ($f =~ m!^lib/!) {
                    $self->install_to_lib("$dir/$f");
                    if ($f =~ /par$/) {
                        $f =~ s{.*/}{};
                        $self->installed($parameter, $f);
                    }
                }
                if ($f =~ m!^bin/!) {
                    my $t = $f;
                    $t =~ s/^bin/cmd/;
                    move "$dir/$f" => "$dir/$t";
                    $f = $t;
                }
                if ($f =~ m!^cmd/!) {
                    if ($f =~ m{/tree-tagger-[a-z]+$}) {
                        $self->process_sh_file("$dir/$f");
                        $self->install_to_bin("$dir/$f");
                    }
                    else {
                        $self->install_to_cmd("$dir/$f");
                    }
                }
            }
        }
    }
    else {
        my $utf = $self->{lookup}{$parameter}{encoding} =~ /utf.?8/i ? "-utf8" : "";

        gunzip $filename => "$lang$utf.par" or die "Can't gunzip $filename";

        $self->install_to_lib("$lang$utf.par");

        unlink $filename;
        unlink "$lang$utf.par";
        $self->installed($parameter, "$lang$utf.par");
    }

    return 0;
}


sub save {
    my $self = shift;
    open CFG, ">", "$ENV{HOME}/.treetagger" or die "Can't create file\n";
    print CFG Dump($self->{data});
    close CFG;
}

sub create_cfg {
    open CFG, ">", "$ENV{HOME}/.treetagger" or die "Can't create file\n";
    $data->{version} = $VERSION;
    print CFG Dump($data);
    close CFG;
}

sub process_sh_file {
  my $self = shift;
  my $file = shift;

  local $/ = undef;
  open my $fh, $file or die;
  my $contents = <$fh>;
  close $fh;

  # Make this cleaner
  require Lingua::TreeTagger::Installer::ConfigData;
  my $bin = Lingua::TreeTagger::Installer::ConfigData->config('bin');
  my $treelib = Lingua::TreeTagger::Installer::ConfigData->config('treelib');
  my $treebin = Lingua::TreeTagger::Installer::ConfigData->config('treebin');

  $contents =~ s/^\s*BIN=.*/BIN='$bin'/m;
  $contents =~ s/^\s*CMD=.*/CMD='$treebin'/m;
  $contents =~ s/^\s*LIB=.*/LIB='$treelib'/m;

  open my $out, ">", $file or die;
  print $out $contents;
  close $out;

  print STDERR `cat $file`;
}


1;

=encoding utf8

=head1 NAME

Lingua::TreeTagger::Installer - An installer tool for TreeTagger

=head1 DESCRIPTION

This module is an auxiliary module for C<tree-tagger-install-lang>
command line script.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 by Alberto Manuel Brandão Simões

=cut

__DATA__
platforms:
  linux64: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-linux-3.2.tar.gz
  linux: http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/tree-tagger-linux-3.2-old.tar.gz
#  sparc-solaris: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-3.2.tar.gz
#  macosx-ppc: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-MacOSX-3.2.tar.gz
  macosx-intel: http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/tree-tagger-MacOSX-3.2-intel.tar.gz
languages:
  bulgarian:
    - id: BG-1
      encoding: UTF-8
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/bulgarian-par-linux-3.1.bin.gz
  dutch:
    - id: NL-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/dutch-par-linux-3.1.bin.gz
    - id: NL-2
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/dutch2-par-linux-3.1.bin.gz
      author: Julien Bioche
  english:
    - id: EN-1
      encoding: UTF-8
      url: http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/english-par-linux-3.2-utf8.bin.gz
  french:
    - id: FR-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/french-par-linux-3.2.bin.gz
    - id: FR-2
      encoding: UTF-8
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/french-par-linux-3.2-utf8.bin.gz
  italian:
    - id: IT-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par-linux-3.1.bin.gz
    - id: IT-2
      encoding: UTF-8
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par-linux-3.2-utf8.bin.gz
    - id: IT-3
      encoding: ISO-8859-1
      author: Marco Beroni
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par2-linux-3.1.bin.gz
  spanish:
    - id: ES-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/spanish-par-linux-3.1.bin.gz
    - id: ES-2
      encoding: UTF-8
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/spanish-par-linux-3.2-utf8.bin.gz
  estonian:
    - id: ET-1
      encoding: UTF-8
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/estonian-par-linux-3.2.bin.gz
  swahili:
    - id: SW-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/swahili-par-linux-3.2.bin.gz
  latin:
    - id: LA-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/latin-par-linux-3.2.bin.gz
  german:
    - id: DE-1
      encoding: ISO-8859-1
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/german-par-linux-3.2.bin.gz
    - id: DE-2
      encoding: UTF-8
      url: ftp://ftp.ims.uni-stuttgart.de/pub/corpora/german-par-linux-3.2-utf8.bin.gz
  portuguese:
    - id: PT-1
      encoding: ISO-8859-1
      author: Pablo Gamallo
      url: http://gramatica.usc.es/~gamallo/tagger/tree-taggerPT-GZ.tar.gz
      manifest:
        - lib/pt.par
        - lib/portuguese-abbreviations
        - cmd/tree-tagger-portuguese
        - bin/tokenizer-gz.perl
  galician:
    - id: GL-1
      encoding: ISO-8859-1
      author: Pablo Gamallo
      url: http://gramatica.usc.es/~gamallo/tagger/tree-taggerPT-GZ.tar.gz
      manifest:
        - lib/gz.par
        - cmd/tree-tagger-galicien
  russian:
    - id: RU-1
      encoding: UTF-8
      author: Serge Sharoff
      url: http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/russian-par-linux-3.2-utf8.bin.gz
