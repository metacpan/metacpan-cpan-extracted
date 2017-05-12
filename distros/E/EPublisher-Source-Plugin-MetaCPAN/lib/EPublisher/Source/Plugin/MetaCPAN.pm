package EPublisher::Source::Plugin::MetaCPAN;

# ABSTRACT: Get POD from distributions via MetaCPAN

use strict;
use warnings;

use Data::Dumper;
use Encode;
use File::Basename;
use MetaCPAN::API;

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod_from_code);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.24;

# implementing the interface to EPublisher::Source::Base
sub load_source{
    my ($self) = @_;

    $self->publisher->debug( '100: start ' . __PACKAGE__ );

    my $options = $self->_config;
    
    return '' unless $options->{module};

    my $module = $options->{module};    # the name of the CPAN-module
    my $dont_merge_release = $options->{onlythis};
    my $mcpan  = MetaCPAN::API->new;

    # metacpan does not handle ".pm" in dist names
    my $release_name_metacpan = $module;
    $release_name_metacpan    =~ s/\.pm\z//;

    # fetching the requested module from metacpan
    $self->publisher->debug( "103: fetch release $module ($release_name_metacpan)" );

    # if just the one and only POD from the modules name and not the entire
    # release is wanted, we just fetch it and return
    if ($dont_merge_release) {

        my $result;

        eval {
            $result = $mcpan->pod(
                module         => $release_name_metacpan,
                'content-type' => 'text/x-pod',
            );
            1;
        } or do {
            $self->publisher->debug(
                "103: Can't retrieve pod for $release_name_metacpan"
            );
            return;
        };

        my @pod = ();
        my $info = { pod => $result, filename => '', title => $module };
        push (@pod, $info);

        # EXIT!
        return @pod;
    }
    # ELSE we go on and build the entire release...

    # if there is a wrong module-name we write a debug-message and return
    # an empty array
    my $module_result;
    eval {
        $module_result =
            $mcpan->fetch( 'release/' . $release_name_metacpan );
        1;
    } or do {
        $self->publisher->debug(
            "103: release $release_name_metacpan does not exist"
        );
        return;
    };

    # if we reached here the module-call was probably fine...
    # so we print out what we have got
    $self->publisher->debug(
        "103: fetch result: " . Dumper $module_result
    );

    # get the manifest with module-author and modulename-moduleversion
    $self->publisher->debug( '103: get MANIFEST' );
    my $manifest;
    eval {
        $manifest = $mcpan->source(
            author  => $module_result->{author},
            release => $module_result->{name},
            path    => 'MANIFEST',
        );
    } or do {
        $self->publisher->debug(
            "103: Cannot get MANIFEST",
        );
        return;
    };

    # make a list from all possible POD-files in the lib directory
    my @files     = split /\n/, $manifest;

    #$self->publisher->debug( "103: files from manifest: " . join ', ', @files );

    # some MANIFESTS (like POD::Parser) have comments after the filenames,
    # so we match against an optional \s instead of \z
    # the manifest, in POD::Parser in looks e.g. like this:
    #
    # lib/Pod/Usage.pm     -- The Pod::Usage module source
    # lib/Pod/Checker.pm   -- The Pod::Checker module source
    # lib/Pod/Find.pm      -- The Pod::Find module source
    my @pod_files = grep{
        /^.*\.p(?:od|m|l)(?:\s|$)/  # all POD everywhere
        and not
        /^(?:example\/|x?t\/|inc\/)/ # but not in example/ or t/ or xt/ or inc/
    }@files;

    # especially in App::* dists the most important documentation
    # is often in the scripts
    push @pod_files, grep {
        /^bin\//
        and not
        /^.*\.p(?:od|m|l)(?:\s|$)/
    }@files;

    # here whe store POD if we find some later on
    my @pod;

    # look for POD
    for my $file ( @pod_files ) {

        # we match the filename again, in case there are comments in
        # the manifest, in POD::Parser in looks e.g. like this:
        #
        # lib/Pod/Usage.pm     -- The Pod::Usage module source
        # lib/Pod/Checker.pm   -- The Pod::Checker module source
        # lib/Pod/Find.pm      -- The Pod::Find module source

        my ($path) = split /\s/, $file;
        next if $path !~ m{ \. p(?:od|m|l) \z }x && $path !~ m{ \A bin/ }x;

        $file = $path;

        # the call below ($mcpan->pod()) fails if there is no POD in a
        # module so this is why I filter all the modules. I check if they
        # have any line BEGINNING with '=head1' ore similar
        my $source;
        eval {
            $source = $mcpan->source(
                author  => $module_result->{author},
                release => $module_result->{name},
                path    => $file,
            );
            1;
        } or do {
            $self->publisher->debug(
                "103: Cannot get source for $file",
            );
            return;
        };

        $self->publisher->debug( "103: source of $file found" );

        # The Moose-Project made me write this filtering Regex, because
        # they have .pm's without POD, and also with nonsense POD which
        # still fails if you call $mcpan->pod
        my $pod_src;
        if ( $source =~ m{ ^=head[1234] }xim ) {

            eval {
                $pod_src = $mcpan->pod(
                    author         => $module_result->{author},
                    release        => $module_result->{name},
                    path           => $file,
                    'content-type' => 'text/x-pod',
                );

                1;
            } or do{ $self->publisher->debug( $@ ); next; };

            if (!$pod_src) {
                $self->publisher->debug( "103: empty pod handle" );
                next;
            }

            if ( $pod_src =~ m/ \A ({.*) /xs ) {
                $self->publisher->debug( "103: error message: $1" );
                next;
            }
            else {
                $self->publisher->debug( "103: got pod" );
            }

            # metacpan always provides utf-8 encoded data, so we have to decode it
            # otherwise the target plugins may produce garbage
            $pod_src = decode( 'utf-8', $pod_src );

        }
        else {
            # if there is no head we consider this POD unvalid
            next;
        }
        
        # check if $result is always only the Pod
        #push @pod, extract_pod_from_code( $result );
        my $filename = basename $file;
        my $title    = $file;

        $title =~ s{^(?:lib|bin)/}{};
        $title =~ s{\.p(?:m|od|l)\z}{};
        $title =~ s{/}{::}g;
 
        my $info = { pod => $pod_src, filename => $filename, title => $title };
        push @pod, $info;

        # make some nice debug output for what is in $info
        my $pod_short;
        if ($pod_src =~ m/(.{50})/s) {
            $pod_short = $1 . '[...]';
        }
        else {
            $pod_short = $pod_src;
        }
        $self->publisher->debug(
            "103: passed info: "
                . "filename => $filename, "
                . "title => $title, "
                . "pod => $pod_short"
        );
    }

    # voila
    return @pod;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Source::Plugin::MetaCPAN - Get POD from distributions via MetaCPAN

=head1 VERSION

version 0.24

=head1 SYNOPSIS

  my $source_options = { type => 'MetaCPAN', module => 'Moose' };
  my $url_source     = EPublisher::Source->new( $source_options );
  my @pod            = $url_source->load_source;

=head1 OPTIONS

Those options can be passed to this plugin:

=over 4

=item * module

=item * onlythis

=back

=head1 METHODS

=head2 load_source

  my @pod = $url_source->load_source;

returns a list of documentation for the given distribution. Each element
of the list is a hashref that looks like

  {
      pod      => '=head1 EPublisher...',
      filename => 'Epublisher.pm',
      title    => 'EPublisher,
  }

Where 

=over 4

=item * pod

Complete POD documentation extracted from the file

=item * filename

Basename of the file where the documentation was found

=item * title

Full path of the file with some substitutions:

=over 4

=item * removed leading "bin/" or "lib/"

=item * removed file suffix (".pm", ".pl", ".pod")

=item * replaced "/" with "::"

=back

=back

=head1 CONTRIBUTORS

These people contributed to C<EPublisher::Source::Plugin::MetaCPAN> and made it
a better module:

=over 4

=item * Stefan Limbacher (stelim)

=back

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>, Boris Daeppen <boris_daeppen@bluewin.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Bäcker, Boris Däppen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
