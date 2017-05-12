package Dist::Maker::Command::new;
use Mouse;
use MouseX::StrictConstructor;

use Dist::Maker::Scatter;
use Dist::Maker::Name;
use Dist::Maker::Util qw(parse_options p);
use File::Spec;
use File::Basename ();
use Cwd ();

extends 'Dist::Maker::Base';

sub pass_through { 0 }

sub option_spec {
    return(
        'dry-run|n',
        'force|f',
    );
}

sub _predir {
    my($path) = @_;
    return $path =~ m{/}
        ? +(split qr{/}, $path)[0] // ''
        : '';
}

sub run {
    my $self = shift;
    my($options, $filename, $template) = $self->parse_options(@_);
    if(!$filename) {
        $self->diag("File name is not given.\n");
        return undef;
    }

    if($filename =~ /::/) {
        $filename  =~ s{::}{/}g;
        $filename .= ".pm";
    }

    my $meta = $self->get_meta();
    $template //= $meta->{template};

    my $dist = Dist::Maker::Name->new($meta->{dist});
    $self->note("running with $filename $template in $dist\n");

    my($suffix) = ($filename =~ / (\.[^.]+) \z/xms);
    if(!defined $suffix) {
        $self->diag("Cannot determin the prototype from '$filename' (no prototype)\n");
        return undef;
    }
    my $suffix_rx = qr/\Q$suffix\E \z/xms;

    $dist->module(q{<: $package :>});
    my $dms = Dist::Maker::Scatter->new(
        dist     => $dist,
        template => $template,
        config   => $self->config,
    );

    my @candidates;
    foreach my $name(keys %{$dms->content_map}) {
        if($name =~ $suffix_rx) {
            push @candidates, $name;
        }
    }

    my $dir = _predir($filename);

    if(@candidates == 0) {
        $self->diag("Cannot determin the prototype for '$filename' (no candidates)\n");
        return undef;
    }
    elsif(@candidates > 1) {
        $self->info("Candidates: @candidates\n");

        # heulistic methods

        my %p;
        foreach my $c(@candidates) {
            $p{$c} = 0;
            # if the directory is matched, it is stronger
            if(_predir($c) eq $dir) {
                $p{$c}++;
            }

            # for tests, 't/001_*' is stronger
            if($suffix eq '.t' and $c =~ m{\A t/001 }xms) {
                $p{$c}++;
            }
        }
        @candidates = sort {
            $p{$b} <=> $p{$a} # sort by strongness
            || $a cmp $b;     # ... or leave the work to the dictionary!
        } keys %p;
    }

    my $prototype      = shift @candidates;
    my $prototype_dir = _predir($prototype);
    if($prototype_dir ne $dir) {
        if($suffix eq '.pm') {
            (my $f = $prototype) =~ s{ $suffix \z} {/$filename}xms;
            $filename = $f;
        }
        else {
            $filename = "$prototype_dir/$filename";
        }
    }

    $self->note("create $filename from $prototype\n");
    if(-e $filename && !$options->{force}) {
        $self->diag("$filename already exists. Finished.\n");
        return undef;
    }
    if(!$options->{'dry-run'}) {
        my $package = $filename;
        $package =~ s{\A $prototype_dir/ }{}xms;
        $package =~ s{$suffix}{}xms;
        $package =~ s{/+}{::}xmsg;
        $package =~ s{-+}{::}xmsg;

        my $content = $dms->render_string($dms->content_map->{$prototype}, {
            package => $package,
        });
        $dms->scatter('.', { $filename => $content });
    }

    $self->note("finished.\n");
    return 1;
}

sub get_meta {
    my($self) = @_;
    my $cwd  = Cwd::getcwd();
    my $dir  = $cwd;
    DIR: while(1) {
        # read .dim.pl first for back compat
        foreach my $file(".dim.pl", $self->config->distconfig_file) {
            if(-e "$dir/$file") {
                $self->info("Readng '$dir/$file'\n");
                my $data = do "$dir/$file";
                if($data) {
                    return $data;
                }
                if($@) {
                    $self->diag($@);
                }
                last DIR; # file found but failed
            }
        }

        my $d = File::Basename::dirname($dir); # updir
        if($dir eq $d) {
            last;
        }
        else {
            $dir = $d;
        }
    }

    # the last resort: from the current directory
    return {
        dist     => File::Basename::basename($cwd),
        template => 'Default',
    };
}


no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Command::new - Creates a new file

=cut
